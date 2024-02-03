# Set event and description tests

# pre-defined sets for testing
#I = @setbuild(Integer)
#PRED3 = @setbuild(x in I, 0 <= x < 10)
#PRED4 = @setbuild(x in I, 5 <= x < 15)
#MAPD1 = @setbuild(x in PRED3, z in I, z = x + 5, x = z - 5)

# event handler for debugging
#P = hist -> println("PASS\n"*describe(hist[1].set, mark=hist[end].set))
#F = hist -> println("FAIL\n"*describe(hist[1].set, mark=hist[end].set))

P1 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ ::Integer }""")
@test  is_member(I, 1, on_member=P1)

F2 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ ::Integer }""")
@test  !is_member(I, 0.1, on_notamember=F2)

P3 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }""")
@test  is_member(PRED3, 1, on_member=P3)

F4 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
 => A = { x ∈ ::Integer }""")
@test  !is_member(PRED3, 0.1, on_notamember=F4)

C = PRED3 ∩ PRED4

P5 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
=> ∩
{ x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }""")
@test  is_member(C, 5, on_member=P5)


F6 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
∩
=> { x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }""")
@test  !is_member(C, 4, on_notamember=F6)

P7 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> 
=> { x ∈ A }
=>          /\ B-MAP
=>       || ||
=> F-MAP \/
=> { z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
 => F-MAP: z = x + 5
 => B-MAP: x = z - 5
    B = { x ∈ ::Integer }""")

@test is_member(MAPD1, 5, on_member=P7)

F8 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
 => A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
    B = { x ∈ ::Integer }""")

@test !is_member(MAPD1, 4, on_notamember=F8)

F9 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
    A = { x ∈ A.A | 0 <= x < 10 }, where
     => A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
 => B = { x ∈ ::Integer }""")

@test !is_member(MAPD1, 0.1, on_notamember=F9)
