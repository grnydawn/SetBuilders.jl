# macros.jl : SetBuilder Macro User Interface
#

# SetVarException
struct SetVarException <: Exception
    msg::String
end
SetVarException() = SetVarException("A setvar error occurred")

function get_kwargs(args) :: Tuple{Expr, Expr}

    kwargs  = :(Dict{Symbol, Any}())

    for arg in args
        if arg isa Expr && arg.head == :(=)
                push!(kwargs.args, :($(QuoteNode(arg.args[1])) =>
                                   $(esc(arg.args[2]))))
        else
            error("Syntax error: $arg.")
        end
    end

    return kwargs
end


function get_envmeta(kwargs) :: Tuple{Expr, Expr}

    env  = :(Dict{Symbol, Any}())
    meta = :(Dict{Symbol, Any}())

    for kwarg in kwargs
        if kwarg isa Expr && kwarg.head == :(=)
            if startswith(string(kwarg.args[1]), "sb_")
                push!(meta.args, :($(QuoteNode(kwarg.args[1])) =>
                                   $(esc(kwarg.args[2]))))
            else
                push!(env.args, :($(QuoteNode(kwarg.args[1])) =>
                                  $(esc(kwarg.args[2]))))
            end
        else
            error("Syntax error: $kwarg.")
        end
    end

    return env, meta
end

function get_setvars(arg::Union{Symbol, Bool, Expr})

    setvars = Expr(:tuple)

    if arg isa Symbol
        push!(setvars.args, Expr(:tuple, nothing, esc(arg)))

    elseif arg isa Expr
        if arg.head == :tuple
            for svar in arg.args
                if svar isa Symbol
                    push!(setvars.args, Expr(:tuple, nothing, esc(svar)))

                elseif svar isa Expr
                    if svar.head::Symbol == :call
                        if svar.args[1]::Symbol == :in
                            mysvar = svar.args[2]
                            if mysvar isa Symbol
                                push!(setvars.args, Expr(:tuple,
                                                         QuoteNode(mysvar),
                                                         esc(svar.args[3])))
                            elseif mysvar isa Expr
                                if mysvar.head::Symbol == :tuple
                                    for ssvar in mysvar.args
                                        push!(setvars.args, Expr(:tuple,
                                                                 QuoteNode(ssvar),
                                                                 esc(svar.args[3])))
                                    end
                                else
                                    throw(SetVarException(
                                    "Setvar syntax error: $(string(mysvar))."))
                                end
                            else
                                throw(SetVarException(
                                    "Setvar syntax error: $(string(mysvar))."))
                            end

                        elseif svar.args[1]::Symbol == :^
                            if svar.args[2] isa Symbol && svar.args[3] isa Integer
                                for _ in 1:svar.args[3]
                                    push!(setvars.args, Expr(:tuple, nothing,
                                                             esc(svar.args[2])))
                                end
                            else
                                throw(SetVarException(
                                    "Setvar syntax error: $(svar.args)."))
                            end
                        else
                            throw(SetVarException(
                                    "Setvar syntax error: $arg."))
                        end
                    else
                        throw(SetVarException(
                                    "Setvar syntax error: $arg."))
                    end
                else
                    throw(SetVarException(
                                    "Setvar syntax error: $arg."))
                end

            end
        elseif (arg.head::Symbol == :call && (arg.args[1]::Symbol == :in ||
                                              arg.args[1]::Symbol == :∈))
            if arg.args[2] isa Symbol
                push!(setvars.args, Expr(:tuple, QuoteNode(arg.args[2]),
                                         esc(arg.args[3])))

            elseif arg.args[2] isa Expr && arg.args[2].head::Symbol == :tuple
                for svar in arg.args[2].args
                    push!(setvars.args, Expr(:tuple, QuoteNode(svar),
                                             esc(arg.args[3])))
                end
            else
                throw(SetVarException( "Syntax throw(SetVarException: $arg."))
            end
        else
            throw(SetVarException("Syntax throw(SetVarException: $arg."))
        end
    else
        throw(SetVarException("Syntax throw(SetVarException: $arg."))
    end

    return setvars
end

function get_forward_mapping(arg::Expr)
    if arg.head == :(->)
        setvars = get_setvars(arg.args[1])
        names   = Expr(:tuple, (v.args[1].value for v in setvars.args)...)
        arg.args[1] = names

        if arg.args[2].args[1] isa LineNumberNode
            deleteat!(arg.args[2].args, 1)
        end

        return setvars, QuoteNode(arg)
    else
        error("Syntax error: $arg.")
    end
