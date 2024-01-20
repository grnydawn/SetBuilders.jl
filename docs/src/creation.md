# Set Creation
This part demonstrates the "@setbuild" macro in SetBuilders for creating sets
from Julia data types, predicates, and mappings. For example,
`I = @setbuild(Integer)` creates a set of all Julia Integer type objects, and
`A = @setbuild(x ∈ I, 0 < x < 4)` creates a set that implies to contain the
integers 1, 2, and 3.

Here are examples of set creations:
```
# Test fixtures
value = 10

struct MyStruct
    a
    b
end

function myfunc(x)
    x - 5
end

# Empty set
E = @setbuild()

# Universal set
U = @setbuild(Any)

# sets from Julia types
I = @setbuild(Integer)
R = @setbuild(Real)
S = @setbuild(MyStruct)

# Partially enumerable sets
A = @setbuild([1, 2, 3])
B = @setbuild(Int64[value, 2])
C = @setbuild(Dict{String, String}[])

# Cartesian sets
D = @setbuild((I, I))
F = @setbuild((x, y) in I)
G = @setbuild((I^3, z in I))

# Predicate sets
H = @setbuild(x in I, 0 <= x < 10)
J = @setbuild(x in I, 5 <= x < 15)
K = @setbuild((x in H, y in J), x < 5 && y > 10)
L = @setbuild((x in H, y in J), c1*x + c2*y > 0, c1=-1, c2=1)
M = @setbuild(x in I, x + y > 0, y=value)
N = @setbuild(x in @setbuild(Real), x > 0)

# Mapped sets
O = @setbuild(z in I, (x in H) -> x + 5, z -> z - 5)
P = @setbuild(z in I, (x in J) -> x + 5, z -> func(z), func=myfunc)
Q = @setbuild(z in S, (x in H, y in J) -> mystruct(x, y),
                z -> (z.a, z.b), mystruct=MyStruct)
```

