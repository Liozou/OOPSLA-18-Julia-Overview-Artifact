include("measure_dispatch.jl")
include("eachmethod.jl")

#=
This file provides utilities to extract and save a number of intermediate
metrics, starting from the .dyns and .satic files.
=#

"""
Load a directory containing .dyn files in memory.
Return the names of the studied packages and the tables
"""
function load_dyns(source::AbstractString)
    names = [join(split(f, '.')[1:end-1], '.') for f in readdir(source)]
    tables = [(info("   Loading $f"); load_back(source * f)) for f in readdir(source)]
    return names, tables
end

"""
Output the list of number of actual calls signature that were recorded for each
call site.
"""
function targets_per_callsite(t::Table)
    ret = Int[]
    for (f, sites) in t
        for (s, methods) in sites
            push!(ret, number_unique_calls(methods))
        end
    end
    return ret
end

"""
Output the list of number of methods called for each call site.
"""
function methods_per_site(t::Table)
    ret = Int[]
    for (f, sites) in t
        for (s, methods) in sites
            push!(ret, length(keys(methods)))
        end
    end
    return ret
end

"""
Output the list of the number of applicable methods for each call signature.
"""
function applicable_methods_per_call(t::Table)
    ret = Int[]
    x = to_baretable(t)
    for (f, methods) in x
        for (m, calls) in methods
            for (c, info) in calls
                push!(ret, length(info.potentialMethods))
            end
        end
    end
    return ret
end

"""
Type of the tables with only information on the functions and corresponding
method signatures.
"""
ShallowTable = Dict{FunctionSig, Set{MSig}}

"""
Prune from a table all information regarding call sites and actual calls.
Also removes symbols from the table.
"""
function to_shallowtable(t::Table)
    ret = Dict{FunctionSig, Set{MSig}}()
    for (f, sites) in t
        if issymbol(f)
            continue
        end
        for (s, methods) in sites
            if haskey(ret, f)
                union!(ret[f], keys(methods))
            else
                ret[f] = Set{MSig}(keys(methods))
            end
        end
    end
    return ret
end

"""
Transform a static table into a shallow table.
"""
function to_shallowtable(t::StaticTable)
    ret = Dict{FunctionSig, Set{MSig}}()
    for (f, methods) in t
        if issymbol(f)
            continue
        end
        ret[f] = Set{MSig}()
        for m in methods
            specTypes, extension = find_all_arguments(m.sig, 7, true)
            specTypes[1] = "typeof($(specTypes[1]))"
            push!(ret[f], MSig(specTypes, extension))
        end
    end
    return ret
end

"""
Output the list of the number of methods each function has.
"""
function methods_per_function(t::ShallowTable)
    return [length(v) for v in values(t)]
end

"""
Output the list of the number of methods each function/arity has.
The arity is the number of arguments to a function. Here, two methods with a
different arities are considered to belong to two different functions.
"""
function methods_per_functionarity(t::ShallowTable)
    ret = Int[]
    for val in values(t)
        collect = Dict{Int, Int}()
        for x in val
            collect[length(x.specTypes)] = get(collect, length(x.specTypes), 0) + 1
        end
        for v in values(collect)
            push!(ret, v)
        end
    end
    return ret
end

"""
Output the list of the number of actual calls that happened at each call site.
"""
function call_number_per_callsite(t::Table)
    ret = Int[]
    for (f, sites) in t
        for (s, methods) in sites
            push!(ret, number_calls(methods))
        end
    end
    return ret
end

"""
Output the list of the number of calls each method had.
"""
function call_number_per_method(t::Table)
    ret = Int[]
    for (f, sites) in t
        for (s, methods) in sites
            for (m, calls) in methods
                push!(ret, number_calls(calls))
            end
        end
    end
    return ret
end

"""
Output the list of the number of calls that corresponded to each call signature.
"""
function call_number_per_call_signature(t::Table)
    ret = Int[]
    for (f, sites) in t
        for (s, methods) in sites
            for (m, calls) in methods
                for (c, info) in calls
                    push!(ret, info.count)
                end
            end
        end
    end
    return ret
