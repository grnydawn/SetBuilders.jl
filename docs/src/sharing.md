# Set Sharing
As we describe more complex situations by combining various sets, we may find
ourselves creating numerous sets together. Alternatively, we might need to
use a set that was developed by another programmer. To facilitate these
scenarios, SetBuilders enables the definition of sets outside the current
execution environment, such as from an external file.

## Loading Set Module

At the time of this writing, SetBuilders offers functionality to load sets
from a Julia module, which could be housed in a file.

```julia
path = "path/to/set/module"
@setpkg load path
```

The `@setpkg` macro, when used with the "load" sub-command, loads a Julia
module from the specified file. This file should be a regular Julia module
that exports sets.

```julia
module MySetModule
export MySet

MySet = @setbuild(Integer)
end
```
To use the exported set, you can use `@setpkg load` command as shown below:

```julia
@setpkg load "path/to/set/module"
using SetBuilders.MySetModule

@assert 1 in MySet
```
To reduce the chance of naming pollution, the set module is imported beneath
the SetBuilders module. Apart from this, it can be treated as a regular Julia
module.

The SetBuilders set module is an extension of the Julia module. The `@expect`
macro requires users of the set module to provide "expected" values, while the
`@option` macro defines optional information. These extensions assist the set
developer in creating sets independently from the set users.

```julia
module MySetModule

export MySet

@expect(x::Integer)
@option(y::Integer)

I       = @setbuild(Integer)
MySet   = @setbuild(z in I, z + x > 0, x=x)

end
```
The expected value `x` can be provided as demonstrated below.

```julia

@setpkg load "path/to/set/module" x=1
```
