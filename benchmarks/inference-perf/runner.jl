file = ARGS[1]
mod = ARGS[2]
prog = ARGS[3]
mode = 0

stopmod = :none
stopfun = :none
stoppc = 0
if length(ARGS) > 3
    mode = parse(Int, ARGS[4])
end
if mode == 2
    stopmod = Symbol(ARGS[5])
    stopfun = Symbol(ARGS[6])
    stoppc = parse(Int, ARGS[7])
end


module Inner end
Inner.eval(:(include($file)))
Inner.eval(mod)

expr = parse(prog)
Inner.eval(:(function test() $expr end))


Core.Inference.bitf_set_hash(h->hash(repr(h)))
Core.Inference.bitf_module_set(:Inner)
Core.Inference.bitf_set_showerror(showerror)
if mode == 2
    Core.Inference.bitf_trigger_set((stopmod, stopfun, stoppc))
end
if mode == 1
    Core.Inference.bitf_log_set(true)
end
Inner.test()

trials = Array{Any,1}()
for i=1:1
    push!(trials,@timed Inner.test())
end

if mode == 1
    Core.Inference.bitf_print_set(false)
    for i=1:length(Core.Inference.bitf_pcs)
        if isassigned(Core.Inference.bitf_pcs, i)
            res = Core.Inference.bitf_pcs[i]
            println("$(res[1]) $(res[2]) $(res[3])")
        end
    end
else
    println("$(Core.Inference.bitf_getfields) $(Core.Inference.bitf_allocs_removed)")
    for trial in trials
        val, t, bytes, gctime, memallocs = trial
        println("$t $bytes $gctime")
    end
    for inlined in Core.Inference.bitf_functions
        println(inlined[3])
    end
end

#=
if timing
    pre_total = Core.Inference.bitf_total
    result = @timed eval(pp)
    post_total = Core.Inference.bitf_total
else
    pre_total = Core.Inference.bitf_total
    eval(pp)
    post_total = Core.Inference.bitf_total
end

Core.Inference.bitf_trigger_set(-1)
Core.Inference.bitf_print_set(false)
if timing
    val,timings = result
    println(timings)
end
    println(post_total - pre_total)

=#
