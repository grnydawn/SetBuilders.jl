# Set mapping tests

# pre-defined sets for testing
#PRED3 = @setbuild(x in I, 0 <= x < 10)
#PRED4 = @setbuild(x in I, 5 <= x < 15)
#PRED5 = @setbuild((x in PRED3, y in PRED4), x < 5 && y > 10)
#S = @setbuild(MyStruct)

# Mapped sets
#MAPD1 = @setbuild(z in I, (x in PRED3) -> x + 5, z -> z - 5)
@test forward_map(MAPD1, [0, 9]) == [5, 14]
@test !(forward_map(MAPD1, [-1, 9]) == [4, 14])
@test backward_map(MAPD1, [5, 14]) == [0, 9]
@test !(backward_map(MAPD1, [4, 14]) == [-1, 9])

#MAPD2 = @setbuild(z in I, (x in PRED4) -> x + 5, z -> func(z), func=myfunc)
@test forward_map(MAPD2, [5, 14]) == [10, 19]
@test !(forward_map(MAPD2, [4, 14]) == [9, 19])
@test backward_map(MAPD2, [10, 19]) == [5, 14]
@test !(backward_map(MAPD2, [9, 14]) == [4, 14])

#MAPD3 = @setbuild(z in S, (x in PRED3, y in PRED4) -> mystruct(x, y),
#                z -> (z.a, z.b), mystruct=MyStruct)
@test forward_map(MAPD3, [(0, 5)]) == [MyStruct(0, 5)]
@test backward_map(MAPD3, [MyStruct(0, 5)]) == [(0, 5)]

#MAPD4 = @setbuild(z in S, ((x, y) in PRED3) -> mystruct(x, y),
#                z -> (z.a, z.b), mystruct=MyStruct)
@test forward_map(MAPD4, [(0, 9)]) == [MyStruct(0, 9)]
@test !(forward_map(MAPD4, [(0, 10)]) == [MyStruct(0, 10)])
@test backward_map(MAPD4, [MyStruct(0, 9)]) == [(0, 9)]
@test !(backward_map(MAPD4, [MyStruct(0, 10)]) == [(0, 10)])

#MAPD5 = @setbuild(z in S, ((x, y) in PRED5) -> mystruct(x[1], y[2]),
#                z -> ((z.a, z.b), (z.a, z.b)), mystruct=MyStruct)
@test forward_map(MAPD5, [((4, 14), (4, 14))]) == [MyStruct(4, 14)]
@test backward_map(MAPD5, [MyStruct(4, 14)]) == [((4, 14), (4, 14))]

#MAPD6 = @setbuild(z in S, ((x, y) in PRED3) -> mystruct(x, y),
#                z -> [(z.a, z.b), (z.b, z.a)], mystruct=MyStruct)
@test forward_map(MAPD6, [(0, 9)]) == [MyStruct(0, 9)]
@test backward_map(MAPD6, [MyStruct(0, 9)]) == [(0, 9), (9, 0)]

#MAPD7 = @setbuild(x in I, (y in I) -> y + 1, x -> x - 1,
#                0 <= x < 10, 0 <= y < 10)
@test forward_map(MAPD7, [5, 6]) == [6, 7]
@test backward_map(MAPD7, [6, 7]) == [5, 6]
