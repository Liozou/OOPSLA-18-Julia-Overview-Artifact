#=
This file provides a parser for the logs obtained with the instrumentation,
either using ccall(:jl_start/stop_instrumentation, Void, ()) or directly through
Pkg.test.
The return type of `parse_perf` is `Table`, defined below using the intermediate
types MSig, CSig and CInfo.

A variety of `sort_by...` functions are provided below, converting the Table
(or BareTable, which is a simplified version of Table) into a new dictionnary,
allowing for easy access and computations. See the documentation of the
functions directly.
=#


FunctionSig = String

SiteSig = UInt32

"""
Structure containing all the info of the tuple representing a method.
"""
mutable struct MSig
    specTypes::Vector{String}
    extension::String
end

"""
Structure containing all the info of the tuple representing a call.
"""
mutable struct CSig
    specTypes::Vector{String}
    extension::String
end

"""
Structure containing the info collected about a call signature.
"""
mutable struct CInfo
    count::Int
    potentialMethods::Vector{UInt64} # List of the hashes of the methods
end

Sig = Union{MSig, CSig}

# Type of the tables, ie functions -> callsites -> methods -> calls -> number of calls
Table = Dict{FunctionSig, Dict{SiteSig, Dict{MSig, Dict{CSig, CInfo}}}}
BareTable = Dict{FunctionSig, Dict{MSig, Dict{CSig, CInfo}}}


import Base.string

"""
Transforms a method signature back to the string it was generated from
"""
function string(x::Sig)
    """Tuple{$(join(x.specTypes, ", "))}$(x.extension)"""
end
import Base.==, Base.hash

function ==(x::Sig, y::Sig)
    x.specTypes == y.specTypes &&
    x.extension == y.extension
end
function hash(x::Sig)
    return hash(x.specTypes) ⊻ hash(x.extension) ⊻ hash(x isa MSig)
end

function issymbol(s::AbstractString)
    return (length(s) >= 2 && s[1]=='#') || s == "Type" || s == "eval"
end

"""
Return the first index j such that s[i:j-2] is a well parenthesized subtring of
s ending with either ',' or '}' (included).
In the case where it ends with ',' j is the starting index of the next element
of the list.
Also returns a boolean that states whether the ending is ', ' (true) or not.
"""
function find_next_argument(s::AbstractString, i=1)
    k = i
    p = Char[]
    n = endof(s)
    while i<=n
        c, j = next(s, i)
        if c=='(' || c=='{' || c=='['
            push!(p, c)
        elseif c==')'
            x = pop!(p)
            if x!='('
                warn("""Ill-parenthesized expression for "$s" """)
            end
        elseif c=='}'
            if isempty(p)
                return i+2, false
            end
            x = pop!(p)
            if x!='{'
                warn("""Ill-parenthesized expression for "$s" """)
            end
        elseif c==']'
            x = pop!(p)
            if x!='['
                warn("""Ill-parenthesized expression for "$s" """)
            end
        elseif c==',' && isempty(p)
            return i+2, true
        end
        i = j
    end
    return 0, false
end

"""
Return the vector of strings so that each element of the vector is a well
parenthesized substring of s delimited by ", " (excluded).
The substrings are in the same order as in the original string, the first one
starts at character i and the last one ends with a '}' (excluded)
"""
function find_all_arguments(s::String, i::Int, nospace=false)
    result = String[]
    n = endof(s)
    b = true
    while b
        j, b = find_next_argument(s, i)
        if j==0
            return result, ""
        end
        push!(result, s[i:j-3])
        i = j - nospace
    end
    extension = i<=n ? s[i-1:n] : "" # Case where the line ends with "where ..."
    return result, extension
end

"""
Substring of s starting from i until the first occurence of c (excluded).
Empty string if c is not found.
"""
function up_to_char(s::String, i::Int, c)
    s[i : search(s, c, i)-1]
end

"""
Total number of calls made
"""
function number_calls(calls::Dict{CSig, CInfo})
    return sum(call->call.second.count, calls)
end
function number_calls(object::Dict{T, Dict{U, V}} where T where U where V)
    return sum(key->number_calls(key.second), object)
end

