"""
Main module for `SetBuilders` -- Julia Package for Predicate and Enumerable Sets

# Exports

* [`@setbuild`](@ref)     : builds a SetBuilders set
* [`@setpkg`](@ref)       : loads a set from a Julia module
* [`ismember`](@ref)/in/∈ : checks if an object is a member of a set
* [`describe`](@ref)      : generates a set description string
* [`fmap`](@ref)          : generates an element in codomain of a MappedSet
* [`bmap`](@ref)          : generates an element in domain of a MappedSet
* [`complement`](@ref)/~  : set complement operation
* [`SBSet`](@ref)         : the top level type of all SetBuilders sets

# Exports through Base module

* union/∪       : set union operation
* intersection/∩: set intersection operation
* setdiff/-     : set difference operation
* symdiff       : set symmetric difference operation
* push!         : adds an element to an EnumerableSet
* pop!          : removes an element from an EnumerableSet

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
