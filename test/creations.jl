# Tests for set creation syntax
# prepare an integer set for testing

I = SB_SET_INT

x = 1
#mytest()

# helper struct for testing
struct MyStruct
    a
    b
end

# helper functions for testing
function myfunc(x)
    x - 5
end

A = @setfilter(x in I, 0 <= x < 10)

B = @setfilter(x in I, 5 <= x < 15)

C = setfromtype(Complex)

D = @setfilter((x in A, y in B), x < 5 && y > 10)

E = @setfilter((x in A, y in B), c1*x + c2*y > 0, c1=-1, c2=1)

F = @setconvert(z in I, x -> x + 5, z -> z - 5, x in A)

G = @setconvert(z in I, x -> x + 5, z -> func(z), x in A, func=myfunc)

H = setfromtype(MyStruct)

J = @setconvert(z in H, (x, y) -> MyStruct(x, y), z -> (z.a, z.b),
                x in A, y in B, MyStruct=MyStruct)

K = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
                x in A, y in B, mystruct=MyStruct)

L = @setconvert(z in H, (x, y) -> mystruct(x[1], y[2]), z -> ((z.a, z.b), (z.a, z.b)),
                x in D, y in D, mystruct=MyStruct)

M = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> [(z.a, z.b), (z.b, z.a)],
                (x, y) in A, mystruct=MyStruct)

N = @setconvert(z in H, (x, y) -> mystruct(x, y), z -> (z.a, z.b),
                (x, y) in A, mystruct=MyStruct)

O = @setfilter(x in A, true)

P = @setfilter(x in A, false)

Q = setfromtype(Rational)

R = setfromtype(Real)

S = setfromtype(Dict{String, Number})

T = setfromtype(Vector{Int64})

U = setfromtype(Array{Float64, 2})

V = @setenum(1)

W = @setenum([x,2], type=Int64)

X = @setenum([Int32(-1), Int32(1),2], type=(Int64, Int32))

Y = @setenum(type=Union{Int64, Int32})

Z = I

for name in names(Main)
    obj = getfield(Main, name)

    if obj isa SBSet
        @test obj isa SBSet
    end
end