end

"""
Count the number of methods per call site and add the information of the number
of calls per call site. Divide the number of calls into three categories : only
1 call, between 2 and 50 cals and over 50 calls.
"""
function methods_per_callsite_with_proportions(t::Table)
    onlyone = 0
    meths_per_callsite = Dict{Int, Tuple{Int, Int}}()
    for (f, sites) in t
        for (s, methods) in sites
            x = length(methods)
            y = number_calls(methods)
            yless, ymore = get(meths_per_callsite, x, (0, 0))
            if y == 1
                onlyone+=1
            elseif y <= 50
                meths_per_callsite[x] = (yless+1, ymore)
            else
                meths_per_callsite[x] = (yless, ymore+1)
            end
        end
    end
    return onlyone, meths_per_callsite
end

"""
Count the number of targets per call site and add the information of the number
of calls per call site. Divide the number of calls into three categories : only
1 call, between 2 and 50 cals and over 50 calls.
"""
function targets_per_callsite_with_proportions(t::Table)
    onlyone = 0
    targets_per_callsite = Dict{Int, Tuple{Int, Int}}()
    for (f, sites) in t
        for (s, methods) in sites
            for (m, calls) in methods
                x = length(calls)
                y = number_calls(calls)
                yless, ymore = get(targets_per_callsite, x, (0, 0))
                if y == 1
                    onlyone+=1
                elseif y <= 50
                    targets_per_callsite[x] = (yless+1, ymore)
                else
                    targets_per_callsite[x] = (yless, ymore+1)
                end
            end
        end
    end
    return onlyone, targets_per_callsite
end

"""
For each call site, count the number of targets and record whether it is 1, 2,
or 3 and more, in three separated values.
"""
function target_per_callsite_one_two_plus(t::Table)
    one = 0; two = 0; plus = 0
    for (f, sites) in t
        for (s, methods) in sites
            num_call_signature = 0
            for (m, calls) in methods
                num_call_signature += length(calls)
            end
            if num_call_signature == 1
                one += 1
            elseif num_call_signature == 2
                two += 1
            else
                @assert num_call_signature >= 3
                plus += 1
            end
        end
    end
    return one, two, plus
end

import JSON

"""
Export to a file one metric for different packages.
"""
function export_data(names::Vector{String}, file::AbstractString, data)
    mkpath(join(split(file, '/')[1:end-1],'/'))
    x = IOBuffer()
    for i in eachindex(names)
        print(x, names[i], ":")
        JSON.print(x, data[i])
        println(x, "")
    end
    open(file, "w") do f
        println(f, String(take!(x)))
    end
end

function add_merge(dict, key, val)
    if haskey(dict, key)
        dict[key] = merge(dict[key], val)
    else
        dict[key] = val
    end
end

"""
Collect all the metrics given by argument `functions`, requiring both .static
and .dyn files.

Filter out functions that are defined in Core, Base, and anonymous and builtin
functions. Do the computations twice, once for all kept functions and the
second time without the functions that only have one method.
The collected data is saved respectively in `data/function/` and
`data/nonsinglefunction/`.
"""
function collect_export_specific(logs_dir::AbstractString, functions)
    statics = Dict{String, StaticTable}()
    tables = Dict{String, Table}()
    info("LOADING STATIC")
    for f in readdir(logs_dir*"static/") #*.static
        info("  Loading $f")
        statics[f[1:end-7]] = eval(parse(readline(logs_dir*"static/"*f)))
    end
    info("LOADING DYNS")
    for f in readdir(logs_dir*"dyns/") #*.dyn
        info("  Loading $f")
        tables[f[1:end-4]] = eval(parse(readline(logs_dir*"dyns/"*f)))
    end
    names = String[]

    info("EXTRACTING DYNS")
    funs = Table[]; nonsinglefunctions = Table[]
    for (name,table) in tables
        if !haskey(statics, name)
            continue
        end
        push!(names, name)
        info("  Extracting from $name")
        static = statics[name]
        fun = Table()
        nonsinglefunction = Table()
        sorted = sort_by_module(table)
        for (modul, t) in sorted
            if !(modul in ("Core", "Base", "", "#UNDEFINED"))
                for (f, sites) in t
                    if !issymbol(f)
                        add_merge(fun, f, sites)
                        if haskey(static, f) && length(static[f]) > 1
                            add_merge(nonsinglefunction, f, sites)
                        end
                    end
                end
            end
        end
        push!(funs, fun); push!(nonsinglefunctions, nonsinglefunction)
    end

    mkpath(logs_dir*"data/function/package/")
    mkpath(logs_dir*"data/nonsinglefunction/package/")

    for f in functions
        info("COMPUTING $f")
        res_funs = [f(t) for t in funs]
        res_nsfuns = [f(t) for t in nonsinglefunctions]
        export_data(names, logs_dir*"data/function/package/$f.txt", res_funs)
        export_data(names, logs_dir*"data/nonsinglefunction/package/$f.txt", res_nsfuns)
    end

    return names, funs, nonsinglefunctions
