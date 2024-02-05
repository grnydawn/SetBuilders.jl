# Set Description
This section introduces on generating detailed set descriptions. 

The format of set description is drawn from the set-builder notation
in mathematics, like '{ x ∈ R | 0 < x < 4 }'.

## Sets from Julia types

```julia
I = @setbuild(Integer)

println(describe(I))
```
The above code prints the following output on screen.

```julia
{ x ∈ ::Integer }
```
Overall, the description is similar to the set-builder notation.
The double colon indicates of Julia type.

## Enumerable Set

```julia
E1 = @setbuild([1, 2, 3])

println(describe(E1))
```
The above code prints the following output on screen.

```julia
{ x ∈ ::Int64*3 }
```

In addition to the output seen with a set with Julia type,
the `*3` indicates that the set is EnumerableSet and the number of
elements in the set is 3.

```julia
E2 = @setbuild(Union{Int64, Float64}[1, 2, 3.0])

println(describe(E2))
```
The above code prints the following output on screen.

```julia
{ x ∈ (::Float64*1, ::Int64*2) }
```
The tuple indicates that the set `E2` can have members of the `Float64` or
`Int64` types, and the number of elements is 1 and 2, respectively.

## Cartesian Set

```julia
C = @setbuild((I, I))

println(describe(C))
```
The above code prints the following output on screen.

```julia
{ c1 ∈ A, c2 ∈ B }, where
    A = { x ∈ ::Integer }
    B = { x ∈ ::Integer }
```
The members of the cartesian set `C` are pairs of two elements from set `I`.
The `c1` and `c2` set variables and set names of `A` and `B` are automatically
created by SetBuilders. The set `A` is the first set and `B` is the second set
in the original cartesian set definition.

Each set `A` and set `B` are futher described with indentation.

## Predicate Set

```julia
P1 = @setbuild(x in I, 0 <= x < 10)

println(describe(P1))
```
The above code prints the following output on screen.

```julia
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
```
The left side of the vertical bar represents the set variable part, and
the right side represents the predicate part.

```julia
P2 = @setbuild(x in I, 5 <= x < 15)
P3 = @setbuild((x in P1, y in P2), x < 5 && y > 10)

println(describe(P3))
```
The above code prints the following output on screen.

```julia
{ x ∈ A, y ∈ B | x < 5 && y > 10 }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    B = { x ∈ B.A | 5 <= x < 15 }, where
        B.A = { x ∈ ::Integer }
```
The output indicates that the members of set `P3` are pairs of elements,
each from sets `A` and `B`, with the predicates 'x < 5 && y > 10'. The
members of sets `A` and `B` are Julia Integer values, each with the predicates
'0 <= x < 10' and '5 <= x < 15', respectively. To indicate the hierarchy of
sets, a dot ('.') is inserted between the capital letters, such as 'A.A'. The
capital letter progresses from A to Z and starts again from A if the number of
sets exceeds the number of alphabets such as "AA.A".

## Mapped Set

```julia
M1 = @setbuild(x in P1, z in I, z = x + 5, x = z - 5)

println(describe(M1))
```
The above code prints the following output on screen.

```julia

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
    B = { x ∈ ::Integer }
```
The first set description at the top of the output is the source set of the
'forward mapping', denoted as 'F-MAP'. Right below the forward mapping arrow
is the destination set. 'B-MAP' indicates 'backward mapping' from the
destination set to the source set.

With indentation, the sets and mappings used in the construction of MappedSet
are further described.

## Marking a set in description

Set operations and mappings make it easy to build a new set from multiple sets.
Therefore, we can conveniently and systematically describe a complex condition
using a set or a composite of sets generated from set operations and mappings.

However, as the number of sets involved in describing a condition increases,
analyzing the structure and relationships between the sets becomes more
challenging.

The `describe` function features a way to mark a specific set that is part of
a larger set, enabling users to easily pinpoint a specific set for a certain
purpose.

In previous examples, set `M1` uses sets `P1` and `I`, and set `P` uses set `I`.
Assuming we want to know all the cases in which set `I` is used in set `M1`, we
can use the `describe` function as follows:

```julia
println(describe(M1, mark=I))
```
produces

```julia

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
     => A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
 => B = { x ∈ ::Integer }
```
Note that there are two positions where set `I` is being used pointed by
"=>" mark.

In case that a different mark is preferred, we can use a tuple with a new mark
as following:

```julia
println(describe(M1, mark=(I, "## ")))
```
produces

```julia

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
     ## A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
 ## B = { x ∈ ::Integer }
```
