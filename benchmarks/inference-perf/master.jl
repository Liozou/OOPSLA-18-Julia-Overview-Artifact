source = "../shootout/binary_trees.jl"
mod = ""
code = "binary_trees()"
if !isempty(mod)
    modcode = "using $mod"
else
    modcode = ""
end

abstract type Invocation end
struct BaselineInvocation <: Invocation end
struct BrokenInferenceInvocation <: Invocation
    mod::String
    fun::String
    pc::Int
end

struct PerformanceOutcome
    invocation::Invocation
    time::Float64
    bytes::Int64
    gctime::Float64
    inlinings::Int64
    getfields::Int64
    allocs::Int64
    inline_locations::Array{UInt64,1}
end

function readtime(invocation::Invocation, time::String)
    outs = split(time, "\n")
    memory_opts = split(outs[1], " ")
    fields = parse(Int64, memory_opts[1])
    allocs = parse(Int64, memory_opts[2])

    ntimes = 5
    
    inline_locs = UInt64[]
    for loc in outs[2+ntimes:end]
        if isempty(loc) continue end
        push!(inline_locs, parse(UInt64, loc))
    end
    
    out = Array{PerformanceOutcome, 1}()

    for i=1:ntimes
        timeres = outs[1+i]
        times = split(timeres, " ")
        t = parse(Float64, times[1])
        bytes = parse(Int64, times[2])
        gctime = parse(Float64, times[3])
        push!(out, PerformanceOutcome(invocation, t, bytes, gctime, 0, fields, allocs, inline_locs))
    end

    return out
end

function do_invoke(invocation::BaselineInvocation)
    executor = `../jl-bti/julia/julia runner.jl $source $modcode $code 0`
    return readtime(invocation, read(executor, String))
end

function do_invoke(invocation::BrokenInferenceInvocation)
    executor = `../jl-bti/julia/julia runner.jl $source $modcode $code 2 
                                                $(invocation.mod) $(invocation.fun) $(invocation.pc)`
    return readtime(invocation, read(executor, String))
end
    

function inference_locs()
    executor = `../jl-bti/julia/julia runner.jl $source $modcode $code 1`
    locations = split(read(executor, String), "\n")
    output = Set{Invocation}()
    for loc in locations[2:end]
        if isempty(loc) continue end
        spres = split(loc, " ")
        imod = spres[1]
        fun = spres[2]
        pc = parse(Int, spres[3])
        of_interest = false
        if mod == ""
            of_interest = (imod == "Inner")
        else
            of_interest = imod == mod
        end
        
        if of_interest
            push!(output, BrokenInferenceInvocation(imod, fun, pc))
        end
    end
    return output
end

of_interest = inference_locs()
push!(of_interest, BaselineInvocation())
perfres_2d = map(do_invoke, of_interest)

perfres = Array{PerformanceOutcome,1}()
map(ress->append!(perfres, ress), perfres_2d)

inlocs = Set{UInt64}()
for res in perfres
    union!(inlocs, res.inline_locations)
end

function generate_predictors(inlocs, perfres)
    predictors = Array{Int, 2}(length(perfres), length(inlocs))
    i = 1
    for res in perfres
        j = 1
        for loc in inlocs
            if in(loc, res.inline_locations)
                predictors[i,j] = 1
            else
                predictors[i,j] = 0
            end
            j += 1
        end
        i += 1
    end
    return predictors
end
predictors = generate_predictors(inlocs, perfres)

#println("$(baselines[1].time) $(baselines[1].inlinings) $(baselines[1].getfields) $(baselines[1].allocs)")
function print_res(perfres, predictors)
    i = 1
    for res in perfres
        sep = ","
        println("$(hash(res.invocation)),$(res.time),$(join(predictors[i,:],sep))")
        i += 1
    end
end
print_res(perfres, predictors)
