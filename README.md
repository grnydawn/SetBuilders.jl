# SetBuilders.jl

Julia Predicate and Enumerated Set Package

## Set Creations

```
using SetBuilders

I = SB_SET_INT

x = 1

# helper struct for testing
struct MyStruct
    a
    b
end

# helper functions for testing
function myfunc(x)
    x - 5
end

A = @setfilter(x in I, 0 <= x < 10)

B = @setfilter(x in I, 5 <= x < 15)

C = setfromtype(Complex)

D = @setfilter((x in A, y in B), x < 5 && y > 10)

E = @setfilter((x in A, y in B), c1*x + c2*y > 0, c1=-1, c2=1)

F = @setconvert(z in I, x -> x + 5, z -> z - 5, x in A)

G = @setconvert(z in I, x -> x + 5, z -> func(z), x in A, func=myfunc)

H = setfromtype(MyStruct)

J = @setconvert(z in H, (x, y) -> MyStruct(x, y), z -> (z.a, z.b),
                x in A, y in B, MyStruct=MyStruct)

K = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
                x in A, y in B, mystruct=MyStruct)

L = @setconvert(z in H, (x, y) -> mystruct(x[1], y[2]), z -> ((z.a, z.b), (z.a, z.b)),
                x in D, y in D, mystruct=MyStruct)

M = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> [(z.a, z.b), (z.b, z.a)],
                (x, y) in A, mystruct=MyStruct)

N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
                (x, y) in A, mystruct=MyStruct)

O = @setfilter(x in A, true)

P = @setfilter(x in A, false)

Q = setfromtype(Rational)

R = setfromtype(Real)

S = setfromtype(Dict{String, Number})

T = setfromtype(Vector{Int64})

U = setfromtype(Array{Float64, 2})

V = @setenum(1)

W = @setenum([x,2], type=Int64)

X = @setenum([Int32(-1), Int32(1),2], type=(Int64, Int32))

Y = @setenum(type=Union{Int64, Int32})

Z = I
```

## Set Membership Tests

```
#A = @setfilter(x in I, 0 <= x < 10)
@assert 0 in A
@assert 5 in A
@assert !(10 in A)
@assert !(-1 in A)

#B = @setfilter(x in I, 5 <= x < 15)
@assert 5 in B
@assert 10 in B
@assert !(15 in B)
@assert !(4 in B)

#C = setfromtype(Complex)
@assert 1 + 2im in C
@assert !(1 in C)

#D = @setfilter((x in A, y in B), x < 5 && y > 10)
@assert (0, 11) in D
@assert !((5, 10) in D)

#E = @setfilter((x in A, y in B), c1*x + c2*y > 0, c1=-1, c2=1)
@assert (0, 5) in E
@assert !((5, 5) in E)

#F = @setconvert(z in I, x -> x + 5, z -> z - 5, x in A)
@assert 5 in F
@assert 10 in F
@assert !(15 in F)

#G = @setconvert(z in I, x -> x + 5, z -> func(z), x in A, func=myfunc1)
@assert 5 in G
@assert 10 in G
@assert !(15 in G)

#H = setfromtype(MyStruct)
@assert MyStruct(1, 2) in H

#J = @setconvert(z in H, (x, y) -> MyStruct(x, y), z -> (z.a, z.b),
#                x in A, y in B, MyStruct=MyStruct)
@assert MyStruct(1, 5) in J
@assert !(MyStruct(10, 5) in J)

#K = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#                x in A, y in B, mystruct=MyStruct)
@assert MyStruct(1, 5) in K
@assert !(MyStruct(10, 5) in K)


#L = @setconvert(z in H, (x, y) -> mystruct(x[1], y[2]), z -> ((z.a, z.b), (z.a, z.b)),
#                x in D, y in D, mystruct=MyStruct)
@assert MyStruct(1, 11) in L
@assert !(MyStruct(1, 5) in L)

#M = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> [(z.a, z.b), (z.b, z.a)],
#                (x, y) in A, mystruct=MyStruct)
@assert MyStruct(1, 5) in M
@assert !(MyStruct(10, 5) in M)

#N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
#                (x, y) in A, mystruct=MyStruct)
@assert MyStruct(1, 5) in N
@assert !(MyStruct(10, 5) in N)

#O = @setfilter(x in A, true)
@assert 0 in O
@assert !(10 in O)

#P = @setfilter(x in A, false)
@assert !(5 in P)
@assert !(10 in P)

#Q = setfromtype(Rational)
@assert 1//2 in Q
@assert !(0.5 in Q)

#R = setfromtype(Real)
@assert 0.5 in R
@assert !(0.5im in R)

#S = setfromtype(Dict{String, Number})
@assert Dict{String, Number}("1" => 1) in S
@assert !(Dict{String, String}("1" => "1") in S)

#T = setfromtype(Vector{Int64})
@assert Vector{Int64}([1,1]) in T
@assert !(Vector{Int32}([1,1]) in T)

#U = setfromtype(Array{Float64, 2})
@assert Array{Float64, 2}([1 1; 2 2]) in U
@assert !(Array{Float32, 2}([1 1; 2 2]) in U)

#V = @setenum(1)
@assert 1 in V
@assert !(2 in V)

# x = 1
#W = @setenum([x,2], type=Int64)
@assert 1 in W
@assert !(3 in W)
@assert !(Int32(1) in W)

#X = @setenum([Int32(1),2], type=(Int64, Int32))
@assert Int64(2) in X
@assert !(Int64(1) in X)

#Y = @setenum(type=Union{Int64, Int32})
@assert !(1 in Y)
push!(Y, 1)
@assert 1 in Y

#Z = I
```

