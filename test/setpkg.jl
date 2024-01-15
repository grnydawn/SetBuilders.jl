# Set imports tests

@setpkg load "./testsets.sjl" x=1

using SetBuilders.MySetModule

@test  1 in IMPT1
@test !(-1 in IMPT1)
