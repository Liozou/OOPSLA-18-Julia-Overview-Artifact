include("perfutil.jl")
rpath(filename::AbstractString) = joinpath(@__DIR__, filename)

include("meteor_contest.jl")
@timeit meteor_contest() "meteor_contest" "Search for solutions to shape packing puzzle"

