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

@timeit include("fannkuch.jl") fannkuch(parse(Int, ENV["FANNKUCH_SIZE"])) "fannkuch"

@timeit include("fasta.jl") fasta(parse(Int, ENV["FASTA_SIZE"])) "fasta"

@timeit include("k_nucleotide.jl") k_nucleotide(ENV["KNUC_FILE"]) "knucleotide"

@timeit include("mandelbrot.jl") mandelbrot(parse(Int, ENV["MANDELBROT_SIZE"]), "/dev/null") "mandelbrot"

@timeit include("meteor_contest.jl") meteor_contest() "meteor_contest"

@timeit include("nbody.jl") Main.NBody.nbody(parse(Int, ENV["NBODY_SIZE"])) "nbody"

#include("nbody_vec.jl")
#using NBodyVec
#@timeit NBodyVec.nbody_vec(50000000) "nbody_vec50m" "A vectorized double-precision N-body simulation"

@timeit include("pidigits.jl") pidigits(parse(Int, ENV["PIDIGITS_NUM"])) "pidigits"

@timeit include("regex_dna.jl") regex_dna(ENV["REGEX_FILE"]) "regex"

@timeit include("revcomp.jl") revcomp(ENV["REVCOMP_FILE"]) "revcomp"

@timeit include("spectralnorm.jl") spectralnorm(parse(Int, ENV["SPECTRALNORM_SIZE"])) "spectralnorm"

