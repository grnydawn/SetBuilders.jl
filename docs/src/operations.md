# Set Operations
SetBuilders sets support conventional set operations including union,
intersection, difference, symmetric difference, and complement.

The first argument of the `all` function in the examples is an anonymous
function that is applied to all items in the last argument.

All of the following `@assert` checks should pass.
```julia
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
