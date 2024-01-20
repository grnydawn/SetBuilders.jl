# SetBuilders.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://grnydawn.github.io/SetBuilders.jl/dev/)

Julia Package for Predicate and Enumerable Sets


## Introduction

SetBuilders provides Julia users with the power of predicate-based sets.

Many programming languages, including Julia, support a type of enumerable
sets but not predicate sets in the mathematical sense. For instance,
in Julia, it's possible to create a set containing integer values, such as

```julia
A = Set([1,2,3])
```
However, creating the following is not possible:

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

### Set Creation
This part demonstrates the "@setbuild" macro in SetBuilders for creating sets
from Julia data types, predicates, and mappings. For example,
`I = @setbuild(Integer)` creates a set of all Julia Integer type objects, and
`A = @setbuild(x ∈ I, 0 < x < 4)` creates a set that implies to contain the
integers 1, 2, and 3.

### Set Membership
This section explains set membership checks using operators
such as "in" or "∈". In the previous example, "1 in A" would return "true",
whereas "4 ∈ A" would yield "false".

### Set Operations
It explores conventional set operations like union, intersection, difference,
symmetric difference, and complement. If `B = @setbuild(x ∈ I, 1 < x < 5)`,
then creating an intersection `C = A ∩ B` would result in `2 in C` being true,
but `1 in C` false.

### Set Description
This segment concentrates on generating detailed set descriptions. Combined
with set events, these descriptions are essential for intuitively
comprehending the reasons behind set membership outcomes in complex
situations. Using "println(describe(C))" displays the details of set C's
construction.:

```
{ x ∈ A | 0 < x < 4 }, where
    A = { x ∈ ::Integer }
∩
{ x ∈ A | 1 < x < 5 }, where
    A = { x ∈ ::Integer }
```

### Membership Event
This section introduces event handlers that activate in response to the
outcomes of membership tests and their applications in different scenarios.
For example, using
```
julia> F = hist -> println(describe(hist[1].set, mark=hist[end].set))
#1 (generic function with 1 method)

julia> is_member(C, 1, on_notamember=F)
false
```

displays the details of set C's construction, pinpointing the specific
set that failed the membership test.

```
{ x ∈ A | 0 < x < 4 }, where
    A = { x ∈ ::Integer }
∩
 => { x ∈ A | 1 < x < 5 }, where
    A = { x ∈ ::Integer }
```

### Element Mappings
MappedSet contains a map that associates each element in the domain with
zero or more elements in the codomain, known as a forward map. It also
includes a backward map for reverse mapping. Elements can be generated
using these maps.

# Set Sharing
Introduces a Julia module extension for creating, saving, and sharing sets
as files to facilitate collaboration among users.