"""
Total number of call signatures encountered
"""
function number_unique_calls(calls::Dict{CSig, CInfo})
    return length(calls)
end
function number_unique_calls(object::Dict{T, Dict{U, V}} where T where U where V)
    return sum(key->number_unique_calls(key.second), object)
end
function number_unique_calls(table::Table)
    return number_unique_calls(to_baretable(table))
end

"""
Total number of method signature encountered
"""
function number_methods(fun::Dict{MSig, Dict{CSig, CInfo}})
    return length(keys(fun))
end
function number_methods(table::BareTable)
    return sum(key->number_methods(key.second), table)
end
function number_methods(table::Table)
    return number_methods(to_baretable(table))
end


import Base.+

function +(x::CInfo, y::Int)
    return CInfo(x.count + y, x.potentialMethods)
end

function +(x::CInfo, y::CInfo)
    if x.potentialMethods != y.potentialMethods
        @show x
        @show y
        error("Inconsistent potential methods")
    end
    return CInfo(x.count + y.count, x.potentialMethods)
end

import Base.merge

merge(x::Set{T}, y::Set{T}) where T = union(x,y) # Type piracy, sorry!

"""
Merge two dictionnaries representing methods.
"""
function merge(x::Dict{CSig, CInfo}, y::Dict{CSig, CInfo})
    merge(+, x, y)
end

"""
Merge two dictionnaries whose values are dictionnaries.
"""
function merge(x::Dict{T, Dict{U,V}}, y::Dict{T, Dict{U,V}}) where T where U where V
    return merge(merge, x, y)
end

"""
Reconstitute a single table from a sorted table.
"""
function recombine(x::Dict{T, Table}) where T
    mapreduce(identity, merge, Table(), values(x))
end

"""
Convert a Table to a BareTable
"""
function to_baretable(t::Table)
    x = BareTable()
    for (fun, sites) in t
        for (s, methods) in sites
            for (m, calls) in methods
                if haskey(x, fun)
                    if haskey(x[fun], m)
                        x[fun][m] = merge(x[fun][m], calls)
                    else
                        x[fun][m] = calls
                    end
                else
                    x[fun] = Dict(m=>calls)
                end
            end
        end
    end
    return x
end


function complete_supertable!(sorted::Dict{T, BareTable}, key, fun, m, calls) where T
    if haskey(sorted, key)
        if haskey(sorted[key], fun)
            sorted[key][fun][m] = calls
        else
            sorted[key][fun] = Dict(m=>calls)
        end
    else
        sorted[key] = Dict(fun=>Dict(m=>calls))
    end
end

function complete_supertable!(sorted::Dict{T, BareTable}, key::T, fun, m, call, info) where T
    if haskey(sorted, key)
        if haskey(sorted[key], fun)
            if haskey(sorted[key][fun], m)
                sorted[key][fun][m][call] = info
            else
                sorted[key][fun][m] = Dict(call=>info)
            end
        else
            sorted[key][fun] = Dict(m=>Dict(call=>info))
        end
    else
        sorted[key] = Dict(fun=>Dict(m=>Dict(call=>info)))
    end
end

function complete_supertable!(sorted::Dict{T, Table}, key, fun, s, methods) where T
    if haskey(sorted, key)
        if haskey(sorted[key], fun)
            sorted[key][fun][s] = methods
        else
            sorted[key][fun] = Dict(s=>methods)
        end
    else
        sorted[key] = Dict(fun=>Dict(s=>methods))
    end
end

function complete_supertable!(sorted::Dict{T, Table}, key::T, fun, s, m, calls) where T
    if haskey(sorted, key)
        if haskey(sorted[key], fun)
            if haskey(sorted[key][fun], s)
                sorted[key][fun][s][m] = calls
            else
                sorted[key][fun][s] = Dict(m=>calls)
            end
        else
            sorted[key][fun] = Dict(s=>Dict(m=>calls))
        end
    else
        sorted[key] = Dict(fun=>Dict(s=>Dict(m=>calls)))
    end
end

