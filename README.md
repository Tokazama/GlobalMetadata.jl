# GlobalMetadata

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/GlobalMetadata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/GlobalMetadata.jl/dev/)
[![Build Status](https://github.com/Tokazama/GlobalMetadata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Tokazama/GlobalMetadata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Tokazama/GlobalMetadata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Tokazama/GlobalMetadata.jl)


```julia
module DummyScope
    using DataAPI
    using GlobalMetadata
    # initialize global metadata
    GlobalMetadata.GlobalMetadataDict(@__MODULE__, IdDict{Symbol, Any}())
    # `__metadata` provides `DummyScope` with private syntax for mutating
    # global metadata
    __metadata[:foo] = 1

    # The metadata interface provided by `DataAPI` serves as a public interface
    # for reading metadata
    DataAPI.metadata(@__MODULE__, :foo) == __metadata[:foo] == 1
    DataAPI.metadata(@__MODULE__, :foo, 1) == get(__metadata, :foo, 1) == 1
    DataAPI.metadata(@__MODULE__, :bar, 2) == get(__metadata, :bar, 2) == 2
end
```