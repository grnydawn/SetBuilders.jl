# Set describe tests

# sets are defined in "creations.jl"

## Empty set
#E = @setbuild()
@test describe(E) == "EmptySet(Ø)"

## Universal set
#U = @setbuild(Any)
@test describe(U) == "UniversalSet(U)"

## sets from Julia types
#I = @setbuild(Integer)
@test describe(I) == "{ x ∈ ::Integer }"

#D = @setbuild(Dict{String, Number})
@test describe(D) == "{ x ∈ ::Dict{String, Number} }"

#V = @setbuild(Vector{Int64})
@test describe(V) == "{ x ∈ ::Vector{Int64} }"

#A = @setbuild(Array{Float64, 2})
@test describe(A) == "{ x ∈ ::Matrix{Float64} }"

#S = @setbuild(MyStruct)
@test describe(S) == "{ x ∈ ::MyStruct }"

#G = @setbuild(Union{Integer, Float64})
@test describe(G) == "{ x ∈ ::Union{Float64, Integer} }"

## Enumerable sets
#ENUM1 = @setbuild([1, 2, 3])
@test describe(ENUM1) == "{ x ∈ ::Int64*3 }"

#ENUM2 = @setbuild(Int64[value, 2])
@test describe(ENUM2) == "{ x ∈ ::Int64*2 }"

#ENUM3 = @setbuild(Union{Int64, Float64}[1, 2, 3.0])
@test (describe(ENUM3) == "{ x ∈ (::Float64*1, ::Int64*2) }" ||
       describe(ENUM3) == "{ x ∈ (::Int64*2, ::Float64*1) }")

#ENUM4 = @setbuild(Dict{String, String}[])
@test describe(ENUM4) == "{ x ∈ ::Dict{String, String}*0 }"

## Cartesian sets
#CART1 = @setbuild((I, I))
@test describe(CART1) == """
{ c1 ∈ A, c2 ∈ B }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }"""

#CART2 = @setbuild((x in I, I))
@test describe(CART2) == """
{ x ∈ A, c1 ∈ B }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }"""

#CART3 = @setbuild((x, y) in I)
@test describe(CART3) == """
{ x ∈ A, y ∈ B }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }"""

#CART4 = @setbuild(((x, y) in I, z in I))
@test describe(CART4) == """
{ x ∈ A, y ∈ B, z ∈ C }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }
    C = { x ∈ ::Integer }"""

#CART5 = @setbuild((I^3, z in I))
@test describe(CART5) == """
{ c1 ∈ A, c2 ∈ B, c3 ∈ C, z ∈ D }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }
    C = { x ∈ ::Integer }
    D = { x ∈ ::Integer }"""

## Predicate sets
#PRED1 = @setbuild(x in I, true)
@test describe(PRED1) == """
{ x ∈ A | true }, where
    A = { x ∈ ::Integer }"""

#PRED2 = @setbuild(x in I, false)
@test describe(PRED2) == """
{ x ∈ A | false }, where
    A = { x ∈ ::Integer }"""

#PRED3 = @setbuild(x in I, 0 <= x < 10)
@test describe(PRED3) == """
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }"""

#PRED5 = @setbuild((x in PRED3, y in PRED4), x < 5 && y > 10)
@test describe(PRED5) == """
{ x ∈ A, y ∈ B | x < 5 && y > 10 }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    B = { x ∈ B.A | 5 <= x < 15 }, where
        B.A = { x ∈ ::Integer }"""

#PRED6 = @setbuild((x in PRED3, y in PRED4), c1*x + c2*y > 0, c1=-1, c2=1)
@test describe(PRED6) == """
{ x ∈ A, y ∈ B | c1 * x + c2 * y > 0 }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    B = { x ∈ B.A | 5 <= x < 15 }, where
        B.A = { x ∈ ::Integer }"""

## Mapped sets
#MAPD1 = @setbuild(x in PRED3, z in I, z = x + 5, x = z - 5)
@test describe(MAPD1) == raw"""

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
    B = { x ∈ ::Integer }"""


COMP1 = PRED3 ∪ PRED4
@test describe(COMP1) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
∪
{ x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }"""

COMP2 = PRED3 ∩ PRED4
@test describe(COMP2) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
∩
{ x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }"""

COMP3 = PRED3 - PRED4
@test describe(COMP3) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
-
{ x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }"""

@test describe(~COMP3) == raw"""
UniversalSet(U)
-
    { x ∈ A | 0 <= x < 10 }, where
        A = { x ∈ ::Integer }
    -
    { x ∈ A | 5 <= x < 15 }, where
        A = { x ∈ ::Integer }"""

@test describe(symdiff(COMP3, MAPD1)) == raw"""
    { x ∈ A | 0 <= x < 10 }, where
        A = { x ∈ ::Integer }
    -
    { x ∈ A | 5 <= x < 15 }, where
        A = { x ∈ ::Integer }
∆

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
    B = { x ∈ ::Integer }"""

collect_func = set -> string(typeof(set))
collect_vect = String[]
describe(symdiff(E, MAPD7), mark=(MAPD7, "=> "), collect=(collect_func, collect_vect))
@test all(item -> startswith(item, "SetBuilders."), collect_vect)
