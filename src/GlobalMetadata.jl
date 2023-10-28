module GlobalMetadata

using DataAPI

if !isdefined(Base, :getglobal)
    const getglobal = getfield
end

const META = gensym(:metadata)
const SUPPORT = gensym(:support)

# this shouldn't be constructed directly
# versions below 1.10 don't support the module in the type space.
# * < v"1.10" `Static` is `nothing` or `() -> mod::Module`
# * >= v"1.10" `Static` is `nothing` or `mod::Module`
struct ModuleProxy{proxy}
    global _ModuleProxy(p) = new{p}()
end

@static if VERSION < v"1.10"
    proxy_of(::ModuleProxy{M}) where {M} = M()::Module
    _this_expr(m::Module) = :(const This = $(_ModuleProxy)(() -> $(m)))
else
    proxy_of(::ModuleProxy{M}) where {M} = M::Module
    _this_expr(m::Module) = :(const This = $(_ModuleProxy)($(m)))
end

Base.propertynames(p::ModuleProxy) = names(proxy_of(p))
Base.hasproperty(p::ModuleProxy, s::Symbol) = isdefined(proxy_of(p), s)
Base.getproperty(p::ModuleProxy, s::Symbol) = getproperty(proxy_of(p), s)
Base.getproperty(p::ModuleProxy, s::Symbol, order::Symbol) = getproperty(proxy_of(p), s, order)

DataAPI.metadatasupport(T::Type{<:ModuleProxy}) = getglobal(T()(), SUPPORT)

function DataAPI.metadata(p::ModuleProxy, key::AbstractString; style::Bool=false)
    DataAPI.metadata(p, Symbol(key); style=style)
end
@inline function DataAPI.metadata(p::ModuleProxy, key::Symbol; style::Bool=false)
    if style
        return (getglobal(proxy_of(p), META)[key], :default)
    else
        return getglobal(proxy_of(p), META)[key]
    end
end
function DataAPI.metadata(p::ModuleProxy, key::AbstractString, default; style::Bool=false)
    DataAPI.metadata(p, Symbol(key), default; style=style)
end
@inline function DataAPI.metadata(p::ModuleProxy, key::Symbol, default; style::Bool=false)
    if style
        return (get(getglobal(proxy_of(p), META), key, default), :default)
    else
        return get(getglobal(proxy_of(p), META), key, default)
    end
end
DataAPI.metadatakeys(p::ModuleProxy) = keys(getglobal(proxy_of(p), META))

function DataAPI.metadata!(p::ModuleProxy, key::AbstractString, value; style::Symbol=:default)
    DataAPI.metadata!(p, Symbol(key), value)
end
function DataAPI.metadata!(p::ModuleProxy, key::Symbol, value; style::Symbol=:default)
    setindex!(getglobal(proxy_of(p), META), value, key)
end

function DataAPI.deletemetadata!(p::ModuleProxy, key::AbstractString)
    DataAPI.deletemetadata!(getglobal(proxy_of(p), META), Symbol(key))
end
DataAPI.deletemetadata!(p::ModuleProxy, key::Symbol) = delete!(getglobal(proxy_of(p), META), key)
DataAPI.emptymetadata!(p::ModuleProxy) = empty!(delete!(getglobal(proxy_of(p), META), key))

@nospecialize
function init(m::Module)
    if !isdefined(m, META)
        Core.eval(m, _this_expr(m))
    end
    nothing
end
function init(
    m::Module,
    md::Union{AbstractDict{Symbol, Any}, NamedTuple};
    read::Bool = false,
    write::Bool = false,
)
    if !isdefined(m, META)
        Core.eval(m,
            Expr(:block,
                _this_expr(m),
                :(const $(SUPPORT) = $((; read, write))),
                :(const $(META) = $(md))
            )
        )
    else
        Core.eval(m,
            Expr(:block,
                :(const $(SUPPORT) = $((; read, write))),
                :(const $(META) = $(md))
            )
        )
    end
    nothing
end
Base.show(io::IO, p::ModuleProxy) = show(io, MIME"text/plain"(), p)
function Base.show(io::IO, m::MIME"text/plain", p::ModuleProxy)
    if isa(p, ModuleProxy)
        show(io, proxy_of(p))
        print(io, ".This")
    end
    nothing
end

@specialize

init(@__MODULE__)

end
