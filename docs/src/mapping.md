# Set Element Generation
MappedSet contains mappings that associate each elements in the domain
and the codomain. This page explains how to use the mappings to generate
elements from one set to another.

To demonstrate the forward and backward mappings, following sets are prepared.

```julia
struct MyStruct
    a
    b
end

I  = @setbuild(Integer)
M1 = @setbuild(
        (x, y) in I,        # domain: a pair of integer values
        z in S,             # codomain: an instance of MyStruct type
        z = mystruct(x, y), # forward mapping: MyStruct z from the pair in the domain
        (x, y) = (z.a, z.b),# backward mapping: The domain is recovered from MyStruct fields
        mystruct=MyStruct   # Let SetBuilders know the name of mystruct
    )
```

## Forward mapping
Forward mapping maps from the elements in the domain to the ones in
codomain and backward mapping in reverse.



