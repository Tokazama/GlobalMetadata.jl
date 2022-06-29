using GlobalMetadata
using Test

@testset "GlobalMetadata" begin
    x = ones(2, 2)
    @test_throws ErrorException @metadata(x)
    xm = @metadata!(x)
    @metadata!(x, :x, 1)
    @metadata!(x, :y, 2)
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
    @test xm[:x] == 1
    @test xm[:y] == 2

    struct MyType{X}
        x::X
    end

    x = MyType(ones(2,2))
    GC.gc()
    @test isempty(@metadata!(x))  # test finalizer

    @test @metadata!(x, :x, 1) == 1
    @test @metadata!(x, :y, 2) == 2
    x = MyType(1)
    GC.gc()
    @test_logs(
        (:warn, "Cannot create finalizer for MyType{$Int}. Global dictionary must be manually deleted."),
        @metadata!(x)
    )
    @metadata!(x, :x, 1)
    @metadata!(x, :y, 2)
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
end
