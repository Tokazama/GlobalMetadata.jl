module GlobalMetadata

using DataAPI
using DataAPI: metadatakeys, metadata

#region GlobalMetadataDict
"""
    GlobalMetadata.GlobalMetadataDict
"""
struct GlobalMetadataDict{G} <: AbstractDict{Symbol, Any}
    getmeta::G

    global _GlobalMetadataDict(@nospecialize(x)) = new{typeof(x)}(x)
end

(gmd::GlobalMetadataDict)() = getfield(gmd, 1)()
Base.parentmodule(gmd::GlobalMetadataDict) = parentmodule(getfield(gmd, 1))

Base.length(gmd::GlobalMetadataDict) = length(gmd())

Base.iterate(gmd::GlobalMetadataDict) = iterate(gmd())
Base.iterate(gmd::GlobalMetadataDict, state) = iterate(gmd(), state)

Base.haskey(gmd::GlobalMetadataDict, k::AbstractString) = haskey(gmd, Symbol(k))
Base.haskey(gmd::GlobalMetadataDict, k::Symbol) = haskey(gmd(), k)

Base.getindex(gmd::GlobalMetadataDict, k::AbstractString) = getindex(gmd, Symbol(k))
Base.getindex(gmd::GlobalMetadataDict, k::Symbol) = getindex(gmd(), k)


Base.get(gmd::GlobalMetadataDict, k::AbstractString, default) = get(gmd, Symbol(k), default)
Base.get(gmd::GlobalMetadataDict, k::Symbol, default) = get(gmd(), k, default)
Base.get(f::Union{Function, Type}, gmd::GlobalMetadataDict, k::AbstractString) = get(f, gmd, Symbol(k))
Base.get(f::Union{Function, Type}, gmd::GlobalMetadataDict, k::Symbol) = get(f, gmd(), k)

Base.setindex!(gmd::GlobalMetadataDict, v, k::AbstractString) = setindex!(gmd, v, Symbol(k))
Base.setindex!(gmd::GlobalMetadataDict, v, k::Symbol) = setindex!(gmd(), v, k)

Base.delete!(gmd::GlobalMetadataDict, k::AbstractString) = delete!(gmd, Symbol(k))
Base.delete!(gmd::GlobalMetadataDict, k::Symbol) = delete!(gmd(), k)

#endregion GlobalMetadataDict

#region DataAPI
DataAPI.metadatakeys(m::Module) = keys(m.__metadata)
DataAPI.metadatasupport(::Type{Module}) = (; read=true, write=false)
function DataAPI.metadata(m::Module, key::AbstractString; style::Bool=false)
    metadata(m, Symbol(key); style=style)
end
@inline function DataAPI.metadata(m::Module, key::Symbol; style::Bool=false)
    if style
        return (m.__metadata[key], :default)
    else
        return m.__metadata[key]
    end
end
function DataAPI.metadata(m::Module, key::AbstractString, default; style::Bool=false)
    metadata(m, Symbol(key), default; style=style)
end
@inline function DataAPI.metadata(m::Module, key::Symbol, default; style::Bool=false)
    if style
        return (get(m.__metadata, key, default), :default)
    else
        return get(m.__metadata, key, default)
    end
end
#endregion DataAPI

const G_VAR = gensym(:g_var)
const G_GET = gensym(:g_get)

@nospecialize

"""
    GlobalMetadata.GlobalMetadataDict(g::Module, md::AbstractDict{Symbol}=IdDict{Symbol, Any}())

Assigns a dictionary of type `GlobalMetadataDict` to `g.__metadata`.
`g.__metadata` serves as an proxy for `md`, which is stored in a hidden global state.
`GlobalMetadataDict` supports the `AbstractDict` interface, providing access to `md`.

Metadata functions from the `DataAPI` package also provide public access
(`metadata(g, key)`). However, mutating methods such as `DataAPI.metadata!` are not
supported in order to discourage outside mutation of module metadata.
"""
function GlobalMetadataDict(mod::Module, md::AbstractDict{Symbol}=IdDict{Symbol, Any}())
    if !isdefined(mod, :__metadata)
        Core.eval(mod,
            quote
                const $(G_VAR) = $(md)
                $(G_GET)() = $(G_VAR)
                const __metadata = $(_GlobalMetadataDict)($(G_GET))
            end
        )
    end
end

@noinline function Base.showarg(io::IO, gmd::GlobalMetadataDict, toplevel::Bool)
    toplevel || print(io, "::")
    show(io, parentmodule(gmd))
    print(io, ".__metadata")
    nothing
end
function Base.show(io::IO, gmd::GlobalMetadataDict)
    summary(io, gmd)
    if !isempty(gmd)
        show(io, MIME"text/plain"(), gmd)
    end
    nothing
end
@specialize

GlobalMetadataDict(@__MODULE__)

end

# `g.__metadata` serves as
# whose value is an instance of `GlobalMetadataDict`.

# `g.__metadata` acts as a proxy for `mod` (`propertynames(mod) ==
# propertynames(mod.__metadata)`, `getproperty(mod, name) == getproperty(mod.__metadata, name)`), The
# instance of `__metadata` generated is unique to `mod` without direclty storing any field data.

# If the metadata argument is present, `md` will be accessible through the metadata API
# provided by the `DataAPI` package (e.g., `DataAPI.metadata(mod, key)`).
