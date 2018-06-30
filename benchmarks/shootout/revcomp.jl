# This file is a part of Julia. License is MIT: https://julialang.org/license

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by David Campbell

# FIXME(davekong) Is there support in Julia for doing more efficient IO and
# handling of byte arrays?

const revcompdata = Dict{Char,Char}(
   'A'=> 'T', 'a'=> 'T',
   'C'=> 'G', 'c'=> 'G',
   'G'=> 'C', 'g'=> 'C',
   'T'=> 'A', 't'=> 'A',
   'U'=> 'A', 'u'=> 'A',
   'M'=> 'K', 'm'=> 'K',
   'R'=> 'Y', 'r'=> 'Y',
   'W'=> 'W', 'w'=> 'W',
   'S'=> 'S', 's'=> 'S',
   'Y'=> 'R', 'y'=> 'R',
   'K'=> 'M', 'k'=> 'M',
   'V'=> 'B', 'v'=> 'B',
   'H'=> 'D', 'h'=> 'D',
   'D'=> 'H', 'd'=> 'H',
   'B'=> 'V', 'b'=> 'V',
    'N'=> 'N', 'n'=> 'N',
    '\n' => '\n'
)

function dict_to_linear_array(inp::Dict{Char,Char})::Array{UInt8,1}
    lookup = Array{UInt8, 1}(255)
    for k in keys(inp)
        lookup[UInt8(k)] = UInt8(inp[k])
    end
    return lookup
end

const rcda = dict_to_linear_array(revcompdata)
const rarrow = UInt8('>')
const nl = UInt8('\n')

function revcomp(infile)
    open(infile, "r") do input
        arr = Array{UInt8,1}(filesize(input))
        char = readbytes!(input, arr, Inf)

        laststring=char
        lastline=char
        first = true
        firstlinelen = -1
        while true
            @inbounds while char > 0 && arr[char] != rarrow
                @inbounds if arr[char] == nl
                   @inbounds if char != lastline && arr[char+1] != rarrow
                        firstlinelen = lastline-char-1
                        break
                    end
                    lastline = char
                end
                char -= 1
            end
            @inbounds while char > 0 && arr[char] != rarrow
                @inbounds if arr[char] == nl
                    lastline = char
                end
                char -= 1
            end
            if char <= 0
                break
            end
            #comment is handled because we're targeting the source arr
            #two pointers converging
            outlen = laststring-lastline
            top = outlen
            bottom = 2
            topcol = 60
            botcol = 60-firstlinelen
            while top > bottom
                if topcol == 0
                    top -= 1
                    topcol = 60
                end
                if botcol == 60
                    bottom += 1
                    botcol = 0
                end
                @inbounds botval = arr[outlen-bottom+lastline+1]
                @inbounds topval = arr[outlen-top+lastline+1]
                @inbounds arr[outlen-top+lastline+1] = rcda[botval]
                @inbounds arr[outlen-bottom+lastline+1] = rcda[topval]
                top -= 1
                bottom += 1
                topcol -= 1
                botcol += 1
            end
            arr[laststring] = nl
            char -= 1
            laststring=char
        end
        #write(STDOUT, arr)
    end
    
end