## Set Operation Tests

```
@assert all(x -> !(x in SB_SET_EMPTY), (0, 1))
@assert all(x -> x in SB_SET_UNIVERSAL, (0, 1))

@assert complement(SB_SET_EMPTY) == SB_SET_UNIVERSAL
@assert complement(SB_SET_UNIVERSAL) == SB_SET_EMPTY
@assert ~SB_SET_UNIVERSAL == SB_SET_EMPTY
@assert ~SB_SET_EMPTY == SB_SET_UNIVERSAL

#A = @setfilter(x in I, 0 <= x < 10)
#B = @setfilter(x in I, 5 <= x < 15)
#X = @setenum([Int32(-1), Int32(1),2], type=(Int64, Int32))

@assert all(x -> x in A, 0:9)
@assert all(x -> x ∈ A, 0:9)
@assert all(x -> !(x in A), (-1, 10))

@assert all(x -> x in union(A, B), 0:14)
@assert all(x -> x in A ∪ B, 0:14)
@assert all(x -> !(x in union(A, B)), (-1, 15))
@assert all(x -> x in union(A, SB_SET_UNIVERSAL), -1:15)
@assert all(x -> x in A ∪ ~SB_SET_EMPTY, -1:15)
@assert all(x -> x in union(A, SB_SET_EMPTY), 0:9)

@assert all(x -> x in intersect(A, B), 5:9)
@assert all(x -> x ∈ A ∩ B, 5:9)
@assert all(x -> !(x in intersect(A, B)), 0:4)
@assert all(x -> x in intersect(A, SB_SET_UNIVERSAL), 0:9)
@assert all(x -> !(x in intersect(A, SB_SET_EMPTY)), -1:15)

@assert all(x -> x in setdiff(A, B), 0:4)
@assert all(x -> x in A - B, 0:4)
@assert all(x -> !(x in setdiff(A, B)), 5:9)
@assert all(x -> !(x in setdiff(A, SB_SET_UNIVERSAL)), -1:15)
@assert all(x -> x in setdiff(SB_SET_UNIVERSAL, A), 10:14)
@assert all(x -> x in ~SB_SET_EMPTY - A, 10:14)
@assert all(x -> x in setdiff(A, SB_SET_EMPTY), 0:9)
@assert all(x -> !(x in setdiff(SB_SET_EMPTY, A)), -1:15)

@assert all(x -> x in symdiff(A, B), [0:4; 10:14])
@assert all(x -> !(x in symdiff(A, B)), 5:9)
@assert all(x -> !(x in symdiff(A, SB_SET_UNIVERSAL)), 0:9)
@assert all(x -> x in symdiff(A, SB_SET_EMPTY), 0:9)

@assert all(x -> x in A ∪ X, [Int32(i) for i in -1:9])
@assert all(x -> !(x in A ∩ X), [0, 1])
```
