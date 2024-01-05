# SetBuilders.jl

Julia Predicate and Enumerated Set Package


## Introduction

Most of programming languages including Julia support a certain type of
enumerated sets, but not the type of predicate sets in mathematical sense.
For example, in Julia, we can create a set having integer values like

```julia
A = Set([1,2,3])
```
However, we cannot create something like this:

```julia
A = Set(x ∈ Integer | 0 < x < 4)
```

With the SetBuilders package, Julia users can create predicate sets, compose
them using set operations such as unions and intersections, and check if an
object is a member of the set.

```julia
I = @setbuild(Integer)           # creates a set from Julia Integer type
A = @setbuild(x ∈  I, 0 < x < 4) # creates a set with the predicate of "0 < x < 4"
B = @setbuild(x in I, 2 < x < 6) # creates a set with the predicate of "2 < x < 6"
C = A ∩ B                        # creates an intersection with the two sets
@assert 3 ∈ C                    # => true, 3 is a member of the set C
@assert !(4 in C)                # => true, 4 is not a member of the set C
```

## Installation

The package can be installed using the Julia package manager. From the Julia
REPL, type ] to enter the Pkg REPL mode and run:

```julia
pkg> add SetBuilders
```
Alternatively, it can be installed via the Pkg API:

```julia
julia> import Pkg; Pkg.add("SetBuilders")
```

## Usage

Once installed, the `SetBuilders` package can be loaded with `using SetBuilders`.

```julia
using SetBuilders
```

### Set Creations

SetBuilders provides one macro, `@setbuild`, for creating various types of
sets, including sets from Julia data types, predicate sets, enumerated sets,
and mapped sets.

Here are examples of set creations:
```
# Test fixtures
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

# Universal set
U = @setbuild(Any)

# sets from Julia types
I = @setbuild(Integer)
R = @setbuild(Real)
S = @setbuild(MyStruct)

# Enumerated sets
A = @setbuild([1, 2, 3])
B = @setbuild(Int64[value, 2])
C = @setbuild(Dict{String, String}[])

# Cartesian sets
D = @setbuild((I, I))
F = @setbuild((x, y) in I)
G = @setbuild((I^3, z in I))

# Predicate sets
H = @setbuild(x in I, 0 <= x < 10)
J = @setbuild(x in I, 5 <= x < 15)
K = @setbuild((x in H, y in J), x < 5 && y > 10)
L = @setbuild((x in H, y in J), c1*x + c2*y > 0, c1=-1, c2=1)
M = @setbuild(x in I, x + y > 0, y=value)
N = @setbuild(x in @setbuild(Real), x > 0)

# Mapped sets
O = @setbuild(z in I, (x in H) -> x + 5, z -> z - 5)
P = @setbuild(z in I, (x in J) -> x + 5, z -> func(z), func=myfunc)
Q = @setbuild(z in S, (x in H, y in J) -> mystruct(x, y),
                z -> (z.a, z.b), mystruct=MyStruct)
```

### Set Membership Tests

Once a set is created, checking if an object is a member of the set is
straightforward using the `in` or `∈` operators.

All of the following `@assert` checks should pass.
```
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

# Enumerated sets
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

### Set Operation Tests

SetBuilders also offers standard set operations such as union and intersection.

```
E = @setbuild()
U = @setbuild(Any)

@assert all(x -> !(x in E), (0, 1))
@assert all(x -> x in U, (0, 1))

@assert complement(E) == U
@assert complement(U) == E
@assert ~U == E
@assert ~E == U

I = @setbuild(Integer)
A = @setbuild(x in I, 0 <= x < 10)
B = @setbuild(x in I, 5 <= x < 15)
X = @setbuild(Union{Int64, Int32}[Int32(-1), Int32(1), 2])

@assert all(x -> x in A, 0:9)
@assert all(x -> x ∈ A, 0:9)
@assert all(x -> !(x in A), (-1, 10))

@assert all(x -> x in union(A, B), 0:14)
@assert all(x -> x in A ∪ B, 0:14)
@assert all(x -> !(x in union(A, B)), (-1, 15))
@assert all(x -> x in union(A, U), -1:15)
@assert all(x -> x in A ∪ ~E, -1:15)
@assert all(x -> x in union(A, E), 0:9)

@assert all(x -> x in intersect(A, B), 5:9)
@assert all(x -> x ∈ A ∩ B, 5:9)
@assert all(x -> !(x in intersect(A, B)), 0:4)
@assert all(x -> x in intersect(A, U), 0:9)
@assert all(x -> !(x in intersect(A, E)), -1:15)

@assert all(x -> x in setdiff(A, B), 0:4)
@assert all(x -> x in A - B, 0:4)
@assert all(x -> !(x in setdiff(A, B)), 5:9)
@assert all(x -> !(x in setdiff(A, U)), -1:15)
@assert all(x -> x in setdiff(U, A), 10:14)
@assert all(x -> x in ~E - A, 10:14)
@assert all(x -> x in setdiff(A, E), 0:9)
@assert all(x -> !(x in setdiff(E, A)), -1:15)

@assert all(x -> x in symdiff(A, B), [0:4; 10:14])
@assert all(x -> !(x in symdiff(A, B)), 5:9)
@assert all(x -> !(x in symdiff(A, U)), 0:9)
@assert all(x -> x in symdiff(A, E), 0:9)

@assert all(x -> x in A ∪ X, [Int32(i) for i in -1:9])
@assert all(x -> !(x in A ∩ X), [0, 1])
```
