# This file is a part of Julia. License is MIT: https://julialang.org/license

const mintrials = 2
const mintime = 100
print_output = true

macro output_timings(t,name,desc,group,addtl...)
    t = esc(t)
    name = esc(name)
    desc = esc(desc)
    group = esc(group)
    quote
        # If we weren't given anything for the test group, infer off of file path!
        test_group = length($group) == 0 ? basename(dirname(Base.source_path())) : $group[1]
        if false
            submit_to_codespeed( $t, $name, $desc, "seconds", test_group )
        elseif print_output
            @printf "%s,%f\n" $name mean($t)
        end
        gc()
    end
end

macro timeit(ex,name,desc,group...)
    quote
        t = Float64[]
        tot = 0.0
        i = 0
        while i < mintrials || tot < mintime
            e = 1000*(@elapsed $(esc(ex)))
            tot += e
            if i > 0
                # warm up on first iteration
                push!(t, e)
            end
            i += 1
        end
        @output_timings t $(esc(name)) $(esc(desc)) $(esc(group))
    end
end

macro timeit_init(ex,init,name,desc,group...)
    quote
        t = zeros(mintrials)
        for i=0:mintrials
            $(esc(init))
            e = 1000*(@elapsed $(esc(ex)))
            if i > 0
                # warm up on first iteration
                t[i] = e
            end
        end
        @output_timings t $(esc(name)) $(esc(desc)) $(esc(group))
    end
end

function maxrss(name)
    # FIXME: call uv_getrusage instead here
    rus = Array{Int64}(div(144,8))
    fill!(rus, 0x0)
    res = ccall(:getrusage, Int32, (Int32, Ptr{Void}), 0, rus)
    if res == 0
        mx = rus[5]/1024
        @printf "julia,%s.mem,%f,%f,%f,%f\n" name mx mx mx 0
    end
end


# seed rng for more consistent timings
srand(1776)
