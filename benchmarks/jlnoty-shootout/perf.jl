# This file is a part of Julia. License is MIT: https://julialang.org/license

include("perfutil.jl")
rpath(filename::AbstractString) = joinpath(@__DIR__, filename)

macro timeit(include, expr, name)
    cmd = `$(Sys.get_process_title()) $(@__FILE__) $(name)`
    quote
        if length(ARGS) > 0 && $name==ARGS[1]
            $include
            for i=1:5
                val,t,bytes,gctime,memallocs = @timed $expr
                @printf "%s  %d:%05.10f %d\n" $name div(t,60) t%60 i
            end
        elseif length(ARGS) == 0 #harness mode
            expr = pipeline($cmd, stdout=STDOUT)
            run(expr)
        end
    end
end
@timeit include("binary_trees.jl") binary_trees(parse(Int, ENV["BTREE_DEPTH"])) "binary_trees"

@timeit include("k_nucleotide.jl") k_nucleotide(ENV["KNUC_FILE"]) "knucleotide"

@timeit include("nbody.jl") Main.NBody.nbody(parse(Int, ENV["NBODY_SIZE"])) "nbody"
