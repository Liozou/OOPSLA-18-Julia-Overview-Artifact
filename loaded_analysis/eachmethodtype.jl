if VERSION > v"0.6.3"
    loaded_modules_array = Base.loaded_modules_array
    function names_kwd(x::Module; all::Bool=false)
        return names(x, all=all)
    end
else
    loaded_modules_array() = [Main]
    function names_kwd(x::Module; all::Bool=false)
        return names(x, all)
    end
end


function _eachmethod(f, ft, m::Module, visited, vmt)
    push!(visited, m)
    for nm in names_kwd(m, all=true)
        if isdefined(m, nm)
            x = getfield(m, nm)
            if isa(x, Module) && !in(x, visited)
                _eachmethod(f, ft, x, visited, vmt)
            elseif isa(x, Function)
                mt = typeof(x).name.mt
                if !in(mt, vmt)
                    push!(vmt, mt)
                    Base.visit(d -> f(nm,d), mt)
                end
            elseif isa(x, Type)
                ft(nm,x)
                x = Base.unwrap_unionall(x)
                if isa(x, DataType) && isdefined(x.name, :mt)
                    mt = x.name.mt
                    if !in(mt, vmt)
                        push!(vmt, mt)
                        Base.visit(d -> f(nm,d), mt)
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
function eachmethod(f, ft, mods = loaded_modules_array())
    visited = Set{Module}()
    vmt = Set{Any}()
    for mod in mods
        _eachmethod(f, ft, mod, visited, vmt)
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
   return ret
end

struct Met
    sig::String
    nargs::Int32
    calls::Int32
    num_specializations::Int
    modul::String
end

Met(x::Method) = Met(string(x.sig), x.nargs, x.called, length(x.specializations),
                     string(split(string(x.module), '.')[1]))

StaticTable = Dict{String, Vector{Met}}

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