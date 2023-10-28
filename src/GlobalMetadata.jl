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

@noinline function throw_read_error(m::Module)
    throw(ArgumentError("Module $(m)'s metadata does not support read access."))
end
@noinline function throw_write_error(m::Module)
    throw(ArgumentError("Module $(m)'s metadata does not support write access."))
end

function DataAPI.metadata(p::ModuleProxy, key::AbstractString; style::Bool=false)
    DataAPI.metadata(p, Symbol(key); style=style)
end
@inline function DataAPI.metadata(p::ModuleProxy, key::Symbol; style::Bool=false)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).read || throw_read_error(mod)
    if style
        return (getglobal(mod, META)[key], :default)
    else
        return getglobal(mod, META)[key]
    end
end
function DataAPI.metadata(p::ModuleProxy, key::AbstractString, default; style::Bool=false)
    DataAPI.metadata(p, Symbol(key), default; style=style)
end
@inline function DataAPI.metadata(p::ModuleProxy, key::Symbol, default; style::Bool=false)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).read || throw_read_error(mod)
    if style
        return (get(getglobal(mod, META), key, default), :default)
    else
        return get(getglobal(mod, META), key, default)
    end
end
function DataAPI.metadatakeys(p::ModuleProxy)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).read || throw_read_error(mod)
    keys(getglobal(mod, META))
end
function DataAPI.metadata!(p::ModuleProxy, key::AbstractString, value; style::Symbol=:default)
    DataAPI.metadata!(p, Symbol(key), value)
end
function DataAPI.metadata!(p::ModuleProxy, key::Symbol, value; style::Symbol=:default)
    setindex!(getglobal(mod, META), value, key)
end
function DataAPI.deletemetadata!(p::ModuleProxy, key::AbstractString)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).write || throw_write_error(mod)
    DataAPI.deletemetadata!(getglobal(mod, META), Symbol(key))
end
function DataAPI.deletemetadata!(p::ModuleProxy, key::Symbol)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).write || throw_write_error(mod)
    delete!(getglobal(mod, META), key)
end
function DataAPI.emptymetadata!(p::ModuleProxy)
    mod = proxy_of(p)
    getglobal(mod, SUPPORT).write || throw_write_error(mod)
    empty!(delete!(getglobal(mod, META), key))
end

@nospecialize
"""
    GlobalMetadata.init(mod::Module[, md::AbstractDict{Symbol}; read::Bool=true, write::Bool=false])

Creates a constant global variable within `mod` to `This` (i.e., `mod.This`) whose value is
an instance of `ModuleProxy`. `mod.This` acts as a proxy for `mod` (`propertynames(mod) ==
propertynames(mod.This)`, `getproperty(mod, name) == getproperty(mod.This, name)`), The
instance of `This` generated is unique to `mod` without direclty storing any field data.

If the metadata argument is present, `md` will be made accessible through the metadata API
provided by the `DataAPI` package (e.g., `DataAPI.metadata(mod.This, key)`). The keyword
arguments (`read`, `write`) are used to specify what metadata accessing methods are supported.

`GlobalMetadata.init(mod)` and `GlobalMetadata.init(mod, md; read write)` may be called seperately,
providing access to `mod.This` with subsequent binding to global metadata in the module.
"""
function init(m::Module)
    if !isdefined(m, META)
        Core.eval(m, _this_expr(m))
    end
    nothing
end
function init(
    m::Module,
    md::Union{AbstractDict{Symbol}, NamedTuple};
    read::Bool = true,
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
