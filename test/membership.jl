# Set membership tests

# sets are pre-defined in "creations.jl"

## Empty set
#E = @setbuild()
@test !(1 in E)
@test !ismember(1, E)

## Universal set
#U = @setbuild(Any)
@test 1 in U
@test ismember(1, U)

## sets from Julia types
#I = @setbuild(Integer)
@test 1 in I
@test !(1.0 in I)
@test ismember(1, I)

#Q = @setbuild(Rational)
@test 1//2 in Q
@test !(0.5 in Q)

#R = @setbuild(Real)
@test 1.0 in R
@test !(1.0im in R)

#C = @setbuild(Complex)
@test 1.0im in C
@test !(1.0 in C)

#D = @setbuild(Dict{String, Number})
@test Dict{String, Number}("x" => 1 + 1im) in D

#V = @setbuild(Vector{Int64})
@test Int64[1,2,3] in V
@test !(Int32[1,2,3] in V)

#A = @setbuild(Array{Float64, 2})
@test Float64[1 2;3 4] in A
@test !(Float64[1; 2; 3; 4] in A)

#S = @setbuild(MyStruct)
@test MyStruct(1,2) in S
@test !(1 in S)

#G = @setbuild(Union{Integer, Float64})
@test 1 in G 
@test 1.0 in G 
@test !(Float32(1) in G)
@test ismember(1.0, G)

## Enumerable sets
#ENUM1 = @setbuild([1, 2, 3])
@test 1 in ENUM1 
@test !(4 in ENUM1)
@test ismember(1, ENUM1)

#ENUM2 = @setbuild(Int64[value, 2])
@test value in ENUM2 
@test !(Int32(value) in ENUM2)
@test !(3 in ENUM2)
push!(ENUM2, 3)
@test 3 in ENUM2
pop!(ENUM2, 3)
@test !(3 in ENUM2)

#ENUM3 = @setbuild(Union{Int64, Float64}[1, 2, 3.0])
@test 3.0 in ENUM3 
@test 1 in ENUM3 
@test !(4 in ENUM3)

#ENUM4 = @setbuild(Dict{String, String}[])
d1 = Dict{String, String}("a" => "x")
d2 = Dict{String, Integer}("a" => 1)
@test !(d1 in ENUM4)
push!(ENUM4, d1)
@test d1 in ENUM4 
@test !(d2 in ENUM4)

## Cartesian sets
#CART1 = @setbuild((I, I))
@test (1, 1) in CART1
@test !(1 in CART1)
@test !((1.0, 1.0) in CART1)
@test ismember((1, 1), CART1)

#CART2 = @setbuild((x in I, I))
@test (1, 1) in CART2
@test !(1 in CART2)
@test !((1.0, 1.0) in CART2)

#CART3 = @setbuild((x, y) in I)
@test (1, 1) in CART3
@test !(1 in CART3)
@test !((1.0, 1.0) in CART3)

#CART4 = @setbuild(((x, y) in I, z in I))
@test (1, 1, 1) in CART4
@test !(1 in CART4)
@test !((1.0, 1.0, 1.0) in CART4)

#CART5 = @setbuild((I^3, z in I))
@test (1, 1, 1, 1) in CART5
@test !(1 in CART5)
@test !((1.0, 1.0, 1.0, 1.0) in CART5)

## Predicate sets
#PRED1 = @setbuild(x in I, true)
@test 1 in PRED1
@test !(1.0 in PRED1)

#PRED2 = @setbuild(x in I, false)
@test !(1 in PRED2)

#PRED3 = @setbuild(x in I, 0 <= x < 10)
@test 0 in PRED3
@test !(10 in PRED3)
@test ismember(0, PRED3)

#PRED4 = @setbuild(x in I, 5 <= x < 15)
@test 5 in PRED4
@test !(15 in PRED4)

#PRED5 = @setbuild((x in PRED3, y in PRED4), x < 5 && y > 10)
@test (4, 11) in PRED5
@test !((9, 10) in PRED5)

#PRED6 = @setbuild((x in PRED3, y in PRED4), c1*x + c2*y > 0, c1=-1, c2=1)
@test (5, 10) in PRED6
@test !((9, 5) in PRED6)

#PRED7 = @setbuild(x in I, x + y > 0, y=value)
@test -9 in PRED7
@test !(-10 in PRED7)

#PRED8 = @setbuild(x in @setbuild(Real), x > 0)
@test 1 in PRED8
@test 1.0 in PRED8
@test !(1im in PRED8)

## Mapped sets
#MAPD1 = @setbuild(x in PRED3, z in I, z = x + 5, x = z - 5)
@test 5 in MAPD1
@test !(0 in MAPD1)
@test ismember(5, MAPD1)

#MAPD2 = @setbuild(x in PRED4, z in I, z = x + 5, x = func(z), func=myfunc)
@test 10 in MAPD2
@test !(5 in MAPD2)

#MAPD3 = @setbuild((x in PRED3, y in PRED4), z in S,  z = mystruct(x, y),
#                (x, y) = (z.a, z.b), mystruct=MyStruct)
@test MyStruct(0, 5) in MAPD3
@test !(MyStruct(10, 15) in MAPD3)

#MAPD4 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
#                (x, y) = (z.a, z.b), mystruct=MyStruct)
@test MyStruct(0, 0) in MAPD4
@test !(MyStruct(10, 10) in MAPD4)

#MAPD5 = @setbuild(x in PRED5, z in S, z = mystruct(x[1], x[2]),
#                x = [(z.a, z.b), (z.a, z.b)], mystruct=MyStruct)
@test MyStruct(4, 11) in MAPD5
@test !(MyStruct(9, 10) in MAPD5)

#MAPD6 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
#                (x, y) = [(z.a, z.b), (z.b, z.a)], mystruct=MyStruct)
@test MyStruct(5, 5) in MAPD6
@test !(MyStruct(10, 10) in MAPD6)

#MAPD7 = @setbuild(x in I, y in I, (y = x + 1, 0 <= y < 10),
#                    (x = y - 1, 0 <= x < 10))
@test 1 in MAPD7
@test !(10 in MAPD7)
