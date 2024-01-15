# macros.jl : SetBuilder Macro User Interface
#

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

function get_setvars(arg::Union{Symbol, Expr})

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
                                    error("Syntax error: $(string(mysvar)).")
                                end
                            else
                                error("Syntax error: $(string(mysvar)).")
                            end

                        elseif svar.args[1]::Symbol == :^
                            if svar.args[2] isa Symbol && svar.args[3] isa Integer
                                for _ in 1:svar.args[3]
                                    push!(setvars.args, Expr(:tuple, nothing,
                                                             esc(svar.args[2])))
                                end
                            else
                                error("Syntax error: $(svar.args).")
                            end
                        else
                            error("Syntax error: $arg.")
                        end
                    else
                        error("Syntax error: $arg.")
                    end
                else
                    error("Syntax error: $arg.")
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
                error("Syntax error: $arg.")
            end
        else
            error("Syntax error: $arg.")
        end
    else
        error("Syntax error: $arg.")
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
        error("PartiallyEnumerableSet requires to specify Julia type of " *
              "elements: $elems.")
    end

    return quote
        _sb_enum_type = find_param($elems)
        _sb_enum_elems= $(esc(elems))
        if isconcretetype(_sb_enum_type)
            PartiallyEnumerableSet(Dict(_sb_enum_type =>
                                        Set{_sb_enum_type}(_sb_enum_elems)),
                                   $meta)
        else
            error("PartiallyEnumerableSet requires concreate type, but got " *
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
                error("PartiallyEnumerableSet requires a concreate type, " *
                      "but got " * string(_t) * ".")
            end
        end

        _sb_enum_set = PartiallyEnumerableSet(Dict(_sb_type2set), $meta)

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

function proc_build_twoargs(part1, part2, env, meta)

    setvars = get_setvars(part1)

    if part2 isa Expr && part2.head == :(->)
        error("Syntax error: a mapping is provided at the place for " *
              "a predicate at $part2")
    end

    pred    = QuoteNode(part2)

    return :(SetBuilders.PredicateSet($setvars, $pred, $env, $meta))
end

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

macro setbuild(args...)

    args, env, meta = split_args(args)

    NARGS = length(args)

    if NARGS == 0
        return :(SetBuilders.EmptySet())

    elseif NARGS == 1
        return proc_build_onearg(args[1], env, meta)

    elseif NARGS == 2
        return proc_build_twoargs(args[1], args[2], env, meta)

    else
        return proc_build_args(args, env, meta)
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

macro setpkg(args...)

    args, env, meta = split_args(args)

    if length(args) == 0
        return print_pkg_help()

    else
        return proc_pkg_command(args[1], args[2:end], env, meta)
    end
end
