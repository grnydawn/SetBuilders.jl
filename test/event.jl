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
@test  ismember(1, I, on_member=P1)

F2 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ ::Integer }""")
@test  !ismember(0.1, I, on_nomember=F2)

P3 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }""")
@test  ismember(1, PRED3, on_member=P3)

F4 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
 => A = { x ∈ ::Integer }""")
@test  !ismember(0.1, PRED3, on_nomember=F4)

C = PRED3 ∩ PRED4

P5 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
=> ∩
{ x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }""")
@test  ismember(5, C, on_member=P5)


F6 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
{ x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
∩
=> { x ∈ A | 5 <= x < 15 }, where
    A = { x ∈ ::Integer }""")
@test  !ismember(4, C, on_nomember=F6)

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

@test ismember(5, MAPD1, on_member=P7)

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

@test !ismember(4, MAPD1, on_nomember=F8)

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

@test !ismember(0.1, MAPD1, on_nomember=F9)

F10 = hist -> (@test describe(hist[1].set, mark=hist[end].set) == raw"""
=> { x ∈ ::Int64*3 }""")

ENUM_1 = @setbuild([1,2,3], sb_on_nomember=F10)

@test !ismember(0.1, ENUM_1)
