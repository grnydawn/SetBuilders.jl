using JET

@testset "JET" begin

    JET.test_package(SetBuilders)

    @test_call target_modules=(SetBuilders,) @setbuild(x in @setbuild(Integer), x > 0 )
    @test_opt target_modules=(SetBuilders,) @setbuild(x in @setbuild(Integer), x > 0 )


end
