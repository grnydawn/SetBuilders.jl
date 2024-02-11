# Set mapping tests

# pre-defined sets for testing
#PRED3 = @setbuild(x in I, 0 <= x < 10)
#PRED4 = @setbuild(x in I, 5 <= x < 15)
#PRED5 = @setbuild((x in PRED3, y in PRED4), x < 5 && y > 10)
#S = @setbuild(MyStruct)

# Mapped sets
#MAPD1 = @setbuild(x in PRED3, z in I, z = x + 5, x = z - 5)
@test fmap(MAPD1, [0, 9]) == [5, 14]
@test !(fmap(MAPD1, [-1, 9]) == [4, 14])
@test bmap(MAPD1, [5, 14]) == [0, 9]
@test !(bmap(MAPD1, [4, 14]) == [-1, 9])

P1 = events -> (@test length(events) == 0) 
@test fmap(MAPD1, [0, 9], on_mapping=P1) == [5, 14]

F1 = events -> (@test (length(events) == 1 &&
                       events[1].event == :source_membership_fail))
@test !(fmap(MAPD1, [-1, 9], on_nomapping=F1) == [4, 14])

#MAPD2 = @setbuild(x in PRED4, z in I, z = x + 5, x = func(z), func=myfunc)
@test fmap(MAPD2, [5, 14]) == [10, 19]
@test !(fmap(MAPD2, [4, 14]) == [9, 19])
@test bmap(MAPD2, [10, 19]) == [5, 14]
@test !(bmap(MAPD2, [9, 14]) == [4, 14])

#MAPD3 = @setbuild((x in PRED3, y in PRED4), z in S,  z = mystruct(x, y),
#                (x, y) = (z.a, z.b), mystruct=MyStruct)
@test fmap(MAPD3, [(0, 5)]) == [MyStruct(0, 5)]
@test bmap(MAPD3, [MyStruct(0, 5)]) == [(0, 5)]

#MAPD4 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
#                (x, y) = (z.a, z.b), mystruct=MyStruct)
@test fmap(MAPD4, [(0, 9)]) == [MyStruct(0, 9)]
@test !(fmap(MAPD4, [(0, 10)]) == [MyStruct(0, 10)])
@test bmap(MAPD4, [MyStruct(0, 9)]) == [(0, 9)]
@test !(bmap(MAPD4, [MyStruct(0, 10)]) == [(0, 10)])

#MAPD5 = @setbuild(x in PRED5, z in S, z = mystruct(x[1], x[2]),
#                x = [(z.a, z.b), (z.a, z.b)], mystruct=MyStruct)
#@test fmap(MAPD5, [((4, 14), (4, 14))]) == [MyStruct(4, 14)]
@test fmap(MAPD5, (4, 14)) == MyStruct(4, 14)
@test bmap(MAPD5, MyStruct(4, 14)) == [(4, 14), (4, 14)]

#MAPD6 = @setbuild((x, y) in PRED3, z in S, z = mystruct(x, y),
#                (x, y) = [(z.a, z.b), (z.b, z.a)], mystruct=MyStruct)
@test fmap(MAPD6, [(0, 9)]) == [MyStruct(0, 9)]
# TODO: fix the following issue
@test bmap(MAPD6, MyStruct(0, 9)) == [(0, 9), (9, 0)]

#MAPD7 = @setbuild(x in I, y in I, (y = x + 1, 0 <= y < 10),
#                    (x = y - 1, 0 <= x < 10))
@test fmap(MAPD7, [5, 6]) == [6, 7]
@test bmap(MAPD7, [6, 7]) == [5, 6]

MAPD_X1 = @setbuild(x in I, z in I, z = x + 5, x = z - 5)
@test bmap(MAPD_X1, 6) == 1
@test fmap(MAPD_X1, 1) == 6
MAPD_X2 = @setbuild(x in I, z in I, (z = [x + 5, x + 4], z > 3), x = z - 5)
@test bmap(MAPD_X2, 6) == 1
@test fmap(MAPD_X2, 1) == [6, 5]
