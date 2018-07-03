include("eachmethodtype.jl")
import JSON
function listmodules(file)
    packages = readlines(file)
    op = Dict{String,String}()
    for package in packages
        cmd = `$(JULIA_HOME)/julia analyze-packages.jl analyze $package`
        println(cmd)
        res = chomp(readstring(cmd))
        println(res)
        op[package] = res
    end
    body = (join(map(pair->"$(pair[1]),$(pair[2])", collect(op)), "\n"))
    open("typesandfuncs.data", "w") do f
        write(f, body)
    end
end

global nfuncs = 0
global ntypes = 0
function handle_type(name, tdecl)
    if startswith(string(name), "##")
        return
    end
    global ntypes += 1
end

function handle_func(name, tdecl)
    if startswith(string(name), "##")
        return
    end
    global nfuncs += 1
end

if length(ARGS) > 1 # being called from above
    package = ARGS[2]
    eval(:(using $(Symbol(package))))
    eachmethod(handle_func, handle_type, [getfield(Main, Symbol(package))])
    println("$ntypes,$nfuncs")
else
    listmodules(ARGS[1])
end