end

function create_cartesianset(setvars::Expr, env, meta) ::Expr

    if setvars.head == :tuple
        idx = 1

        for setvar in setvars.args
            if setvar.args[1] isa Nothing
                setvar.args[1] = QuoteNode(Symbol("c$idx"))
                idx += 1
            end
        end

        return :(SetBuilders.PredicateSet($setvars, true, $env, $meta))
    else
        error("Syntax error: $setvars.")
    end
end

function create_enumset(elems::Expr, meta) ::Expr

    if length(elems.args) == 0
        error("EnumerableSet requires to specify Julia type of " *
              "elements: $elems.")
    end

    return quote
        _sb_enum_type = find_param($elems)
        _sb_enum_elems= $(esc(elems))
        if isconcretetype(_sb_enum_type)
            EnumerableSet(Dict(_sb_enum_type =>
                                        Set{_sb_enum_type}(_sb_enum_elems)),
                                   $meta)
        else
            error("EnumerableSet requires concreate type, but got " *
                  string(_sb_enum_type) * ".")
        end
    end
end

function create_enumset(type::Union{Symbol, Expr}, elems::Vector{Any}, meta) ::Expr

    types = Expr(:tuple)

    if type isa Symbol
        push!(types.args, type)

    elseif type.head == :curly
        if type.args[1] == :Union
            append!(types.args, type.args[2:end])

        else
            push!(types.args, type)
        end
    else
        error("Syntax error: $type.")
    end

    return quote
        _sb_type2set = []

        for _t in $types
            if isconcretetype(_t)
                push!(_sb_type2set, _t => Set{_t}())
            else
                error("EnumerableSet requires a concreate type, " *
                      "but got " * string(_t) * ".")
            end
        end

        _sb_enum_set = EnumerableSet(Dict(_sb_type2set), $meta)

        for e in $elems
            push!(_sb_enum_set, Base.eval(Main, e))
        end
        _sb_enum_set
    end

end

function proc_build_onearg(arg, env, meta)

    if arg isa Symbol
        if arg == :Any
            return :(SetBuilders.UniversalSet())

        else
            arg = esc(arg)
            return quote
                if $arg isa SBSet
                    error("Syntax error: re-building SBSet is not allowed.")

                elseif $arg isa DataType || $arg isa UnionAll
                    SetBuilders.TypeSet{$arg}($meta)

                else
                    error("Incorrect type: " * string($arg))
                end
            end
        end

    elseif arg isa Expr

        if arg.head == :vect
            return create_enumset(arg, meta)

        elseif arg.head == :tuple
            return create_cartesianset(get_setvars(arg), env, meta)

        elseif arg.head == :ref
            return create_enumset(arg.args[1], arg.args[2:end], meta)

        elseif arg.head == :curly
            return :(SetBuilders.TypeSet{$arg}($meta))

        elseif arg.head::Symbol == :call && arg.args[1]::Symbol == :in
            return create_cartesianset(get_setvars(arg), env, meta)

        else
            error("Syntax error: $arg.")
        end
    else
        error("Syntax error: $arg.")
    end
end

#function proc_build_twoargs(part1, part2, env, meta)
#
#    setvars = get_setvars(part1)
#
#    if part2 isa Expr && part2.head == :(->)
#        error("Syntax error: a mapping is provided at the place for " *
#              "a predicate at $part2")
#    end
#
#    pred    = QuoteNode(part2)
#
#    return :(SetBuilders.PredicateSet($setvars, $pred, $env, $meta))
#end

function proc_build_args(args, env, meta)

    codomain    = get_setvars(args[1])
    domain, fmap= get_forward_mapping(args[2])

    if args[3].args[2].args[1] isa LineNumberNode
        deleteat!(args[3].args[2].args, 1)
    end
    bmap        = QuoteNode(args[3])

    NARGS = length(args)

    if NARGS == 3
        fpres, bpres = QuoteNode(:true), QuoteNode(:true)

    elseif NARGS == 4
        fpres, bpres = QuoteNode(args[4]), QuoteNode(:true)

    elseif NARGS == 5
        fpres, bpres = QuoteNode(args[4]), QuoteNode(args[5])

    else
        error("Syntax error: too many arguments: $NARGS, " * string(args))
    end

    forward_map = Expr(:tuple, fmap, fpres)
    backward_map = Expr(:tuple, bmap, bpres)

    return :(SetBuilders.MappedSet($domain, $forward_map, $backward_map,
                                        $codomain, $env, $meta))
