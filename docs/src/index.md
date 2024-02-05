```@meta
CurrentModule = SetBuilders
```

# SetBuilders

## In a nutshell...

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
using SetBuilders

I = @setbuild(Integer)           # creates a set from Julia Integer type
A = @setbuild(x ∈  I, 0 < x < 4) # creates a set with the predicate of "0 < x < 4"
B = @setbuild(x in I, 2 < x < 6) # creates a set with the predicate of "2 < x < 6"
C = A ∩ B                        # creates an intersection with the two sets
                                 # As an alternative, "intersect(A, B)" can be used
@assert 3 ∈ C                    # => true, 3 is a member of the set C
                                 # As an alternative, "3 in C" can be used
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

Once installed, the SetBuilders package can be loaded with using SetBuilders.

```julia
using SetBuilders
```

## Sets in Mathematics

Set theory, established by Georg Cantor in the late 19th century, is often
regarded as the language of mathematics. It introduces the concept of a set
as a collection of distinct objects and provides basic operations such as
union, intersection, and difference. The evolution of set theory, marked by
milestones like Cantor's work, Russell's Paradox, and the development of the
Zermelo-Fraenkel Set Theory (ZF), has shaped it into a robust, axiomatic
framework. This transformation solidified set theory's role as the universal
language for expressing and structuring mathematical ideas, making it
fundamental to the development and understanding of various mathematical
disciplines.

In modern mathematics, set theory's influence is all-encompassing. It is the
framework within which most mathematical concepts and theories are formulated
and discussed. From the abstract structures in algebra to the nuanced concepts
in topology and analysis, set theory provides the essential vocabulary and
syntax. It underpins the formation of groups, rings, and fields in algebra,
the characterization of space in topology, and the rigorous foundation of
calculus in analysis. This universality showcases set theory as not just
a branch of mathematics but as the foundational dialect through which
mathematics expresses itself.

## Sets in Programming

In programming languages like Julia and C++, the set data structure serves
a specific yet crucial function, primarily focused on managing collections
of unique elements. For instance, in Julia, converting an array to a set to
eliminate duplicates is straightforward: `my_set = Set(my_array)`. In C++,
the Standard Template Library (STL) provides a set container that
automatically removes duplicates and maintains element order, instantiated
with `std::set<int> my_set(my_array, my_array + array_size);`.

However, the application of sets in programming languages is more limited
compared to their comprehensive role in mathematics. In mathematics, set
theory is a fundamental discipline with wide-ranging implications. In
contrast, programming primarily utilizes sets for pragmatic tasks like data
manipulation and storage. While indispensable within their scope, these uses
do not capture the broad and abstract nature of mathematical set theory.
Consequently, sets in programming, despite their utility, represent a more
confined aspect of the extensive and foundational role they play in
mathematics.

## [SetBuilders](https://github.com/grnydawn/SetBuilders.jl): Harnessing the Power of Predicate-Based Sets

Set, vital in math, finds new life in programming with Julia's SetBuilders.
This tool innovatively allows sets to be defined not just by listing
elements but also through predicates - logical formulas yielding true for
set members. Predicates in Julia can be any expression yielding a Boolean
result, thus enabling sophisticated set definitions through set operations.
Additionally, SetBuilders offers features such as set event and
customizable set descriptions, greatly enhancing its utility.

```julia
# continues from the code example at the beginning of this page

F = hist -> println(describe(hist[1].set, mark=hist[end].set))
ismember(1, C, on_nomember=F)
```

The above example demonstrates how to identify the set that fails the
membership test among the sets in the set composition using set event and
set description features.

The value `1` is not a member of set `C` because the predicate of set `B`
excludes it. The following output from the previous code indicates that
the "=>" mark correctly identifies set `B` as the reason for exclusion.

```julia
{ x ∈ A | 0 < x < 4 }, where
    A = { x ∈ ::Integer }
∩
 => { x ∈ A | 1 < x < 5 }, where
    A = { x ∈ ::Integer }
```

The function `ismember` serves the same purpose as the membership operator,
`in` or `∈`, but with additional keyword arguments. In the example,
`on_nomember` accepts a function with one input argument, `hist`, and prints
the output from the `describe` function, which details the structure of the
first argument's set. Optionally, the `describe` function accepts a `mark`
keyword argument to highlight a specific set in the output. In this case,
`hist[end].set` is the set that fails the membership test.

For further details, please continue reading the following manual.

## Contents

* [Set Creation](@ref): explains how to use `@setbuild` macro for building various types of sets.
* [Set Operations](@ref): shows examples of using set operations.
* [Set Description](@ref): explains how to generate set descriptions.
* [Set Event](@ref): explains how to use set event with a callback function
* [Set Element Generation](@ref): explains how to generate set elements from Mapped sets.
* [Set Sharing](@ref): explains how to create/use/share a Julia module for sets
* [Reference](@ref): provides reference manual for using SetBuilders.
* [Developer Documentaion](@ref): explains how to extend SetBuilders.