end

"""
Export the static data. Must be run in scope of the targeted static data.
"""
function compare_static(pkg::String, log_address::String)
    d = collect_all_methods()
    keep = StaticTable()
    unk = String[]
    for l in readlines(log_address)
        name = ""
        if length(l) > 1 && l[1]==':'
            name = l[2:end]
        elseif length(l) > 6 && l[1:6] == "Symbol"
            name = l[9:end-2]
        else
            continue
        end
        if haskey(d, name)
            keep[name] = d[name]
        else
            push!(unk, name)
        end
    end
    addr = join(split(log_address, '/')[1:end-1], '/')
    mkpath("$addr/static/"); mkpath("$addr/unk/")
    open("$addr/static/$pkg.static", "w") do f
        println(f, keep)
    end
    open("$addr/unk/$pkg.unk", "w") do f
        println(f, unk)
    end
end

"""
Keep only the functions, not the symbols.
"""
function static_separate_functions(d::StaticTable)
    return filter((f,val)->!issymbol(f),d)
end
"""
Keep only the user-defined functions that do not come from Base or Core.
"""
function static_separate_package(d::StaticTable)
    ret = StaticTable()
    for (f, val) in d
        if f=="Type" || f=="eval"
            continue
        end
        if any(x->!(x.modul in ["Core", "Base"]), val)
            ret[f] = val
        end
    end
    return ret
end

"""
Count the number of specializations per method.
"""
function specializations_per_method(t::StaticTable)
    ret = Int[]
    for (f,v) in t
        if !issymbol(f)
            for x in v
                push!(ret, x.num_specializations)
            end
        end
    end
    return ret
end

"""
Output a list whose k-th element is a sublist, recording for each method that
takes k arguments the number of arguments on which the call was dispatched on.
"""
function arguments_per_dispatch(t::ShallowTable)
    allresults = [count_arguments_involved(v) for v in values(t)]
    n = isempty(allresults) ? 0 : maximum(length, allresults)
    ret = [Int[] for i in 1:n]
    for v in allresults
        for i in eachindex(v)
            if v[i]!=-1
                push!(ret[i], v[i])
            end
        end
    end
    return ret
end

global study_redefinitions = Dict{String, Set{String}}()

"""
Count the number of functions that have methods defined in at least two
different modules.
For this purpose, Core, Base and Compat are considered to be the same package.
"""
function method_redefinitions(t::StaticTable)
    ret = 0
    for (f, methods) in t
        if issymbol(f)
            continue
        end
        modules = Set{String}([m.modul for m in methods])
        if "Core" in modules
            if "Base" in modules
                pop!(modules, "Base")
            end
            if "Compat" in modules
                pop!(modules, "Compat")
            end
        elseif "Base" in modules && "Compat" in modules
            pop!(modules, "Base")
        end
        if length(modules) > 1
            add_merge(study_redefinitions, f, modules)
            ret += 1
        end
    end
    return ret, length(t)
