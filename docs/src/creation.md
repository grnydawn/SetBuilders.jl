# Set Creation
The `@setbuild`` macro in SetBuilders is the primary interface for creating
sets.

With this macro, users can create sets from Julia types, predicates, mappings,
and lists of elements.

## Empty Set and Universal Set
Let's start with the simplest ones: the empty set and the universal set.

```julia
E = @setbuild()     # Empty set
U = @setbuild(Any)  # Universal set
```
With no argument, @setbuild creates an empty set, which does not contain
any elements.

In Julia, the `Any` type is a special type that sits at the top of the type
hierarchy. With the `Any` type, `@setbuild` creates the universal set, which
includes all objects in Julia.

## Set from Julia Type
With Jula type, `@setbuild` creates a set that includes all instances
of that type.

```julia
struct MyStruct
    a
    b
end

I = @setbuild(Integer)
R = @setbuild(Real)
S = @setbuild(MyStruct)
```
The set `I` includes instances of all subtypes of `Integer` (`BigInt`,
`Int128`, `Int16`, `Int32`, `Int64`, `Int8`, `UInt128`, `UInt16`, `UInt32`,
`UInt64`, `UInt8`, and `Bool`).

Please note that the set `I` conceptually "includes" such elements,
but does not actually "contain" them.

Similarly, the set `R` includes all instances of all subtypes of the `Real`
type, encompassing all subtypes of `Integer`, `AbstractFloat`,
`AbstractIrrational`, and `Rational` types.

Note also that `@setbuild` can create sets from user-defined types.
The set `S` includes all instances of the `MyStruct` type.

## Enumerated Set
Similar to Julia's `Set` data structure, `@setbuild` can create a set from
a list of elements.

```julia
value = 10

A = @setbuild([1, 2, 3])
B = @setbuild(Int64[value, 2])
C = @setbuild(Dict{String, String}[])
```
The set `A` in the above example include the three elements.

Note that Setbuilders Enumerated Set actually "contains" the elements.

Users can specify the type of elements, as shown in the set `B`. There is one
difference in handling the type of elements compared to Julia's `Set`.
When an element is "pushed" into the set, `SetBuilder` enumerated sets do not
promote the element's type, whereas Julia `Set` does.

## Cartesian Product Set
In some cases, we may want to create a set by selecting elements from each set
and arranging the chosen elements in order, known as the Cartesian product.

```julia
D = @setbuild((I, I))
F = @setbuild((x, y) in I)
G = @setbuild((I^3, z in I))
```
The set `D` includes all pairs of elements from the set `I`, previously defined
in the example above as a set of Julia `Integer` type.

The set `F` offers another syntax for creating a set of Integer pairs, similar
to the set `D`.

The set `G` demonstrates another syntax for creating a Cartesian product set
with the 4-ary Cartesian product set.

## Predicate Set
Predicates are logical formulas that yield true for set members. In `SetBuilders`,
predicates can be any expression yielding a `Boolean` result, including functions.

```julia
H = @setbuild(x in I, 0 <= x < 10)
J = @setbuild(x in I, 5 <= x < 15)
K = @setbuild((x in H, y in J), x < 5 && y > 10)
L = @setbuild((x in H, y in J), c1*x + c2*y > 0, c1=-1, c2=1)
M = @setbuild(x in I, x + y > 0, y=value)
N = @setbuild(x in @setbuild(Real), x > 0)
```
The sets `H` and `J` in the above example have two arguments. The first
argument defines the domain of the sets. In other words, all members of
the sets `H` and `J` should also be members of the set I. Additionally,
all members of these sets should satisfy the Boolean expression of the
second argument.

The set `K` demonstrates how to define the domain of a set using multiple
sets.

The sets `L` and `M` show how to use values defined outside of the
`@setbuild` macro.

The set `N` illustrates that the `@setbuild` macro can be nested within
another `@setbuild` macro.

## Mapped Set
With a Mapped Set, users can create a set using mappings from one set to
another.

```julia
function myfunc(x)
    x - 5
end

O = @setbuild(z in I, (x in H) -> x + 5, z -> z - 5)
P = @setbuild(z in I, (x in J) -> x + 5, z -> func(z), func=myfunc)
Q = @setbuild(z in S, (x in H, y in J) -> mystruct(x, y),
                z -> (z.a, z.b), mystruct=MyStruct)
```
A "Mapped Set" should have at least three arguments. The first argument
defines the target set, or codomain in mathematical terms. For example, the
members of the set `O` (denoted as "z") comprise some members of the set `I`.

The second argument defines a "forward" mapping from the starting set (domain)
to the destination set (codomain). The arrow in the second argument indicates
that it is a mapping. The left part of the arrow defines the domain; for the
set `O`, the domain set is `H`. The right part of the arrow defines the
instructions for generating members in the codomain.

The third argument defines a "backward" mapping from the codomain to the domain.

The set `P` demonstrates how to use a function defined outside of `@setbuild`
to create a mapping.

The set `Q` shows that a mapped set can map to a user-defined type.
