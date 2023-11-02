using GlobalMetadata
using Test

module DummyScope
    using DataAPI
    using GlobalMetadata
    using Test

    GlobalMetadata.GlobalMetadataDict(@__MODULE__)
    __metadata[:foo] = 1
    @test DataAPI.metadata(@__MODULE__, :foo) == __metadata[:foo] == 1
    @test DataAPI.metadata(@__MODULE__, :foo, 1) == get(__metadata, :foo, 1) == 1
    @test DataAPI.metadata(@__MODULE__, :bar, 2) == get(__metadata, :bar, 2) == 2
end
