# Set operation tests

# pre-defined sets for testing
#E = @setbuild()
#U = @setbuild(Any)

@test all(x -> !(x in E), (0, 1))
@test all(x -> x in U, (0, 1))

@test complement(E) == U
@test complement(U) == E
@test ~U == E
@test ~E == U

X = @setbuild(x in I, 0 <= x < 10)
Y = @setbuild(x in I, 5 <= x < 15)
Z = @setbuild(Union{Int64, Int32}[Int32(-1), Int32(1), 2])

@test all(x -> x in X, 0:9)
@test all(x -> x ∈ X, 0:9)
@test all(x -> !(x in X), (-1, 10))

@test all(x -> x in union(X, Y, sb_on_error=1), 0:14)
@test all(x -> x in X ∪ Y, 0:14)
@test all(x -> !(x in union(X, Y)), (-1, 15))
@test all(x -> x in union(X, U), -1:15)
@test all(x -> x in X ∪ ~E, -1:15)
@test all(x -> x in union(X, E), 0:9)

@test all(x -> x in intersect(X, Y), 5:9)
@test all(x -> x ∈ X ∩ Y, 5:9)
@test all(x -> !(x in intersect(X, Y)), 0:4)
@test all(x -> x in intersect(X, U), 0:9)
@test all(x -> !(x in intersect(X, E)), -1:15)

@test all(x -> x in setdiff(X, Y), 0:4)
@test all(x -> x in X - Y, 0:4)
@test all(x -> !(x in setdiff(X, Y)), 5:9)
@test all(x -> !(x in setdiff(X, U)), -1:15)
@test all(x -> x in setdiff(U, X), 10:14)
@test all(x -> x in ~E - X, 10:14)
@test all(x -> x in setdiff(X, E), 0:9)
@test all(x -> !(x in setdiff(E, X)), -1:15)

@test all(x -> x in symdiff(X, Y), [0:4; 10:14])
@test all(x -> !(x in symdiff(X, Y)), 5:9)
@test all(x -> !(x in symdiff(X, U)), 0:9)
@test all(x -> x in symdiff(X, E), 0:9)

@test all(x -> x in X ∪ Z, [Int32(i) for i in -1:9])
@test all(x -> !(x in X ∩ Z), [0, 1])
