# Set Membership
This section explains set membership checks using "in" or "∈"
operators by showing various examples.

All of the following `@assert` checks should pass.
```julia
# test fixtures
value = 10

struct MyStruct
    a
    b
end

function myfunc(x)
    x - 5
end

# Empty set
E = @setbuild()
@assert !(1 in E)

# Universal set
U = @setbuild(Any)
@assert 1 in U

# sets from Julia types
I = @setbuild(Integer)
@assert 1 in I
@assert !(1.0 in I)

R = @setbuild(Real)
@assert 1.0 in R
@assert !(1.0im in R)

S = @setbuild(MyStruct)
@assert MyStruct(1,2) in S
@assert !(1 in S)

# Enumeratable sets
A = @setbuild([1, 2, 3])
@assert 1 in A
@assert !(4 in A)

B = @setbuild(Int64[value, 2])
@assert value in B
@assert !(Int32(value) in B)
@assert !(3 in B)
push!(B, 3)
@assert 3 in B
pop!(B, 3)
@assert !(3 in B)

C = @setbuild(Dict{String, String}[])
d1 = Dict{String, String}("a" => "x")
d2 = Dict{String, Integer}("a" => 1)
@assert !(d1 in C)
push!(C, d1)
@assert d1 in C
@assert !(d2 in C)

# Cartesian sets
D = @setbuild((I, I))
@assert (1, 1) in D
@assert !(1 in D)
@assert !((1.0, 1.0) in D)

F = @setbuild((x, y) in I)
@assert (1, 1) in F
@assert !(1 in F)
@assert !((1.0, 1.0) in F)

G = @setbuild((I^3, z in I))
@assert (1, 1, 1, 1) in G
@assert !(1 in G)
@assert !((1.0, 1.0, 1.0, 1.0) in G)

# Predicate sets
H = @setbuild(x in I, 0 <= x < 10)
@assert 0 in H
@assert !(10 in H)

J = @setbuild(x in I, 5 <= x < 15)
@assert 5 in J
@assert !(15 in J)

K = @setbuild((x in H, y in J), x < 5 && y > 10)
@assert (4, 11) in K
@assert !((9, 10) in K)

L = @setbuild((x in H, y in J), c1*x + c2*y > 0, c1=-1, c2=1)
@assert (5, 10) in L
@assert !((9, 5) in L)

M = @setbuild(x in I, x + y > 0, y=value)
@assert -9 in M
@assert !(-10 in M)

N = @setbuild(x in @setbuild(Real), x > 0)
@assert 1 in N
@assert 1.0 in N
@assert !(1im in N)

# Mapped sets
O = @setbuild(z in I, (x in H) -> x + 5, z -> z - 5)
@assert 5 in O
@assert !(0 in O)

P = @setbuild(z in I, (x in J) -> x + 5, z -> func(z), func=myfunc)
@assert 10 in P
@assert !(5 in P)

Q = @setbuild(z in S, (x in H, y in J) -> mystruct(x, y),
                z -> (z.a, z.b), mystruct=MyStruct)
@assert MyStruct(5, 5) in Q
@assert !(MyStruct(10, 10) in Q)

```


