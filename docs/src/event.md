# Set Event
SetBuilders provides users with the capability to register callback functions,
so they can be called when an event occurs during operation.

The situations in which an event occurs can vary. As of this writing,
membership events are supported.

## Membership events
Membership events occur during membership check using `ismember` functions.

Note that membership check operators of `in` or `∈` can not be used for event
handling.

### Creating a callback function
When an event occurs, SetBuilders makes a call to the registered callback
function with one argument that is a vector of named tuple(:set and :elem).

Let's start by creating a callback function.

```julia
function F1(history)
    desc = describe(history[1].set, mark=history[end].set)
    println("#############")
    println("Not a Member")
    println("-------------")
    println(desc)
    println("-------------")
    println(", because '$(history[end].elem)' is not a member of the set pointed by '=>'")
    println("#############")
end
```

The function `F1` takes one argument, `history`, which contains all the sets
visited during the membership check and the elements used in these sets.

The first item in the vector is the tuple of the set specified as the first
argument and the value as the second argument of the `ismember` function.

The last item in the vector is the tuple of the set and the element at the
time the event occurred.

To illustrate, we used the `describe` function with the `mark` keyword argument
to mark the last visited set where the event occurred. See
[Marking a set in description](@ref) for an explanation of how to use the
`mark` keyword argument in the `describe` function.

### Registering a callback function

Once a callback function is created, registering it to the `ismember`
function is straightforward.

```julia
I = @setbuild(Integer)
P1 = @setbuild(x in I, 0 <= x < 10)
M1 = @setbuild(x in P1, z in I, z = x + 5, x = z - 5)

ismember(0, M1, on_nomember=F1)
```
To register a callback function when a membership failure event occurs, we used
the `on_nomember` keyword argument. In the case of a membership success
event, `on_member` is used.

### Reading output from the callback function

The previous example produces:

```julia
#############
Not a Member
-------------

{ x ∈ A }
         /\ B-MAP
      || ||
F-MAP \/
{ z ∈ B }, where
 => A = { x ∈ A.A | 0 <= x < 10 }, where
        A.A = { x ∈ ::Integer }
    F-MAP: z = x + 5
    B-MAP: x = z - 5
    B = { x ∈ ::Integer }
-------------
, because '-5' is not a member of the set pointed by '=>'
#############
false
```
The output shows that the membership test failed at set `A`, originally named
`P1`, because the value `-5` is not a member of set `P1`.

The value `-5` was calculated using `B-MAP` from the original argument value of
`0` to `-5`, using the formula `x = z - 5`.