end

function split_args2(args)

    kwargs  = ()

    # split args to (setargs, setkwargs)
    for (idx, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(=)
            kwargs  = args[idx:end]
            args    = args[1:(idx-1)]
            break
        end
    end

    return args, kwargs
end

function split_kwargs(args)

    env  = :(Dict{Symbol, Any}())
    meta = :(Dict{Symbol, Any}())

    # split args to (setargs, setkwargs)
    for (idx, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(=)
            env, meta = get_envmeta(args[idx:end])
            break
        end
    end

    return env, meta
end

function split_args(args)

    env  = :(Dict{Symbol, Any}())
    meta = :(Dict{Symbol, Any}())

    # split args to (setargs, setkwargs)
    for (idx, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(=)
            env, meta = get_envmeta(args[idx:end])
            args    = args[1:(idx-1)]
            break
        end
    end

    return args, env, meta
end

# _forward_map::Tuple{Dict{Symbol, Tuple}, Tuple{Union{Bool, Expr}}} where N
#    _forward_map::Dict{Symbol, NTuple{N, Any} where N}
#    _forward_pred::NTuple{N, Union{Bool, Expr}} where N

function get_mapping(arg, domain)

    _map = Dict()
    _pred = :(())

    for setvar in domain.args
        _map[setvar.args[1].value] = []
    end
    
    if arg isa Expr
        if arg.head == :(=)
            if arg.args[1] isa Symbol
                setvar = arg.args[1]

                if haskey(_map, setvar)
                    push!(_map[setvar], arg.args[2])
                else
                    error("Set variable, $setvar is not in $(keys(_map)).")
                end
            elseif arg.args[1] isa Expr && arg.args[1].head == :tuple
                if  arg.args[2] isa Expr
                    if arg.args[2].head == :tuple
                        for (setvar, ex) in zip(arg.args[1].args, arg.args[2].args)
                            push!(_map[setvar], ex)
                        end
                    elseif arg.args[2].head == :vect
                        for exprs in arg.args[2].args
                            if exprs.head == :tuple
                                for (setvar, ex) in zip(arg.args[1].args, exprs.args)
                                    push!(_map[setvar], ex)
                                end
                            else
                                error("Unsupported mapping syntax: $exprs")
                            end
                        end
                    else
                        dump(arg)
                        error("Unsupported mapping syntax: $(arg.args[2])")
                    end
                else
                    error("Unsupported mapping syntax: $(arg.args[2])")
                end
            else
                error("Unsupported mapping syntax: $arg")
            end
        elseif arg.head == :tuple
            for ex in arg.args
                if ex.head == :(=)
                    if ex.args[1] isa Symbol
                        setvar = ex.args[1]

                        if haskey(_map, setvar)
                            if ex.args[2].head == :vect
                                append!(_map[setvar], ex.args[2].args)
                            else
                                push!(_map[setvar], ex.args[2])
                            end
                        else
                            error("Set variable, $setvar is not in $(keys(_map)).")
                        end
                    else
                        error("Unsupported mapping syntax: $arg")
                    end
                else
                    push!(_pred.args, QuoteNode(ex))
                end
            end
        else
            dump(arg)
            error("Unsupported mapping syntax: $arg")
        end
    else
        error("Unsupported mapping syntax: $arg")
    end

    pairs = Expr(:tuple)
    for (svar, ex) in _map
        push!(pairs.args, Expr(:call, :(=>), QuoteNode(svar), QuoteNode(Tuple(ex))))
    end

    mapping = :(Dict{Symbol, NTuple{N, Any} where N}($pairs))
    pred = _pred

    return mapping, pred
end


"""
    @setbuild([args...[; kwargs...]])

The `@setbuild` macro creates various SetBuilders sets.

The `@setbuild` macro in SetBuilders for creating sets
from Julia data types, predicates, and mappings.
For example, `I = @setbuild(Integer)` creates a set of
all Julia Integer type objects, and
`A = @setbuild(x ∈ I, 0 < x < 4)` creates a set that
implies to contain the integers 1, 2, and 3.

# Examples

```julia-repl
julia> E = @setbuild()
EmptySet()

julia> U = @setbuild(Any)
UniversalSet()

julia> I = @setbuild(Integer) # Julia Integer-type set
TypeSet(Integer)

julia> D = @setbuild(Dict{String, Number}) # Julia Dict{String, Number}-type set
TypeSet(Dict{String, Number})

julia> struct MyStruct
           a
           b
       end

julia> S = @setbuild(MyStruct)  # Julia user-type set
TypeSet(MyStruct)

julia> N = @setbuild([1, 2, 3]) # Enumerable set
EnumerableSet([{Int64}*3])

julia> C = @setbuild((I, I))  # Cartesian sets
PredicateSet((c1 ∈ TypeSet(Integer)), (c2 ∈ TypeSet(Integer)) where true)

julia> P = @setbuild(x in I, 0 <= x < 10) # Predicate sets
PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)

julia> M = @setbuild(z in I, (x in P) -> x + 5, z -> z - 5) # Mapped sets
MappedSet((x ∈ PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)) -> (z ∈ TypeSet(Integer)))
```
"""
macro setbuild(args...)

    args, kwargs = split_args2(args)

    NARGS = length(args)

    if NARGS == 0
        return :(SetBuilders.EmptySet())

    elseif NARGS == 1
        env, meta   = split_kwargs(kwargs)
        return proc_build_onearg(args[1], env, meta)

    else
        
        try
            # MappedSet
            codomain        = get_setvars(args[2])
            domain          = get_setvars(args[1])

            if length(args) == 2
                fmap, codomain_pred = get_mapping(kwargs[1], codomain)
                bmap, domain_pred   = get_mapping(kwargs[2], domain)
                env, meta   = split_kwargs(kwargs[3:end])

            elseif length(args) == 3
                fmap, codomain_pred = get_mapping(args[3], codomain)
                bmap, domain_pred   = get_mapping(kwargs[1], domain)
                env, meta   = split_kwargs(kwargs[2:end])

            elseif length(args) == 4
                fmap, codomain_pred = get_mapping(args[3], codomain)
                bmap, domain_pred   = get_mapping(args[4], domain)
                env, meta   = split_kwargs(kwargs)

            else
                error("Syntax error: $args")
            end
 
            return :(SetBuilders.MappedSet($domain, $fmap, $codomain_pred,
                            $codomain, $bmap, $domain_pred, $env, $meta))

        catch exc
            if exc isa SetVarException
                if NARGS == 2

                    setvars     = get_setvars(args[1])
                    env, meta   = split_kwargs(kwargs)
                    pred        = QuoteNode(args[2])

                    return :(SetBuilders.PredicateSet($setvars, $pred,
                                                        $env, $meta))
                else
                    error("Wrong syntax: $(args)")
                    #return proc_build_args(args, env, meta)
                end

            else
                rethrow()
            end
        end
    end
end

function print_pkg_help()
    println("T.B.D.")
end

function proc_pkg_load(args, env, meta)

    if length(args) == 0
        error("No path is specified for loading a set definition package.")
    end    

    target = args[1]

    if !(target isa String)
        target = esc(target)
    end

    return :(load_pkg($target, $env, $meta))
end

function proc_pkg_command(arg, args, env, meta) :: Expr

    if arg isa Symbol
        if arg == :load
            return proc_pkg_load(args, env, meta)

        else
            error("@setpkg command, $arg, is not supported.")
        end

    else
        error("@setpkg command is not a symbol type: $arg.")
    end
end

"""
    @setpkg command[ command-arguments... ]

The @setpkg macro enables the reuse of sets that were developed separately.

# commands

## load: loads sets from a local file, also known as a setfile

    @setpkg load <path/to/file>

The setfile is a regular Julia module customized for SetBuilders.

# Examples
Assuming that the file `myset.sjl` contains the following Julia code:

```julia
module MySetModule

export MYSET

I = @setbuild(Integer)
MYSET = @setbuild(x in I, x > 0)

end
```

`MYSET` can be used as shown in the example below:

```julia-repl
julia> @setpkg load "myset.sjl"

julia> using SetBuilders.MySetModule

julia> 1 in MYSET
true

julia> 0 in MYSET
false
```
"""
macro setpkg(args...)

    args, env, meta = split_args(args)

    if length(args) == 0
        return print_pkg_help()

    else
        return proc_pkg_command(args[1], args[2:end], env, meta)
    end
end
