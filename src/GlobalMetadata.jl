module GlobalMetadata

using DataAPI

const META = gensym(:metadata)

# this shouldn't be constructed directly
# versions below 1.10 don't support the module in the type space.
# * < v"1.10" `Static` is `nothing` or `() -> mod::Module`
# * >= v"1.10" `Static` is `nothing` or `mod::Module`
struct ThisModule{
    STATIC,
    D<:Union{Nothing, Module},
    support
}
    dynamic::D

    global function _ThisModule(s, d, support::NamedTuple{(:read, :write), Tuple{Bool, Bool}})
        new{s, typeof(d), support}(d)
    end
end
@static if VERSION < v"1.10"
    (tm::ThisModule{STATIC})() where {STATIC} = isa(STATIC, Function) ? STATIC() : getfield(tm, 1)
    _this_module_expr(m::Module, nt) = :(const This = $(_ThisModule)(() -> $(m), nothing, $(nt)))
else
    (tm::ThisModule{STATIC})() where {STATIC} = isa(STATIC, Module) ? STATIC : getfield(tm, 1)
    _this_module_expr(m::Module, nt) = :(const This = $(_ThisModule)($(m), nothing, $(nt)))
end

@noinline function throw_read_error(m::Module)
    throw(ArgumentError("Module $(m)'s metadata does not support read access."))
end
@noinline function throw_write_error(m::Module)
    throw(ArgumentError("Module $(m)'s metadata does not support write access."))
end

DataAPI.metadatasupport(::Type{<:ThisModule{<:Any, <:Any, support}}) where {support} = support
function DataAPI.metadata(tm::ThisModule, key::AbstractString; style::Bool=false)
    DataAPI.metadata(tm, Symbol(key); style=style)
end
@inline function DataAPI.metadata(tm::ThisModule, key::Symbol; style::Bool=false)
    mod = tm()
    DataAPI.metadatasupport(typeof(tm)).read || throw_read_error(mod)
    if style
        return (getfield(mod, META)[key], :default)
    else
        return getfield(mod, META)[key]
    end
end
function DataAPI.metadata(tm::ThisModule, key::AbstractString, default; style::Bool=false)
    DataAPI.metadata(tm, Symbol(key), default; style=style)
end
@inline function DataAPI.metadata(tm::ThisModule, key::Symbol, default; style::Bool=false)
    mod = tm()
    DataAPI.metadatasupport(typeof(tm)).read || throw_read_error(mod)
    if style
        return (get(mod, key, default), :default)
    else
        return get(mod, key, default)
    end
end
DataAPI.metadatakeys(tm::ThisModule) = keys(getfield(tm(), META))

function DataAPI.metadata!(tm::ThisModule, key::AbstractString, value; style::Symbol=:default)
    DataAPI.metadata!(tm, Symbol(key), value)
end
function DataAPI.metadata!(tm::ThisModule, key::Symbol, value; style::Symbol=:default)
    mod = tm()
    DataAPI.metadatasupport(typeof(tm)).write || throw_write_error(mod)
    setindex!(getfield(mod, META), value, key)
end

function DataAPI.deletemetadata!(tm::ThisModule, key::AbstractString)
    DataAPI.deletemetadata!(tm::ThisModule, Symbol(key))
end
function DataAPI.deletemetadata!(tm::ThisModule, key::Symbol)
    mod = tm()
    DataAPI.metadatasupport(typeof(tm)).write || throw_write_error(mod)
    delete!(getfield(mod, META), key)
end
function DataAPI.emptymetadata!(tm::ThisModule)
    mod = tm()
    DataAPI.metadatasupport(typeof(tm)).write || throw_write_error(mod)
    empty!(getfield(mod, META))
end

@nospecialize
function initmeta(
    m::Module,
    md::AbstractDict{Symbol, Any};
    read::Bool = false,
    write::Bool = false,
)
    if !isdefined(m, META)
        Core.eval(m, Expr(:block, _this_module_expr(m, (; read, write)), :(const $(META) = $(md))))
    end
    nothing
end
Base.show(io::IO, tm::ThisModule) = show(io, MIME"text/plain"(), tm)
function Base.show(io::IO, m::MIME"text/plain", tm::ThisModule)
    if isa(x, typeof(this))
        return print(io, "this")
    elseif isa(x, typeof(This))
        return print(io, "This")
    elseif isa(x, ThisModule)
        show(io, tm()::Module)
        print(io, " --> this")
    end
    nothing
end

@specialize
# GlobalAlias
# GlobalValue

initmeta(@__MODULE__, IdDict{Symbol, Any}(); read=true, write=true)

end
