# Set imports tests

@setimport("./testsets.sjl", x=1)

using SetBuilders.MySetModule

printelem = x -> println("$x is a member.")
printnoelem = x -> println("$x is not a member.")

@test  1 in IMPT1
@test !(-1 in IMPT1)
@test  is_member(IMPT1, 1, sb_on_member=printelem,
        sb_on_notamember=printnoelem)
@test  !(is_member(IMPT1, -1, sb_on_member=printelem,
        sb_on_notamember=printnoelem))
