# sets.jl : SetBuilder Set Types
#

# Top-level type of all sets

"""
    SBSet - Type

The `SBSet` type is the supertype of all SetBuilders set types.

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> I isa SBSet
true
```
"""
abstract type SBSet end

"""
    EmptySet - Type

The `EmptySet` type is a singleton type that implements a set containing
no member.

# Examples
```julia-repl
julia> E = @setbuild()
EmptySet()

julia> 1 in E
false
```
"""
struct EmptySet <: SBSet
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::EmptySet)
    print(io, "EmptySet()")
end


"""
    UniversalSet - Type

The `UniversalSet` type is a singleton type that implements a set containing
all object.

# Examples
```julia-repl
julia> U = @setbuild(Any)
UniversalSet()

julia> 1 in U
true
```
"""
struct UniversalSet <: SBSet
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::UniversalSet)
    print(io, "UniversalSet()")
end

"""
    TypeSet - Type

The `TypeSet` type implements a set containing members of Julia data types.

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> 1 in I
true
```
"""
struct TypeSet{T} <: SBSet where T
    _meta::Dict{Symbol, Any}
end
find_param(set::TypeSet{T}) where T  = T

function Base.show(io::IO, s::TypeSet{T}) where T
    #print(io, "TypeSet{$T}()")
    print(io, "TypeSet($T)")
end

"""
    EnumerableSet - Type

The `EnumerableSet` type implements a set containing enumerable members of
Julia data types.

The `EnumerableSet` type is similar to the standard Julia `Set` type in that
programmers can `push!` members into and `pop!` members from a set.

However, the `EnumerableSet` type strictly distinguishes the type of its
members. For example, with `A = @setbuild(Int64[])`, A can contain any `Int64`
values, but not `Int32` or objects of other types.

# Examples
```julia-repl
julia> A = @setbuild(Union{Int64, Float64}[1])
EnumerableSet([{Float64}*0, {Int64}*1])

julia> ismember(1, A)
true

julia> ismember(Int32(1), A)
false

julia> push!(A, Float64(2.0))
EnumerableSet([{Float64}*1, {Int64}*1])

julia> ismember(Float64(2.0), A)
true

julia> pop!(A, Float64(2.0))
2.0

julia> ismember(Float64(2.0), A)
false
```
"""
struct EnumerableSet <: SBSet
    _elems::Dict{DataType, Set{Any}}
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::EnumerableSet)
    dtypes = ["{$k}*$(length(v))" for (k,v) in s._elems]
    print(io, """EnumerableSet([$(join(dtypes, ", "))])""")
end

"""
    PredicateSet - Type

The `PredicateSet` type implements a set whose members are defined by
Julia Bool expression.

For example, `A = @setbuild(x in @setbuild(Real), 0 < x < 10)` creates
a set that contains all Julia real numbers bigger than 0 and less than 10.

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> A = @setbuild(x in I, 0 <= x < 10)
PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)

julia> ismember(0, A)  # 0 in A 
true

julia> ismember(10, A) # 10 in A
false
```
"""
struct PredicateSet <: SBSet
    _vars::NTuple{N, Tuple{Union{Symbol, Nothing}, SBSet}} where N
    _pred::Union{Bool, Symbol, Expr, Nothing}
    _env ::Dict{Symbol, Any}
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::PredicateSet)
    vars = ["($k ∈ $v)" for (k,v) in s._vars]
    print(io, """PredicateSet($(join(vars, ", ")) where $(string(s._pred)))""")
end

"""
    MappedSet - Type

The `MappedSet` type implements a set whose members are converted from 
another sets.

The conversion is defined by two mappings. First, a forward mapping 
specifies how members of the originating sets(Domain sets) are mapped 
to the member of the targeted set(image) within a pre-defined set(Codomain).
Secondly, a backward mapping specifies how the member in targeted set 
maps back to the originalting sets. This backward mapping ensures the
correctness of membership test.

In addition to the mappings, filter Boolean expressions can be used
after each mappings are applied so that unwanted results from the mappings
can be eliminated.

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> struct MyStruct
       a
       b
       end

julia> S = @setbuild(MyStruct)
TypeSet(MyStruct)

julia> A = @setbuild(s in S, (x in I, y in I) -> mystruct(x,y), s -> (s.a, s.b),
                     mystruct=MyStruct)
MappedSet((x ∈ TypeSet(Integer)), (y ∈ TypeSet(Integer)) -> (s ∈ TypeSet(MyStruct)))

julia> ismember(MyStruct(1, 1), A)   # MyStruct(1, 1) in A
true

julia> ismember(MyStruct(1.0, 1), A) # MyStruct(1.0, 1) in A
false
```
"""
struct MappedSet <: SBSet
    _domain::NTuple{N, Tuple{Symbol, SBSet}} where N
    _forward_map::Dict{Symbol, NTuple{N, Any} where N}
    _codomain_pred::NTuple{N, Union{Bool, Expr}} where N
    _codomain::NTuple{N, Tuple{Symbol, SBSet}} where N
    _backward_map::Dict{Symbol, NTuple{N, Any} where N}
    _domain_pred::NTuple{N, Union{Bool, Expr}} where N
    _env::Dict{Symbol, Any}
    _meta::Dict{Symbol, Any}
end
#    _forward_map::Tuple{Expr, Union{Bool, Expr}}
#    _backward_map::Tuple{Expr, Union{Bool, Expr}}

function Base.show(io::IO, s::MappedSet)
    dvars = ["($k ∈ $v)" for (k,v) in s._domain]
    cvars = ["($k ∈ $v)" for (k,v) in s._codomain]
    print(io, """MappedSet($(join(dvars, ", ")) -> $(join(cvars, ", ")))""")
end


"""
    CompositeSet - Type

The `CompositeSet` type implements a set by applying set operations
including union, intersection, complement, difference, and symetric 
difference.

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer) julia> A = @setbuild(x in I, 0 <= x < 10) PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10) julia> B = @setbuild(x in I, 5 <= x < 15)
PredicateSet((x ∈ TypeSet(Integer)) where 5 <= x < 15)

julia> C = A ∩ B
CompositeSet(PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10) ∩ PredicateSet((x ∈ TypeSet(Integer)) where 5 <= x < 15))

julia> ismember(5, C) # 5 in C
true

julia> ismember(0, C) # 0 in C
false
```
"""
struct CompositeSet <: SBSet
    _op::Symbol
    _sets::NTuple{N, SBSet} where N
    _meta::Dict{Symbol, Any}
end

function Base.show(io::IO, s::CompositeSet)
    sym = setops_syms[s._op]
    print(io, """CompositeSet($(join(s._sets, " $sym ")))""")
end

