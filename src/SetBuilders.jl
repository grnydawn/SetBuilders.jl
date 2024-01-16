"""
Main module for `SetBuilders.jl` -- predicate-based set generation package for Julia.
"""
module SetBuilders

export SBSet, @setbuild, @setpkg, complement, is_member
export forward_map, backward_map, describe

include("utils.jl")
include("sets.jl")
include("membership.jl")
include("setops.jl")
include("describe.jl")
include("setpkg.jl")
include("macros.jl")

end
