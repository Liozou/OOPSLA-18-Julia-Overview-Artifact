# This file is a part of Julia. License is MIT: https://julialang.org/license

#
# The Computer Language Benchmarks Game
# binary-trees benchmark
# http://shootout.alioth.debian.org/u32/performance.php?test=binarytrees
#
# Ported from an OCaml version
#

abstract type BTree end

mutable struct Empty <: BTree
end

mutable struct Node <: BTree
    info
    left
    right
end

function makearrnorec(val::Int, d)
    arr = Array{Int,1}(2^(d+1)-1)
    arr[1] = val
    for i=2:length(arr)
        nval,side = 2*arr[div(i,2)], i%2
        if side==0
            arr[i]=nval-1
        else
            arr[i]=nval
        end
    end
    return arr
end

function checknorec(arr::Array{Int,1}, depth::Int)
    sum = 0
    for i=1:length(arr)
        parity = (count_ones(i)-1)%2
        # if parity = 0, then positive, otherwise neg
        if parity == 0
            sum += arr[i]
        else
            sum -= arr[i]
        end
    end
    return sum
end

function makearrrec(val::Int, d, arr::Array{Int,1}, last)
    if d == 0
        arr[last] = val
    else
        nval = val * 2
        arr[last] = val
        makearrrec(nval-1, d-1, arr, 2*(last-1) + 2)
        makearrrec(nval, d-1, arr, 2*(last-1) + 3)
    end
end

function makearr(val::Int, d)
    outp = Array{Int, 1}(2^(d+1)-1)
    makearrrec(val, d, outp, 1)
    return outp
end

function checkarr(ptr::Int,depth::Int,arr::Array{Int,1})
    if depth == 0
        return arr[ptr]
    else
        return arr[ptr] + checkarr(2*(ptr-1) + 2, depth-1, arr) - checkarr(2*(ptr-1)+3, depth-1, arr)
    end
end

function checkarr(arr::Array{Int,1}, depth::Int64)
    return checkarr(1, depth, arr)
end



function make(val::Int, d)
    emp = Empty()
    current = Node(val, emp, emp)
    if d == 0
        return current
    end
    root = current
    next = Array{Node}(d+1)
    nextd = Array{Int}(d+1)
    nextv = Array{Int}(d+1)
    ptr = 1
    next[ptr] = current
    nextd[ptr] = d-1
    nextv[ptr] = 2*val
    val = 2*val - 1
    d = d - 1
    ptr = ptr + 1
    side = 0
    
    while true
        newn = Node(val, emp, emp)
        if side == 0
            current.left = newn
        else
            current.right = newn
            side = 0
        end

        if d == 0
            ptr = ptr - 1
            if ptr <= 0
                break
            end
            current = next[ptr]
            d = nextd[ptr]
            val = nextv[ptr]
            side = 1
        else
            next[ptr] = newn
            nextd[ptr] = d - 1
            nextv[ptr] = val*2
            ptr = ptr + 1

            current = newn
            d = d - 1
            val = 2*val - 1
            side = 0
        end
    end
    return root
end


function oldmake(val::Int, d)
    if d == 0
        Node(val, Empty(), Empty())
    else
        nval = val * 2
        Node(val, oldmake(nval-1, d-1), oldmake(nval, d-1))
    end
end

function checkwa(root::Node, height::Int64)
    sum = 0
    next = Array{BTree}(height+1)
    nextsign = Array{Int}(height+1)
    ptr = 1
    sign = 1
    current = root
    while true 
        if isa(current, Node)
            sum += sign * current.info
            next[ptr] = current.right
            nextsign[ptr] = -sign
            current = current.left
            ptr = ptr + 1
        else
            ptr = ptr - 1
            if ptr <= 0
                break
            end
            current = next[ptr]
            sign = nextsign[ptr]
        end
    end
    return sum
end


check(t::Empty) = 0
check(t::Node) = t.info + check(t.left) - check(t.right)

function loop_depths(d, min_depth, max_depth)
    for i = 0:div(max_depth - d, 2)
        niter = 1 << (max_depth - d + min_depth)
        c = 0
        for j = 1:niter
            c += checknorec(makearrnorec(i, d),d) + checknorec(makearrnorec(-i, d),d)
        end
#        @printf("%i\t trees of depth %i\t check: %i\n", 2*niter, d, c)
        d += 2
    end
end

function binary_trees(N::Int=10)
    min_depth = 4
    max_depth = N
    stretch_depth = max_depth + 1

    # create and check stretch tree
    let c = checknorec(makearrnorec(0, stretch_depth),stretch_depth)
#        @printf("stretch tree of depth %i\t check: %i\n", stretch_depth, c)
    end

    long_lived_tree = makearrnorec(0, max_depth)

    loop_depths(min_depth, min_depth, max_depth)
#    @printf("long lived tree of depth %i\t check: %i\n", max_depth, check(long_lived_tree))
end

function loop_depths_o(d, min_depth, max_depth)
    for i = 0:div(max_depth - d, 2)
        niter = 1 << (max_depth - d + min_depth)
        c = 0
        for j = 1:niter
            c += checkarr(makearr(i, d),d) + checkarr(makearr(-i, d),d)
        end
#        @printf("%i\t trees of depth %i\t check: %i\n", 2*niter, d, c)
        d += 2
    end
end

function binary_trees_o(N::Int=10)
    min_depth = 4
    max_depth = N
    stretch_depth = max_depth + 1

    # create and check stretch tree
    let c = checkarr(makearr(0, stretch_depth),stretch_depth)
#        @printf("stretch tree of depth %i\t check: %i\n", stretch_depth, c)
    end

    long_lived_tree = makearr(0, max_depth)

    loop_depths(min_depth, min_depth, max_depth)
#    @printf("long lived tree of depth %i\t check: %i\n", max_depth, check(long_lived_tree))
end


function loop_depths_oo(d, min_depth, max_depth)
    for i = 0:div(max_depth - d, 2)
        niter = 1 << (max_depth - d + min_depth)
        c = 0
        for j = 1:niter
            c += checkwa(make(i, d),d) + checkwa(make(-i, d),d)
        end
#        @printf("%i\t trees of depth %i\t check: %i\n", 2*niter, d, c)
        d += 2
    end
end

function binary_trees_oo(N::Int=10)
    min_depth = 4
    max_depth = N
    stretch_depth = max_depth + 1

    # create and check stretch tree
    let c = checkwa(make(0, stretch_depth),stretch_depth)
#        @printf("stretch tree of depth %i\t check: %i\n", stretch_depth, c)
    end

    long_lived_tree = make(0, max_depth)

    loop_depths_o(min_depth, min_depth, max_depth)
#    @printf("long lived tree of depth %i\t check: %i\n", max_depth, check(long_lived_tree))
end

