"""
Main module for `SetBuilders` -- Julia Package for Predicate and Enumerable Sets

# Exports

- [`@setbuild`](@ref): Builds a SetBuilders set.
- [`@setpkg`](@ref): Loads a set from a Julia module.
- [`ismember`](@ref)/`in`/`∈`: Checks if an object is a member of a set.
- [`describe`](@ref): Generates a set description string.
- [`fmap`](@ref): Converts an element in the domain to one in the codomain.
- [`bmap`](@ref): Converts an element in the codomain to one in the domain.
- [`complement`](@ref)/`~`: Performs the set complement operation.
- [`SBSet`](@ref): Represents the top-level type of all SetBuilders sets.

# Exports through the Base Module

- `union`/`∪`: Performs the set union operation.
- `intersection`/`∩`: Performs the set intersection operation.
- `setdiff`/`-`: Performs the set difference operation.
- `symdiff`: Performs the set symmetric difference operation.
- `push!`: Adds an element to an EnumerableSet.
- `pop!`: Removes an element from an EnumerableSet.
"""
module SetBuilders

export SBSet, @setbuild, @setpkg, complement, ismember
export fmap, bmap, describe

include("utils.jl")
include("sets.jl")
include("membership.jl")
include("setops.jl")
include("describe.jl")
include("setpkg.jl")
include("macros.jl")

end
