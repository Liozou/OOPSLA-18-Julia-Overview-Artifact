#=
This file provides a simple function `eachmethod` to iterate over the methods
defined in a module, or, by default, all the accessible methods.
It also provides the `collect_all_methods` utility to record all the currently
accessible methods in a StaticTable object. This is used to obtain static data
on tested packages.
=#

loaded_modules_array() = [Main]
function names_kwd(x::Module; all::Bool=false)
    return names(x, all)
end


function _eachmethod(f, m::Module, visited, vmt)
    push!(visited, m)
    for nm in names_kwd(m, all=true)
        if isdefined(m, nm)
            x = getfield(m, nm)
            if isa(x, Module) && !in(x, visited)
                _eachmethod(f, x, visited, vmt)
            elseif isa(x, Function)
                mt = typeof(x).name.mt
                if !in(mt, vmt)
                    push!(vmt, mt)
                    Base.visit(f, mt)
                end
            elseif isa(x, Type)
                x = Base.unwrap_unionall(x)
                if isa(x, DataType) && isdefined(x.name, :mt)
                    mt = x.name.mt
                    if !in(mt, vmt)
                        push!(vmt, mt)
                        Base.visit(f, mt)
                    end
                end
            end
        end
    end
end

"""
    eachmethod(f, modules = Base.loaded_modules_array())

Call `f` on each `Method` object for all method definitions in modules in the
given array.
`modules` to defaults to all loaded modules.
"""
function eachmethod(f, mods = loaded_modules_array())
    visited = Set{Module}()
    vmt = Set{Any}()
    for mod in mods
        _eachmethod(f, mod, visited, vmt)
    end
end



import Base.length
length(::Void) = 0
function length(x::TypeMapEntry)
    d = 1
    while x.next isa TypeMapEntry
        x = x.next
        d+=1
    end
    return d
end
function length(x::TypeMapLevel)
   ret = length(x.list)
   if x.arg1 isa Vector
       ret += sum(length, x.arg1)
   end
   if x.targ isa Vector
       ret += sum(length, x.targ)
   end
   return ret
end

struct Met
    sig::String
    nargs::Int32
    calls::Int32
    num_specializations::Int
    modul::String
end

function Met(x::Method)
    sig = string(x.sig)
    num_specializations = length(x.specializations)
    modul = string(split(string(x.module), '.')[1])
    return Met(sig, x.nargs, x.called, num_specializations, modul)
end

StaticTable = Dict{String, Vector{Met}}

"""
Record all the accessible methods to a StaticTable.
"""
function collect_all_methods()
    d = StaticTable()
    eachmethod() do m
        s = string(m.name)
        if haskey(d, s)
            push!(d[s], Met(m))
        else
            d[s] = [Met(m)]
        end
    end
    return d
end
