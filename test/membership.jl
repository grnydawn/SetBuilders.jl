# Tests for set membership
# Sets used in the tests are created in syntax.jl

#A = @setfilter(x in I, 0 <= x < 10)
@test 0 in A
@test 5 in A
@test !(10 in A)
@test !(-1 in A)

#B = @setfilter(x in I, 5 <= x < 15)
@test 5 in B
@test 10 in B
@test !(15 in B)
@test !(4 in B)

#C = setfromtype(Complex)
@test 1 + 2im in C
@test !(1 in C)

#D = @setfilter((x in A, y in B), x < 5 && y > 10)
@test (0, 11) in D
@test !((5, 10) in D)

#E = @setfilter((x in A, y in B), c1*x + c2*y > 0, c1=-1, c2=1)
@test (0, 5) in E
@test !((5, 5) in E)

#F = @setconvert(z in I, x -> x + 5, z -> z - 5, x in A)
@test 5 in F
@test 10 in F
@test !(15 in F)

#G = @setconvert(z in I, x -> x + 5, z -> func(z), x in A, func=myfunc1)
@test 5 in G
@test 10 in G
@test !(15 in G)

#H = setfromtype(MyStruct)
@test MyStruct(1, 2) in H

#I = SB_SET_INT

#J = @setconvert(z in H, (x, y) -> MyStruct(x, y), z -> (z.a, z.b),
#                x in A, y in B, MyStruct=MyStruct)
@test MyStruct(1, 5) in J
@test !(MyStruct(10, 5) in J)

#K = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#                x in A, y in B, mystruct=MyStruct)
@test MyStruct(1, 5) in K
@test !(MyStruct(10, 5) in K)


#L = @setconvert(z in H, (x, y) -> mystruct(x[1], y[2]), z -> ((z.a, z.b), (z.a, z.b)),
#                x in D, y in D, mystruct=MyStruct)
@test MyStruct(1, 11) in L
@test !(MyStruct(1, 5) in L)

#M = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> [(z.a, z.b), (z.b, z.a)],
#                (x, y) in A, mystruct=MyStruct)
@test MyStruct(1, 5) in M
@test !(MyStruct(10, 5) in M)

#N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#                (x, y) in A, mystruct=MyStruct)
@test MyStruct(1, 5) in N
@test !(MyStruct(10, 5) in N)

#O = @setfilter(x in A, true)
@test 0 in O
@test !(10 in O)

#P = @setfilter(x in A, false)
@test !(5 in P)
@test !(10 in P)

#Q = setfromtype(Rational)
@test 1//2 in Q
@test !(0.5 in Q)

#R = setfromtype(Real)
@test 0.5 in R
@test !(0.5im in R)

#S = setfromtype(Dict{String, Number})
@test Dict{String, Number}("1" => 1) in S
@test !(Dict{String, String}("1" => "1") in S)

#T = setfromtype(Vector{Int64})
@test Vector{Int64}([1,1]) in T
@test !(Vector{Int32}([1,1]) in T)

#U = setfromtype(Array{Float64, 2})
@test Array{Float64, 2}([1 1; 2 2]) in U
@test !(Array{Float32, 2}([1 1; 2 2]) in U)

#V = @setenum(1)
@test 1 in V
@test !(2 in V)

# x = 1
#W = @setenum([x,2], type=Int64)
@test 1 in W
@test !(3 in W)
@test !(Int32(1) in W)

#X = @setenum([Int32(1),2], type=(Int64, Int32))
@test Int64(2) in X
@test !(Int64(1) in X)

#Y = @setenum(type=Union{Int64, Int32})
@test !(1 in Y)
push!(Y, 1)
@test 1 in Y

#Z = I
