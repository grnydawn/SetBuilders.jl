
@test all(x -> !(x in SB_SET_EMPTY), (0, 1))
@test all(x -> x in SB_SET_UNIVERSAL, (0, 1))

@test complement(SB_SET_EMPTY) == SB_SET_UNIVERSAL
@test complement(SB_SET_UNIVERSAL) == SB_SET_EMPTY
@test ~SB_SET_UNIVERSAL == SB_SET_EMPTY
@test ~SB_SET_EMPTY == SB_SET_UNIVERSAL

#A = @setfilter(x in I, 0 <= x < 10)
#B = @setfilter(x in I, 5 <= x < 15)
#X = @setenum([Int32(-1), Int32(1),2], type=(Int64, Int32))

@test all(x -> x in A, 0:9)
@test all(x -> x ∈ A, 0:9)
@test all(x -> !(x in A), (-1, 10))

@test all(x -> x in union(A, B), 0:14)
@test all(x -> x in A ∪ B, 0:14)
@test all(x -> !(x in union(A, B)), (-1, 15))
@test all(x -> x in union(A, SB_SET_UNIVERSAL), -1:15)
@test all(x -> x in A ∪ ~SB_SET_EMPTY, -1:15)
@test all(x -> x in union(A, SB_SET_EMPTY), 0:9)

@test all(x -> x in intersect(A, B), 5:9)
@test all(x -> x ∈ A ∩ B, 5:9)
@test all(x -> !(x in intersect(A, B)), 0:4)
@test all(x -> x in intersect(A, SB_SET_UNIVERSAL), 0:9)
@test all(x -> !(x in intersect(A, SB_SET_EMPTY)), -1:15)

@test all(x -> x in setdiff(A, B), 0:4)
@test all(x -> x in A - B, 0:4)
@test all(x -> !(x in setdiff(A, B)), 5:9)
@test all(x -> !(x in setdiff(A, SB_SET_UNIVERSAL)), -1:15)
@test all(x -> x in setdiff(SB_SET_UNIVERSAL, A), 10:14)
@test all(x -> x in ~SB_SET_EMPTY - A, 10:14)
@test all(x -> x in setdiff(A, SB_SET_EMPTY), 0:9)
@test all(x -> !(x in setdiff(SB_SET_EMPTY, A)), -1:15)

@test all(x -> x in symdiff(A, B), [0:4; 10:14])
@test all(x -> !(x in symdiff(A, B)), 5:9)
@test all(x -> !(x in symdiff(A, SB_SET_UNIVERSAL)), 0:9)
@test all(x -> x in symdiff(A, SB_SET_EMPTY), 0:9)

@test all(x -> x in A ∪ X, [Int32(i) for i in -1:9])
@test all(x -> !(x in A ∩ X), [0, 1])

# NOTE: may need tollerance for floating values
# NOTE: may use solvers such as Z3, JuMP, and others...
