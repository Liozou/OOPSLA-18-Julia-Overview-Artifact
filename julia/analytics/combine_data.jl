include("collect_data.jl")

#=
This file provides a number of simple functions that extract relevant
per-package or cross-package metrics.
=#

LOGS_DIR = "$JULIA_HOME/../../logs/"
mkpath(LOGS_DIR) # Otherwise the directory is created at the first package test.


## Internal utility functions

"""
Combine data from all the different packages into one.
"""
function all_in_one(source::AbstractString)
    l = Int[]
    for line in readlines(source)
        if isempty(line)
            continue
        end
        append!(l, eval(parse(split(line, ':')[2])))
    end
    return l
end

"""
Gives the data points to plot a histogram corresponding to the given vector of integers.
"""
function hist(l::Vector{Int}, io=STDOUT)
    vals = sort(unique(l))
    index = Dict{Int, Int}()
    for i in eachindex(vals)
        index[vals[i]] = i
    end
    res = zeros(Int, length(vals))
    for v in l
        res[index[v]]+=1
    end
    for x in zip(vals, res)
        println(io, x[1],',',x[2])
    end
end

"""
Regroup lists of lists across multiple packages by their length.
"""
function all_in_list(source::AbstractString)
    src = Vector{Vector{Int}}[]
    for line in readlines(source)
        if isempty(line)
            continue
        end
        push!(src, eval(parse(split(line, ':')[2])))
    end
    n = maximum(length, src)
    l = collect(Int[] for i in 1:n)
    for list in src
        for i in eachindex(list)
            append!(l[i], list[i])
        end
    end
    return l
end


## Cross-package combined metrics


"""
Number of arguments necessary to type check in order to perform dispatch, per
function.

Note that in practise, Julia checks the type of all arguments in order to
perform multiple dispatch. This verification is done at compile time when
possible.
"""
function arguments_dispatch(logs_dir=LOGS_DIR, io=STDOUT)
    l = all_in_list(logs_dir*"data/static_strict/arguments_per_dispatch.txt")
    data = vcat(l...)
    hist(data, io)
end


"""
Number of callable methods per call signature.

A method is considered callable if its signature (ie tuple of types of its
argument definitions) is a supertype of the call signature.
"""
function applicable_methods_per_call_signature(logs_dir=LOGS_DIR, io=STDOUT)
    data = all_in_one(logs_dir*"data/nonsinglefunction/package/applicable_methods_per_call.txt")
    hist(data, io)
end


"""
Number of methods called per call site.
Collected on functions that had at least two different methods
"""
function methods_per_callsite(logs_dir=LOGS_DIR, io=STDOUT)
    data = all_in_one(logs_dir*"data/nonsinglefunction/package/methods_per_site.txt")
    hist(data, io)
end


"""
Number of method definitions per function.
The optional argument `strict` specifies the elimination strategy.
"""
function methods_per_function(logs_dir=LOGS_DIR, strict=true, io=STDOUT)
    staticity = strict ? "_strict" : "_soft"
    data = all_in_one(logs_dir*"data/static$staticity/methods_per_functionarity.txt")
    hist(data, io)
end


"""
For all user-defined method, the number of specializations done during the tests.

The methods with 0 specialization are those that are not called; they are not
taken into account in the paper since they are only indicative of the coverage.
"""
function specializations_per_method(logs_dir=LOGS_DIR, io=STDOUT)
    data = all_in_one(logs_dir*"data/static_strict/specializations_per_method.txt")
    hist(data, io)
end


"""
Number of targets (ie specialized methods) called per call site.
"""
function targets_per_callsite(logs_dir=LOGS_DIR, io=STDOUT)
    data = all_in_one(logs_dir*"data/function/package/targets_per_callsite.txt")
    hist(data, io)
end


## Per-package metrics


"""
Compute the number of methods per function/arity.
The "arity" part means that the number of arguments is considered part of the
function name. For example, two methods with a different number of arguments are
considered to belong to two different functions.

For each package,
- the first value is the number of functions with only 1 method.
- the second value is the number of functions with exactly 2 methods.
- the third value is the number of functions with strictly more than 2 methods.

The optional argument `strict` specifies the elimination strategy.
"""
function number_of_methods_per_functionarity(logs_dir=LOGS_DIR, strict=true, io=STDOUT)
    names = String[]
    vals = Tuple{Int, Int, Int}[]
    staticity = strict ? "_strict" : "_soft"
    source = logs_dir*"data/static$staticity/methods_per_functionarity.txt"
    for line in readlines(source)
        if isempty(line)
            continue
        end
        name, l = split(line, ':')
        push!(names, name)
        evaled = eval(parse(l))
        val = [0,0,0]
        for x in evaled
            val[x >= 4 ? 3 : x] += 1
        end
        push!(vals, (val...))
    end
    for i in eachindex(names)
        println(io, names[i],',',vals[i][1],',',vals[i][2],',',vals[i][3])
    end
end


"""
Collect some of the metrics that are used in the article by Muschevici et al.
per package.

The collected metrics are:
- dispatch ratio i.e. average number of methods per function.
- choice ratio i.e. mean square number of methods per function.
- degree of dispatch i.e. average number of arguments dispatched on per function.
- rightmost dispatch i.e. average index of the last argument dispatched on.
- discrepancy: average number of functions for which RD!=DoD (not a metric in
  the original article by Muschevici et al.)

The optional argument `strict` specifies the elimination strategy.
"""
function muschevici_metrics(logs_dir=LOGS_DIR, strict=true, io=STDOUT)
    staticity = strict ? "_strict" : "_soft"
    source = logs_dir*"data/static$staticity/muschevici_metrics_with_arity.txt"
    s = readstring(source)
    println(io, join(split(join(split(s,":["), ','), ']'), ""))
end


"""
Number of targets (ie specialized methods) called per call site, per package.
The call sites are divides into three categories: those with 1 target, with 2
and those with 3 and more targets.
"""
function targets_per_callsite_per_package(logs_dir=LOGS_DIR, io=STDOUT)
    source = logs_dir*"data/function/package/target_per_callsite_one_two_plus.txt"
    s = readstring(source)
    println(io, join(split(join(split(s,":["), ','), ']'), ""))
end
