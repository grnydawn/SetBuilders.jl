# SetBuilders.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://grnydawn.github.io/SetBuilders.jl/dev/)
[![Build Status](https://github.com/grnydawn/SetBuilders.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/grnydawn/SetBuilders.jl/actions/workflows/CI.yml?query=branch%3Amaster)

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

With the SetBuilders package, Julia users can create predicate sets and
combine them using set operations such as unions and intersections. They
can also check if an object is a member of a set and utilize many more
advanced features, including set events, set descriptions, set element
generation, and set sharing.

```julia
I = @setbuild(Integer)           # creates a set from Julia Integer type
A = @setbuild(x ∈  I, 0 < x < 4) # creates a set with the predicate of "0 < x < 4"
B = @setbuild(x in I, 2 < x < 6) # creates a set with the predicate of "2 < x < 6"
C = A ∩ B                        # creates an intersection with the two sets
                                 # As an alternative, "C = intersection(A, B)" can be used
@assert 3 ∈ C                    # => true, 3 is a member of the set C
                                 # As an alternative, "3 in C" can be used
@assert !(4 in C)                # => true, 4 is not a member of the set C
```
The `@setbuild` macro in SetBuilders creates various types of sets. In the
above example, the set `I` is built using the Julia `Integer` data type.
Meanwhile, the sets `A` and `B` are constructed by specifying the domain set
and a predicate using a boolean expression, and the set `C` is created using
the set intersection operator.

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

## Documentation

In addition to set creations, set operations, and membership tests shown in the
above example, SetBuilders also provides features such as **set event**,
**set description**, **set element generation**, and **set sharing**.

For more information on using the package, see the
[documentation](https://grnydawn.github.io/SetBuilders.jl/).
