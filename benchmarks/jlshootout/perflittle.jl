using Base64
include("perfutil.jl")

ccall(:srandom, Void, (UInt32,), UInt32(floor(time())))
freq = 0
if length(ARGS) > 0 
    freq = parse(Int64, ARGS[1])
    if freq >= -1
        Core.Inference.bitf_random(true,freq)
    end
    println("Anys out of n: $freq")
end
macro timeit(expr, name)
    quote
        val,t,bytes,gctime,memallocs = @timed $expr
        @printf "julia,%s,%f,%d\n" $name t freq
    end
end

rpath(filename::AbstractString) = joinpath(@__DIR__, filename)

include("binary_trees.jl")
@timeit binary_trees(12) "binary_trees12"

opba = BitArray{1}()
opba.chunks = Core.Inference.bitf_log.chunks
opba.len = Core.Inference.bitf_log.len
opba.dims = Core.Inference.bitf_log.dims

io = IOBuffer()
b64 = Base64EncodePipe(io)
write(b64, opba)
close(b64)
println(String(take!(io)))
println(map(hash,Core.Inference.bitf_locs))
