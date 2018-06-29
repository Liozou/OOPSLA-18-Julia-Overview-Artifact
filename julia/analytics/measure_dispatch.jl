include("parse_performance.jl")

#=
This file provides utilities for automatic data collection during package
testing. In particular, it sets the `potentialMethods` field of a CInfo (see
`parse_performance.jl`) according to the available static data.
=#

"""
Merge two call tables by removing the number of calls and merging the potential
methods.
"""
function hard_merge(x::Dict{CSig, Vector{UInt64}}, y::Dict{CSig, CInfo})
    ret = Dict{CSig, Vector{UInt64}}()
    for k in union(keys(x), keys(y))
        if haskey(x, k)
            if haskey(y, k)
                ret[k] = unique(vcat(x[k], y[k].potentialMethods))
            else
                ret[k] = x[k]
            end
        else
            if haskey(y, k)
                ret[k] = y[k].potentialMethods
            end
        end
    end
    return ret
end

"""
Transform each CInfo into only its potentialMethods field
"""
function hard_merge(x::Dict{CSig, CInfo})
    ret = Dict{CSig, Vector{UInt64}}()
    for k in keys(x)
        ret[k] = x[k].potentialMethods
    end
    return ret
end

"""
Shrink a table by removing the call sites and the number of calls.
"""
function hard_merge(t::Table)
    x = Dict{FunctionSig, Dict{MSig, Dict{CSig, Vector{UInt64}}}}()
    for (fun, sites) in t
        for (s, methods) in sites
            for (m, calls) in methods
                if haskey(x, fun)
                    if haskey(x[fun], m)
                        x[fun][m] = hard_merge(x[fun][m], calls)
                    else
                        x[fun][m] = hard_merge(calls)
                    end
                else
                    x[fun] = Dict(m=>hard_merge(calls))
                end
            end
        end
    end
    return x
end

"""
First pass: set, for each call, the potential methods within the same call site.
"""
function set_first_pass(table::Table)
    validCandidate = false
    ret = deepcopy(table)
    for (fun, sites) in table
        for (site, methods) in sites
            for (meth, calls) in methods
                for call in keys(calls)
                    for candidate in keys(methods)
                        str_call = string(call)
                        str_candidate = string(candidate)
                        try
                            validCandidate = eval(Meta.parse("($str_call) <: ($str_candidate)"))
                        catch e
                            warn(e)
                            println("($str_call) <: ($str_candidate)")
                            validCandidate = false
                        end
                        if validCandidate
                            push!(ret[fun][site][meth][call].potentialMethods, hash(candidate))
                        end
                    end
                end
            end
        end
    end
    return ret
end

"""
Second pass: merge the potential methods independently of the call sites.
"""
function set_second_pass!(table::Table)
    merged = hard_merge(table)
    for (fun, sites) in table
        for (site, methods) in sites
            for (meth, calls) in methods
                for call in keys(calls)
                    table[fun][site][meth][call].potentialMethods = merged[fun][meth][call]
                end
            end
        end
    end
    return table
end

"""
Set the according values to the potentialMethods field of a table.
"""
function setPotentialMethods(table::Table)
    return set_second_pass!(set_first_pass(table))
end

"""
Load a .dyn file back into a julia object.
"""
function load_back(dyn_address::String)
    return eval(parse(readline(dyn_address)))
end

"""
Analyze the log for a given package and creates a dyn.
"""
function analyze_package(name::String, log_address::String)
    info("Parsing $name")
    funs = parse_perf(log_address)

    info("Analyzing $name")
    result = setPotentialMethods(funs)

    info("Saving $name")
    log_dir = join(split(log_address, '/')[1:end-1], '/')
    mkpath("$log_dir/dyns/")
    open("$log_dir/dyns/$name.dyn", "w") do f
        println(f, result)
    end
end

"""
Run the tests before analyzing the package.
WARNING: do not use with unmet dependencies.
"""
function analyze_package_with_tests(pkg::String, log_address::String)
    name = deepcopy(pkg)
    b = abspath(joinpath(homedir(),".julia"))
    x, y = VERSION.major, VERSION.minor
    dir = joinpath(b,"v$x.$y")
    pkg = abspath(dir, pkg)

    reqs_path = abspath(pkg,"test","REQUIRE")
    if isfile(reqs_path)
        tests_require = Reqs.parse(reqs_path)
        if (!isempty(tests_require))
            info("Computing test dependencies for $pkg...")
            resolve(merge(Reqs.parse("REQUIRE"), tests_require))
        end
    end
    cd(abspath(pkg, "test"))
    test_path = abspath(pkg,"test","runtests.jl")

    include(test_path)

    return analyze_package(name, log_address)
end

function count_arguments_fixed_size(methods::Vector{MSig}, n::Int)
    if isempty(methods)
        return -1
    end
    count = 0
    @inbounds for i in 2:n+1 # i = 1 corresponds to the type of the function
        count += length(unique([m.specTypes[i] for m in methods])) > 1
    end
    return count
end

function count_arguments_involved(methods)
    n = maximum(x->length(x.specTypes), methods) - 1
    to_ret = [MSig[] for i in 1:n]
    for m in methods
        if length(m.specTypes) > 1
            push!(to_ret[length(m.specTypes)-1], m)
        end
    end
    return [count_arguments_fixed_size(to_ret[i], i) for i in 1:n]
end
