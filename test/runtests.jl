using SetBuilders
using Test

#ENV["JULIA_DEBUG"] = Documenter

@testset "Functionality" begin

    include("creations.jl")
#    include("membership.jl")
#    include("operations.jl")
#    include("describe.jl")
#    include("event.jl")
    include("mapping.jl")
#    include("setpkg.jl")

end

@testset "Performance" begin
end

@testset "Scalability" begin
end

@testset "Quality" begin

    #include("Aqua.jl")
    #include("Documenter.jl")
    #include("JET.jl")

end