function complete_supertable!(sorted::Dict{T, Table}, key::T, fun, s, m, call, info) where T
    if haskey(sorted, key)
        if haskey(sorted[key], fun)
            if haskey(sorted[key][fun], s)
                if haskey(sorted[key][fun][s], m)
                    sorted[key][fun][s][m][call] = info
                else
                    sorted[key][fun][s][m] = Dict(call=>info)
                end
            else
                sorted[key][fun][s] = Dict(m=>Dict(call=>info))
            end
        else
            sorted[key][fun] = Dict(s=>Dict(m=>Dict(call=>info)))
        end
    else
        sorted[key] = Dict(fun=>Dict(s=>Dict(m=>Dict(call=>info))))
    end
end

"""
Return the prefix of the name of the module of the given method signature,
or "#UNDEFINED" if undefined.
"""
function moduleof(m::MSig)
    if isempty(m.specTypes)
        return "#UNDEFINED"
    else
        mtype = m.specTypes[1]
        if length(mtype) >= 8
            if mtype[1:8] == "getfield"
                return up_to_char(mtype, 10, [',', '.'])
            elseif mtype[1:6] == "typeof"
                return up_to_char(mtype, 8, '.')
            else
                return "#UNDEFINED"
            end
        else
            return "#UNDEFINED"
        end
    end
end

"""
Sort a table by the prefix of the name of the modules each method is defined in.

Example:

```
x = sort_by_module(funs)

x["Core"] # Table where each method is defined in Core

x[""] # Table where each method is a builtin of the compiler.
```
"""
function sort_by_module(table::Table)
    sorted = Dict{String, Table}()
    for (fun, sites) in table
        for (s, methods) in sites
            for (m, calls) in methods
                modul = moduleof(m)
                complete_supertable!(sorted, modul, fun, s, m, calls)
            end
        end
    end
    return sorted
end


"""
Sort a table by the number of different methods a same function has.

Example:

```
x = sort_by_number_of_methods(funs)

x[3] # Table where each function can be called through 3 different methods.

x[1] # Table where each function can only be called through one specific method (non-generic function).
```

"""
function sort_by_number_of_methods(table::Table)
    sorted = Dict{Int, Table}()
    for (fun, sites) in table
        meths = Set{MSig}()
        for (s, methods) in sites
            union!(meths, keys(methods))
        end
        num = length(meths)
        if haskey(sorted, num)
            sorted[num][fun] = sites
        else
            sorted[num] = Dict(fun=>sites)
        end
    end
    n = maximum(keys(sorted))
    for i in 1:n
        if !haskey(sorted, i)
            sorted[i] = Table()
        end
    end
    return sorted
end

"""
Sort a bare table by the number of different call signature a same method corresponds to.

Example:
```
x = sort_by_different_calls(funs)

x[7] # Table where each method corresponds to 7 different kinds of call.

x[1] # Table where each method was only called with one specific kind of call.
```
"""
function sort_by_calls_per_method(table::BareTable)
    sorted = Dict{Int, BareTable}()
    for (fun, methods) in table
        for (m, calls) in methods
            num = length(calls)
            complete_supertable!(sorted, num, fun, m, calls)
        end
    end
    return sorted
end

function sort_by_methods_per_site(table::Table)
    sorted = Dict{Int, Table}()
    for (fun, sites) in table
        for (s, methods) in sites
            num = length(methods)
            complete_supertable!(sorted, num, fun, s, methods)
        end
    end
    return sorted
end


"""
Sort a bare table by the number of times a specific call has been made.

Example:
```
x = sort_by_number_of_calls(funs)

x[19] # Table where each call has been made 19 times.

x[1] # Table where each call signature matches a unique actual call.
```
"""
function sort_by_number_of_calls(table::BareTable)
    sorted = Dict{Int, Table}()
    for (fun, methods) in table
        for (m, calls) in methods
            num = number_calls(calls)
            complete_supertable!(sorted, num, fun, m, calls)
        end
    end
    return sorted
end

"""
Sort a table by the number of methods that match a specific call.

Example:
```
x = sort_by_dispatch(funs)

x[4] # Table where each call corresponds to 4 matching methods.

x[0] # Table where no call could be matched with a corresponding method
```
The last case can happen when a type from the call signature was generated by
the compiler but is no more in memory: no method will then be found to have
a signature which is a supertype of that of the call.
"""
function sort_by_dispatch(table::Table)
    sorted = Dict{Int, Table}()
    for (fun, sites) in table
        for (s, methods) in sites
            for (m, calls) in methods
                for (call, info) in calls
                    num = length(info.potentialMethods)
                    complete_supertable!(sorted, num, fun, s, m, call, info)
                end
            end
        end
    end
    return sorted
