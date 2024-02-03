# Membership Event
This section introduces event handlers that activate in response to the
outcomes of membership tests and their applications in different scenarios.
For example, using 
```julia
julia> using SetBuilders

julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> A = @setbuild(x ∈ I, 0 < x < 4)
PredicateSet((x ∈ TypeSet(Integer)) where 0 < x < 4)

julia> B = @setbuild(x ∈ I, 1 < x < 5)
PredicateSet((x ∈ TypeSet(Integer)) where 1 < x < 5)

julia> C = A ∩ B
CompositeSet(PredicateSet((x ∈ TypeSet(Integer)) where 0 < x < 4) ∩ PredicateSet((x ∈ TypeSet(Integer)) where 1 < x < 5))

julia> F = hist -> println(describe(hist[1].set, mark=hist[end].set))
#1 (generic function with 1 method)

julia> is_member(C, 1, on_notamember=F)
false
```

displays the details of set C's construction, pinpointing the specific
set that failed the membership test.

```julia
{ x ∈ A | 0 < x < 4 }, where
    A = { x ∈ ::Integer }
∩
 => { x ∈ A | 1 < x < 5 }, where
    A = { x ∈ ::Integer }
```
