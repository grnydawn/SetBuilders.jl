# Set operation tests

#E = @setbuild()
#U = @setbuild(Any)

@test all(x -> !(x in E), (0, 1))
@test all(x -> x in U, (0, 1))

@test complement(E) == U
@test complement(U) == E
@test ~U == E
@test ~E == U

A = @setbuild(x in I, 0 <= x < 10)
B = @setbuild(x in I, 5 <= x < 15)
X = @setbuild(Union{Int64, Int32}[Int32(-1), Int32(1), 2])

@test all(x -> x in A, 0:9)
@test all(x -> x ∈ A, 0:9)
@test all(x -> !(x in A), (-1, 10))

@test all(x -> x in union(A, B, sb_on_error=1), 0:14)
@test all(x -> x in A ∪ B, 0:14)
@test all(x -> !(x in union(A, B)), (-1, 15))
@test all(x -> x in union(A, U), -1:15)
@test all(x -> x in A ∪ ~E, -1:15)
@test all(x -> x in union(A, E), 0:9)

@test all(x -> x in intersect(A, B), 5:9)
@test all(x -> x ∈ A ∩ B, 5:9)
@test all(x -> !(x in intersect(A, B)), 0:4)
@test all(x -> x in intersect(A, U), 0:9)
@test all(x -> !(x in intersect(A, E)), -1:15)

@test all(x -> x in setdiff(A, B), 0:4)
@test all(x -> x in A - B, 0:4)
@test all(x -> !(x in setdiff(A, B)), 5:9)
@test all(x -> !(x in setdiff(A, U)), -1:15)
@test all(x -> x in setdiff(U, A), 10:14)
@test all(x -> x in ~E - A, 10:14)
@test all(x -> x in setdiff(A, E), 0:9)
@test all(x -> !(x in setdiff(E, A)), -1:15)

@test all(x -> x in symdiff(A, B), [0:4; 10:14])
@test all(x -> !(x in symdiff(A, B)), 5:9)
@test all(x -> !(x in symdiff(A, U)), 0:9)
@test all(x -> x in symdiff(A, E), 0:9)

@test all(x -> x in A ∪ X, [Int32(i) for i in -1:9])
@test all(x -> !(x in A ∩ X), [0, 1])