end

function sort_by_dispatch(table::BareTable)
    sorted = Dict{Int, BareTable}()
    for (fun, methods) in table
        for (m, calls) in methods
            for (call, info) in calls
                num = length(info.potentialMethods)
                complete_supertable!(sorted, num, fun, m, call, info)
            end
        end
    end
    return sorted
end

"""
Replace the # by ___h___ only if the character # is not within quote marks.
This is useful for parsing within Julia since # accounts for comments.
"""
function skim_hashtag(s::String)
    if !('#' in s)
        return s
    end
    if s[1] == ':' # :#foo -> Symbol("#foo")
        return """Symbol("$(s[2:end])")"""
    end
    splits = split(s, '"')
    ret = String[]
    for i in 1:length(splits)
        if i%2==0
            push!(ret, splits[i])
        else
            push!(ret, join(split(splits[i], '#'), "___h___"))
        end
    end
    return join(ret, '"')
end

import Base.copy

"""
Parse a .log file and returns a dictionnary that maps its keys (the function
names) to another dictionnary mapping call sites hashes to another dictionnary
mapping method signatures (aka methods defined by the user) to yet another
dictionnary, this last one mapping call signatures to the number of time this
specific call, with such concrete types as parameters, has been used at runtime.

Example:

    ```
    funs = parse_perf("Module.log")

    funs["functionName"][callSite][methodSignature][callSignature] # Number of times this specific call has been made
    ```
"""
function parse_perf(file)
    # Dummy initialisation of the loop variables
    funs = Table() # Function table
    currFun = "" # Currently studied function of method
    currSite = 0 # Current callsite
    specTypes = String[] # Current MSig of a method
    extension = ""
    currMethod = MSig(specTypes, extension) # Currently studied method
    currCall = (String[], "") # Current CSig of a call
    index = 0 # Current index in a string
    skip = false # Special flag called to forget about a function

    #= Loop over all the lines.
    Some variables are modified at some point to be read afterwards so each
    case cannot be understood separately from the others. =#
    for line in eachline(file)
        if length(line)==0 # Empty line
            skip = false # Stop skipping
            continue
        end
        if skip
            continue
        end
        line = skim_hashtag(line)
        if line[1]=='*' # Declaration of a call site
            currSite = parse(UInt32, line[2:end])
            if !haskey(funs[currFun], currSite)
                funs[currFun][currSite] = Dict{MSig, Dict{CSig, CInfo}}()
            end
        elseif line[1]=='\$' # Declaration of a method
            @assert line[2:6]=="Tuple"
            specTypes, extension = find_all_arguments(line, 8)
            currMethod = MSig(specTypes, extension)
            if !haskey(funs[currFun][currSite], currMethod)
                funs[currFun][currSite][currMethod] =  Dict{CSig, CInfo}()
            end
        elseif line[1]==' ' # Declaration of an explicit call
            @assert line[2:6]=="Tuple"
            if isempty(specTypes) # Case where the line is exactly " Tuple"
                currCall = CSig(String[], "")
            else
                currCall = CSig(find_all_arguments(line, 8)...)
            end
        elseif '0' <= line[1] <= '9' # Declaration of a number of calls
            currVal = get(funs[currFun][currSite][currMethod], currCall, CInfo(0, []))
            funs[currFun][currSite][currMethod][currCall] = currVal + parse(Int, line)
        else # Declaration of a function or a symbol
            if line[1]==':' # Case of a function... Except if the name begins with '#'
                currFun = line[2:end]
            elseif length(line)<10 || line[1:6]!="Symbol"
                warn("""Not a function nor a symbol: skipping from "$line" """)
                skip = true
                continue
            else # Case of a symbol
                currFun = line[9:end-2]
            end
            if !haskey(funs, currFun)
                funs[currFun] = Dict{SiteSig, Dict{MSig, Dict{CSig, CInfo}}}()
            end
        end
    end
    return funs
end
