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
I = @setbuild(Integer)           # creates a set from Julia Integer type
A = @setbuild(x ∈  I, 0 < x < 4) # creates a set with the predicate of "0 < x < 4"
B = @setbuild(x in I, 2 < x < 6) # creates a set with the predicate of "2 < x < 6"
C = A ∩ B                        # creates an intersection with the two sets
@assert 3 ∈ C                    # => true, 3 is a member of the set C
@assert !(4 in C)                # => true, 4 is not a member of the set C
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

## SetBuilders: Harnessing the Power of Predicate-Based Sets

Set, vital in math, finds new life in programming with Julia's SetBuilders.
This tool innovatively allows sets to be defined not just by listing
elements but also through predicates - logical formulas yielding true for
set members. Predicates in Julia can be any expression yielding a Boolean
result, thus enabling sophisticated set definitions through set operations.
Additionally, SetBuilders offers features such as event handlers and
customizable set descriptions, greatly enhancing its utility.

SetBuilders introduction

SetBuilders Usage

## Contents

```@index
```

[SetBuilders Github Repository: ](https://github.com/grnydawn/SetBuilders.jl).

