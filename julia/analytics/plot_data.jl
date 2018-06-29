include("collect_data.jl")

LOGS_DIR = "$JULIA_HOME/../../logs/"

using Plots
plotlyjs()

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
Plot a histogram corresponding to the given vector of integers.
"""
function big_hist(l::Vector{Int}, modifier=(x,y)->(x,y), args...; kwargs...)
    global vals = sort(unique(l))
    index = Dict{Int, Int}()
    for i in eachindex(vals)
        index[vals[i]] = i
    end
    global res = zeros(Int, length(vals))
    for v in l
        res[index[v]]+=1
    end
    for x in zip(vals, res)
        println(x[1],',',x[2])
    end
    return scatter(modifier(vals, res)..., args...; legend=nothing, kwargs...)
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

function plot_argument_dispatch(logs_dir=LOGS_DIR)
    l = all_in_list(logs_dir*"data/static_strict/arguments_per_dispatch.txt")
    data = vcat(l...)
    big_hist(data, yscale=:log10, title="Number of arguments per dispatch")
end

function plot_callable_methods_per_call_signature(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/nonsinglefunction/package/applicable_methods_per_call.txt")
    big_hist(data, yscale=:log10, title="Number of callable methods per call signature")
end

function plot_methods_per_callsite(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/nonsinglefunction/package/methods_per_site.txt")
    big_hist(data, yscale=:log10, xscale=:log10, title="Number of called methods per call site")
end

function prepare_number_of_methods_per_functionarity_soft(logs_dir=LOGS_DIR)
    names = String[]
    vals = Tuple{Int, Int, Int}[]
    source = logs_dir*"data/static_soft/methods_per_functionarity.txt"
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
        println(names[i],',',vals[i][1],',',vals[i][2],',',vals[i][3])
    end
end

function prepare_number_of_methods_per_functionarity_strict(logs_dir=LOGS_DIR)
    names = String[]
    vals = Tuple{Int, Int, Int}[]
    source = logs_dir*"data/static_strict/methods_per_functionarity.txt"
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
        println(names[i],',',vals[i][1],',',vals[i][2],',',vals[i][3])
    end
end

function plot_applicable_methods_per_call_signature(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/nonsinglefunction/package/applicable_methods_per_call.txt")
    big_hist(data, yscale=:log10, title="Number of applicable methods per call signature")
end

function plot_methods_per_function_soft(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/static_soft/methods_per_functionarity.txt")
    big_hist(data, yscale=:log10, xscale=:log10, title="Number of method definitions per function")
end

function plot_methods_per_function_strict(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/static_strict/methods_per_functionarity.txt")
    big_hist(data, yscale=:log10, xscale=:log10, title="Number of methods per function (strict)")
end

function prepare_muschevici_metrics_soft(logs_dir=LOGS_DIR)
    source = logs_dir*"data/static_soft/muschevici_metrics.txt"
    s = readstring(source)
    println(join(split(join(split(s,":["), ','), ']'), ""))
end

function prepare_muschevici_metrics_strict(logs_dir=LOGS_DIR)
    source = logs_dir*"data/static_strict/muschevici_metrics.txt"
    s = readstring(source)
    println(join(split(join(split(s,":["), ','), ']'), ""))
end

function prepare_muschevici_metrics_with_arity_soft(logs_dir=LOGS_DIR)
    source = logs_dir*"data/static_soft/muschevici_metrics_with_arity.txt"
    s = readstring(source)
    println(join(split(join(split(s,":["), ','), ']'), ""))
end

function prepare_muschevici_metrics_with_arity_strict(logs_dir=LOGS_DIR)
    source = logs_dir*"data/static_strict/muschevici_metrics_with_arity.txt"
    s = readstring(source)
    println(join(split(join(split(s,":["), ','), ']'), ""))
end

function plot_specializations_per_method(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/static_strict/specializations_per_method.txt")
    big_hist(data, yscale=:log10, title="Number of specializations per method")
end

function plot_targets_per_callsite(logs_dir=LOGS_DIR)
    data = all_in_one(logs_dir*"data/function/package/targets_per_callsite.txt")
    big_hist(data, yscale=:log10, xscale=:log10, title="Number of targets per call site")
end
