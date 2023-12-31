# SetBuilders sets

abstract type SBSet end

abstract type PredicateSet <: SBSet end

struct EmptySet <: SBSet end
SB_SET_EMPTY = EmptySet()

struct UniversalSet <: SBSet end
SB_SET_UNIVERSAL = UniversalSet()

struct EnumSet <: SBSet
    _elems::Dict{DataType, Set{Any}}
end

struct TypeSet{T} <: SBSet where T end

findparam(set::TypeSet{T}) where T  = T
setfromtype(type::Type)             = TypeSet{type}()

function Base.show(io::IO, s::TypeSet)
    print(io, "$(split(string(typeof(s)), ".")[2])")
end

struct FilteredSet <: PredicateSet
    _vars::NTuple{N, Tuple{Symbol, SBSet}} where N
    _pred::Expr
    _metadata::Dict{Symbol, Any}
    _env::Dict{Symbol, Any}
end

function Base.show(io::IO, s::FilteredSet)
    print(io, """\nFilteredSet(
    vars =$(s._vars)
    pred = $(s._pred))\n""")
end

struct ConvertedSet <: PredicateSet
    _domain::NTuple{N, Tuple{Symbol, SBSet}} where N
    _forward_map::Expr
    _backward_map::Tuple{Symbol, Expr}
    _codomain::Tuple{Symbol, SBSet}
    _metadata::Dict{Symbol, Any}
    _env::Dict{Symbol, Any}
end

function Base.show(io::IO, s::ConvertedSet)
    print(io, """\nConvertedSet(
    domain=$(s._domain)
    forward_map = $(s._forward_map)
    backward_map = $(s._backward_map)
    env = $(s._env)
    codomain = $(s._codomain))\n""")
end

struct CompositeSet <: SBSet
    _op::Symbol
    _sets::NTuple{N, SBSet} where N
end

function Base.show(io::IO, s::CompositeSet)
    print(io, """\nCompositeSet(
    op=$(s._op)
    sets = ($(join([string(t) for t in s._sets], ", ")))\n""")
end

SB_SET_INT      = setfromtype(Integer)
SB_SET_FLOAT    = setfromtype(AbstractFloat)
SB_SET_STR      = setfromtype(AbstractString)
SB_SET_REAL     = setfromtype(Real)
SB_SET_COMPLEX  = setfromtype(Complex)
SB_SET_RATIONAL = setfromtype(Rational)
