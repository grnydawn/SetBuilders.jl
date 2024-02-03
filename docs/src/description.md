# Set Description
This section introduces on generating detailed set descriptions. Combined
with set events, these descriptions are essential for intuitively
comprehending the reasons behind set membership outcomes in complex
situations.

```julia
I = @setbuild(Integer)
A = @setbuild(x ∈ I, 0 < x < 4)
B = @setbuild(x ∈ I, 1 < x < 5)
C = A ∩ B
println(describe(C))
```

The "println(describe(C))" displays the details of set C's
construction.:
```julia
{ x ∈ A | 0 < x < 4 }, where
    A = { x ∈ ::Integer }
∩
{ x ∈ A | 1 < x < 5 }, where
    A = { x ∈ ::Integer }
```