end

"""
Given a set of method signatures corresponding to a same function, return the
number of argument positions dispatched on (ie those for which two methods have
different type requirement) and the rigthmost such position.
"""
function argument_position_dispatch(methods::Set{MSig})
    by_length = Dict{Int, Vector{MSig}}()
    for m in methods
        if haskey(by_length, length(m.specTypes))
            push!(by_length[length(m.specTypes)], m)
        else
            by_length[length(m.specTypes)] = [m]
        end
    end
    delete!(by_length, 0); delete!(by_length, 1)
    ret_num = Int[]; ret_pos = Int[]
    for (n, meths) in by_length
        count = 0; last = 0
        @inbounds for i in 2:n
            if length(unique([m.specTypes[i] for m in meths])) > 1
                count+=1; last = i
            end
        end
        push!(ret_num, count); push!(ret_pos, last)
    end
    return ret_num, ret_pos
end

"""
Compute some metrics from Muschevici et al.
For dispatch and choice ratios, functions are separated by name only; for the
three other metrics, they are separated by name and arity.

Discrepancy is the average number of functions for which RD!=DoD (not a metric
in the original article by Muschevici et al.).
"""
function muschevici_metrics(t::ShallowTable)
    num_methods = Int[]
    num_arguments = Int[]; pos_arguments = Int[]
    for (f, methods) in t
        push!(num_methods, length(methods))
        ret_num, ret_pos = argument_position_dispatch(methods)
        append!(num_arguments, ret_num); append!(pos_arguments, ret_pos)
    end
    dispatch_ratio = mean(num_methods)
    choice_ratio = vecdot(num_methods, num_methods)/sum(num_methods)
    degree_dispatch = mean(num_arguments)
    rightmost_dispatch = mean(pos_arguments)
    n = length(num_arguments)
    discrepancy = count(num_arguments[i] != pos_arguments[i] for i in 1:n)/n
    return dispatch_ratio, choice_ratio, degree_dispatch, rightmost_dispatch, discrepancy
end

"""
Compute some metrics from Muschevici et al.
All functions are separated by arity.

Discrepancy is the average number of functions for which RD!=DoD (not a metric
in the original article by Muschevici et al.).
"""
function muschevici_metrics_with_arity(t::ShallowTable)
    num_methods = Int[]
    num_arguments = Int[]; pos_arguments = Int[]
    for (f, methods) in t
        arities = Dict{Int, Set{MSig}}()
        for m in methods
            n = length(m.specTypes)
            if haskey(arities, n)
                push!(arities[n],m)
            else
                arities[n] = Set{MSig}([m])
            end
        end
        for meths in values(arities)
            push!(num_methods, length(meths))
            ret_num, ret_pos = argument_position_dispatch(meths)
            append!(num_arguments, ret_num); append!(pos_arguments, ret_pos)
        end
    end
    dispatch_ratio = mean(num_methods)
    choice_ratio = vecdot(num_methods, num_methods)/sum(num_methods)
    degree_dispatch = mean(num_arguments)
    rightmost_dispatch = mean(pos_arguments)
    n = length(num_arguments)
    discrepancy = count(num_arguments[i] != pos_arguments[i] for i in 1:n)/n
    return dispatch_ratio, choice_ratio, degree_dispatch, rightmost_dispatch, discrepancy
end

"""
Keep only the user-defined functions that come from one given package or Main.
"""
function static_keep(d::StaticTable, name, strict::Bool)
    ret = StaticTable()
    for (f, val) in d
        if f=="Type" || f=="eval" || issymbol(f)
            continue
        end
        if (strict ? all : any)(x->(x.modul in [name, "Main"]), val)
            ret[f] = val
        end
    end
    return ret
end

