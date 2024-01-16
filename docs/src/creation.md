
# Set Creation
This part demonstrates the "@setbuild" macro in SetBuilders for creating sets from Julia data types, predicates, and mappings. For example, "I = @setbuild(Integer)" creates a set of all Julia Integer type objects, and "A = @setbuild(x ∈ I, 0 < x < 4)" creates a set that implies to contain the integers 1, 2, and 3.
