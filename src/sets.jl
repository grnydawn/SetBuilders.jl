# sets.jl : SetBuilder Set Types
#

# Top-level type of all sets
abstract type SBSet end

# Empty set
struct EmptySet <: SBSet end

function Base.show(io::IO, s::EmptySet)
    print(io, "EmptySet()")
end

# Universal set
struct UniversalSet <: SBSet end

function Base.show(io::IO, s::UniversalSet)
    print(io, "UniversalSet()")
end

# Set for Julia types
struct TypeSet{T} <: SBSet where T end
find_param(set::TypeSet{T}) where T  = T

function Base.show(io::IO, s::TypeSet{T}) where T
    #print(io, "TypeSet{$T}()")
    print(io, "TypeSet($T)")
end

# PartiallyPartiallyEnumerableerated set
struct PartiallyEnumerableSet <: SBSet
    _elems::Dict{DataType, Set{Any}}
end

function Base.show(io::IO, s::PartiallyEnumerableSet)
    dtypes = ["{$k}*$(length(v))" for (k,v) in s._elems]
    print(io, """PartiallyEnumerableSet([$(join(dtypes, ", "))])""")
end

# Set mapped to itself with filtering
struct PredicateSet <: SBSet
    _vars::NTuple{N, Tuple{Union{Symbol, Nothing}, SBSet}} where N
    _pred::Union{Bool, Symbol, Expr}
    _env ::Dict{Symbol, Any}
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::PredicateSet)
    vars = ["($k ∈ $v)" for (k,v) in s._vars]
    print(io, """PredicateSet($(join(vars, ", ")) where $(string(s._pred)))""")
end

# Set generated from another set
struct MappedSet <: SBSet
    _domain::NTuple{N, Tuple{Symbol, SBSet}} where N
    _forward_map::Tuple{Expr, Union{Bool, Expr}}
    _backward_map::Tuple{Expr, Union{Bool, Expr}}
    _codomain::NTuple{N, Tuple{Symbol, SBSet}} where N
    _env::Dict{Symbol, Any}
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::MappedSet)
    dvars = ["($k ∈ $v)" for (k,v) in s._domain]
    cvars = ["($k ∈ $v)" for (k,v) in s._codomain]
    print(io, """MappedSet($(join(dvars, ", ")) -> $(join(cvars, ", ")))""")
end


# Set composed with another sets
struct CompositeSet <: SBSet
    _op::Symbol
    _sets::NTuple{N, SBSet} where N
end

function Base.show(io::IO, s::CompositeSet)
    sym = setops_syms[s._op]
    print(io, """CompositeSet($(join(s._sets, " $sym ")))""")
end

