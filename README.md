# GlobalMetadata

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/GlobalMetadata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/GlobalMetadata.jl/dev/)
[![Build Status](https://github.com/Tokazama/GlobalMetadata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Tokazama/GlobalMetadata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Tokazama/GlobalMetadata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Tokazama/GlobalMetadata.jl)


`GlobalMetadata` provides basic tooling for attaching globally stored metadata for objects.

If the type you want to attach metadata to is mutable then each instance has a unique global identifier and you may attach metadata to a global dictionary.
```julia
julia> x = ones(2, 2);

julia> @metadata!(x, :z, 3);

julia> @metadata(x, :z)
3

julia> Pair(:x, 1) in @metadata(x)
true
```

This is accomplished by assigning a dictionary to a global variable in the current module.
In the above example, the module's metadata dictionary is given a know key corresponding to `objectid(x)`, which is assigned a `Dict{Symbol,Any}` for storing metadata.
If this is the first time that any global metadata is being stored, this may also initialize the current module's metadata dictionary.
However, this package is still in the early stages of development and these are currently considered internal details that could break without notice.