"""
Refine a .static directory by removing from each .static all the functions that
have a method defined outside of the module they come from.
"""
function refine_statics(logs_dir::AbstractString, strict::Bool)
    static_dir = logs_dir*"static/"
    for f in readdir(static_dir)
        info("Refining "*f[1:end-7]*(strict ? " (strict)" : " (soft)"))
        static = eval(parse(readline(static_dir*f)))
        kept = static_keep(static, f[1:end-7], strict)
        suffix = strict ? "_strict" : "_soft"
        mkpath(logs_dir*"/static$suffix/")
        open(logs_dir*"/static$suffix/"*f, "w") do file
            print(file, kept)
        end
    end
end

"""
Refine a table by removing from it all the functions that have a method defined
outside of the module they come from.
"""
function refine_table(table::Table, name::AbstractString)
    ret = Table()
    sorted = sort_by_module(table)
    other_keys = delete!(delete!(Set(keys(table)), name), "Main")
    for f in keys(sorted[name])
        if !any(x->haskey(sorted[x], f), other_keys)
            ret[f] = table[f]
        end
    end
    return ret
end

"""
Export the metrics that can be computed from the .static files only.
suffix should be either
 - "" for all functions,
 - "_strict" for only the functions that have all their methods defined in the
   currently studied module
 - "_soft" for only the functions that have at least one method defined in the
   currently studied module
"""
function export_static(logs_dir::AbstractString, suffix="")
    study_redefinitions = Dict{String, Set{String}}()
    if suffix==""
        info_suffix = ""
    else
        info_suffix = " ("*suffix[2:end]*")"
    end
    global statics = StaticTable[]
    global names = String[]
    static_address = logs_dir*"static$suffix/"
    for f in readdir(static_address) #*.static
        info("Loading $f$info_suffix")
        push!(names, f[1:end-7])
        push!(statics, eval(parse(readline(static_address*f))))
    end
    methods_functionarity = Vector{Int}[]
    arguments_dispatch = Vector{Vector{Int}}[]
    method_redefs = Tuple{Int, Int}[]
    specializations_method = Vector{Int}[]
    muschevici = Tuple{Vararg{Float64, 5}}[]
    muschevici_with_arity = Tuple{Vararg{Float64, 5}}[]
    for i in eachindex(statics)
        info("Extracting $(names[i])$info_suffix")
        static = statics[i]
        push!(specializations_method, specializations_per_method(static))
        push!(method_redefs, method_redefinitions(static))
        shallow = to_shallowtable(static)
        push!(methods_functionarity, methods_per_functionarity(shallow))
        push!(arguments_dispatch, arguments_per_dispatch(shallow))
        push!(muschevici, muschevici_metrics(shallow))
        push!(muschevici_with_arity, muschevici_metrics_with_arity(shallow))
    end
    export_data(names, static_address*"../data/static$suffix/methods_per_functionarity.txt", methods_functionarity)
    export_data(names, static_address*"../data/static$suffix/arguments_per_dispatch.txt", arguments_dispatch)
    export_data(names, static_address*"../data/static$suffix/method_redefinitions.txt", method_redefs)
    export_data(names, static_address*"../data/static$suffix/specializations_per_method.txt", specializations_method)
    export_data(names, static_address*"../data/static$suffix/muschevici_metrics.txt", muschevici)
    export_data(names, static_address*"../data/static$suffix/muschevici_metrics_with_arity.txt", muschevici_with_arity)
end

"""
To launch in the logs directory to collect the different metrics
"""
function set_logs_dir(logs_dir)
    refine_statics(logs_dir, false) # logs/static_soft/
    refine_statics(logs_dir, true) # logs/static_strict/
    export_static(logs_dir, "") # logs/data/static/
    export_static(logs_dir, "_soft") # logs/data/static_soft/
    export_static(logs_dir, "_strict") # logs/data/static_hard/
    names, funs, nonsinglefunctions = collect_export_specific(logs_dir,
        (targets_per_callsite, methods_per_site, applicable_methods_per_call,
        call_number_per_callsite, call_number_per_method, call_number_per_call_signature,
        target_per_callsite_one_two_plus))
    nothing
end

#set_logs_dir("$JULIA_HOME/../../logs/")
