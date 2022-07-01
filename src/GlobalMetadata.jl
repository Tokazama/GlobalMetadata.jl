module GlobalMetadata

export @metadata, @metadata!

const GLOBAL_METADATA    = gensym(:metadata)

struct NoData end
const no_data = NoData()
haskey(::NoData, _) = false

# retrieve metadata in module `m` for object `obj` associated with key `k`. if `k` is not not found `data` is assigned to the key.
global_object_metadata!(m::Module, x, k, data) = get!(global_object_metadata!(m, x), k, data)
#endregion

function global_metadata(m::Module)
    isdefined(m, GLOBAL_METADATA) && return getfield(m, GLOBAL_METADATA)
    error("Module $(m) does not have any global metadata.")
end
global_metadata(m::Module, x) = global_metadata(m)[objectid(x)]
global_metadata(m::Module, x, key) = global_metadata(m)[objectid(x)][key]

"""
    @metadata(x[, k])

Retreive metadata associated with the object id of `x` (`objectid(x)`) in the current
module's global metadata. If the key `k` is specified only the value associated with
that key is returned.
"""
macro metadata()
    esc(:(GlobalMetadata.global_metadata(@__MODULE__)))
end
macro metadata(x)
    esc(:(GlobalMetadata.global_metadata(@__MODULE__, $(x))))
end
macro metadata(x, key)
    esc(:(GlobalMetadata.global_metadata(@__MODULE__, $(x), $(key))))
end

# has_global_metadata
has_global_metadata(m::Module) = isdefined(m, GLOBAL_METADATA)
function has_global_metadata(m::Module, x)
    has_global_metadata(m) && haskey(getfield(m, GLOBAL_METADATA), objectid(x))
end
function has_global_metadata(m::Module, x, k)
    has_global_metadata(m) && haskey(get(getfield(m, GLOBAL_METADATA), objectid(x), no_data), k)
end

"""
    @has_metadata(x)::Bool
    @has_metadata(x, k)::Bool

Does `x` have metadata stored in the curren modules' global metadata? Checks for the
presenece of the key `k` if specified.
"""

macro has_metadata(x)
    esc(:(GlobalMetadata.has_global_metadata(@__MODULE__, x)))
end
macro has_metadata(x, k)
    esc(:(GlobalMetadata.has_global_metadata(@__MODULE__, x, k)))
end

#=
    @has_metadata()::Bool
macro has_metadata()
    esc(:(GlobalMetadata.has_global_metadata(@__MODULE__)))
end
=#

# global_metadata!
function init_global_metadata!(m::Module, data=no_data)
    if has_global_metadata(m)
        return getfield(m, GLOBAL_METADATA)
    else
        gm = data === no_data ? IdDict{UInt,Dict{Symbol,Any}}() : data
        Core.eval(m, :(const $GLOBAL_METADATA = $(gm)))
        return gm
    end
end
function global_metadata!(m::Module, x, data=no_data)
    gm = init_global_metadata!(m)
    id = objectid(x)
    xm = get(gm, id, no_data)
    if xm === no_data
        xm = data === no_data ? Dict{Symbol,Any}() : data
        gm[id] = xm
        if _attach_global_metadata!(x, gm, id)
            @warn "Cannot create finalizer for $(typeof(x)). Global dictionary must be manually deleted."
        end
        return xm
    else
        return xm
    end
end
function _attach_global_metadata!(x, gm, id)
    there_is_no_finalizer = true
    if ismutable(x)
        _assign_global_metadata_finalizer(x,gm, id)
        there_is_no_finalizer = false
    elseif isstructtype(typeof(x))
        N = fieldcount(typeof(x))
        if N !== 0
            i = 1
            while (there_is_no_finalizer && i <= N)
                there_is_no_finalizer = _assign_global_metadata_finalizer(getfield(x, i), gm, id)
                i += 1
            end
        end
    end
    return there_is_no_finalizer
end
function _assign_global_metadata_finalizer(x, gm, id)
    if Base.ismutable(x)
        finalizer(x) do _
            @async delete!(gm, id)
        end
        return false
    else
        return true
    end
end
global_metadata!(m::Module, x, k, val) = get!(global_metadata(m, x), k, val)

"""
    @metadata!(x[data = Dict{Symbol,Any}()])

Initializes global metadata for `x` to `data`. If `data` is not provided then the default is
`Dict{Symbol,Any}()`.
"""
macro metadata!(x)
    esc(:(GlobalMetadata.global_metadata!(@__MODULE__, $(x))))
end
macro metadata!(x, data)
    esc(:(GlobalMetadata.global_metadata!(@__MODULE__, $(x), $(data))))
end

"""
    @metadata!(x, k, val)

Set the value of `x`'s global metadata associated with the key `k` to `val`.
"""
macro metadata!(x, k, val)
    esc(:(GlobalMetadata.global_metadata!(@__MODULE__, $(x), $(k), $(val))))
end

end
