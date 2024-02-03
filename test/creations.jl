# Set creation tests

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

Q = @setbuild(Rational)

R = @setbuild(Real)

C = @setbuild(Complex)

D = @setbuild(Dict{String, Number})

V = @setbuild(Vector{Int64})

A = @setbuild(Array{Float64, 2})

S = @setbuild(MyStruct)

G = @setbuild(Union{Integer, Float64})

# Enumerable set
ENUM1 = @setbuild([1, 2, 3])

ENUM2 = @setbuild(Int64[value, 2])

ENUM3 = @setbuild(Union{Int64, Float64}[1, 2, 3.0])

ENUM4 = @setbuild(Dict{String, String}[])

# Cartesian sets
CART1 = @setbuild((I, I))

CART2 = @setbuild((x in I, I))

CART3 = @setbuild((x, y) in I)

CART4 = @setbuild(((x, y) in I, z in I))

CART5 = @setbuild((I^3, z in I))

# Predicate sets
PRED1 = @setbuild(x in I, true)

PRED2 = @setbuild(x in I, false)

PRED3 = @setbuild(x in I, 0 <= x < 10)

PRED4 = @setbuild(x in I, 5 <= x < 15)

PRED5 = @setbuild((x in PRED3, y in PRED4), x < 5 && y > 10)

PRED6 = @setbuild((x in PRED3, y in PRED4), c1*x + c2*y > 0, c1=-1, c2=1)

PRED7 = @setbuild(x in I, x + y > 0, y=value)

PRED8 = @setbuild(x in @setbuild(Real), x > 0)

# Mapped sets
MAPD1 = @setbuild(x in PRED3, z in I, z = x + 5, x = z - 5)

MAPD2 = @setbuild(x in PRED4, z in I, z = x + 5, x = func(z), func=myfunc)

MAPD3 = @setbuild((x in PRED3, y in PRED4), z in S,  z = mystruct(x, y),
                (x, y) = (z.a, z.b), mystruct=MyStruct)

MAPD4 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
                (x, y) = (z.a, z.b), mystruct=MyStruct)

MAPD5 = @setbuild(x in PRED5, z in S, z = mystruct(x[1], x[2]),
                x = [(z.a, z.b), (z.a, z.b)], mystruct=MyStruct)

MAPD6 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
                (x, y) = [(z.a, z.b), (z.b, z.a)], mystruct=MyStruct)

MAPD7 = @setbuild(x in I, y in I, (y = x + 1, 0 <= y < 10),
                    (x = y - 1, 0 <= x < 10))
