# Set Operations
SetBuilders sets support conventional set operations including union,
intersection, difference, symmetric difference, and complement.

To support examples in this page, the following sets are pre-built.
To learn how to use `@setbuild` for the following set creations,
see [Set Creation](@ref).

```julia
I = @setbuild(Integer)
A = @setbuild(x in I, 0 <= x < 10)
B = @setbuild(x in I, 5 <= x < 15)
X = @setbuild(Union{Int64, Int32}[Int32(-1), Int32(1), 2])
```

## Union

The function `union` or the set operator `∪` performs set union.

```julia
@assert 0 in union(A, B)    # 0 is a member of set A
@assert 14 in A ∪ B         # 14 is a member of set B
@assert !(-1 in A ∪ B)      # -1 is not a member of either set A or set B
```

All of the `@assert` checks in this page should pass.

!!! note
    The number of set arguments can be more than two. For example,
    union(A, B, X) is allowed. "A ∪ B ∪ X" is same to "union(A, B, X)".

    This applies to other set operations including intersection, set
    difference, and set symmetric difference.

## Intersection

The function `intersect` or the set operator `∩` performs set intersection.

```julia
@assert 5 in intersect(A, B)    # 5 is a member of both set A and set B
@assert 9 in A ∩ B              # 9 is a member of both set A and set B
@assert !(0 in A ∩ B)           # 0 is a member of set A, but not of set B
```

## Difference

The function `setdiff` or the set operator `-` performs set difference.

```julia
@assert 0 in setdiff(A, B)      # 0 is a member of set A, but not of set B
@assert 4 in A - B              # 4 is a member of set A, but not of set B
@assert !(5 in A - B)           # 5 is a member of both set A and set B
```

## Symmetric Difference

The function `symdiff` performs set symmetric difference.

```julia
@assert 0  in symdiff(A, B)     # 0 is a member of set A, but not of set B
@assert 10 in symdiff(A, B)     # 10 is a member of set B, but not of set A
@assert !(5 in symdiff(A, B))   # 5 is a member of both set A and set B
```

!!! note
    Where there are more than two set arguments, the symmetric difference
    operation is applied as a binary operation with the result of the
    previous operation. For example, symdiff(A, B, X) is evaluated as
    symdiff(symdiff(A, B), X).

## Complement

The function `complement` or the set operator `~` performs set complement.

```julia
A = @setbuild(x in I, 0 <= x < 10)

@assert 10 in complement(A)     # 10 is not a member of set A
!assert !(1 in ~A)              # 1 is a member of set A
@assert 1 in ~complement(A)     # double complements cancel each other out
```

Also, note that the complement of the EmptySet is the UniversalSet, and
vice versa.

```julia
E = @setbuild()
U = @setbuild(Any)

@assert complement(E) == U
@assert complement(U) == E
@assert ~U == E
@assert ~E == U
```
