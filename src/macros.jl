# macro user interface

using MacroTools: prewalk, postwalk, @capture, isexpr, unblock, rmlines

# TODO: supports { x in X | x < 0 where arg=value} syntax

"""
A filtered set builder

    I = SB_SET_INT

    A = @setfilter((x in I, y in I), x > 0 && y > 0)

    is similar to the mathematical set notation of 

    A = {x ∈ I, y ∈ I | x > 0 and y > 0}

    @assert (1, 1) in A
    @assert !((0, 0) in A)

    , where I is the integer set. SB_SET_INT is a pre-defined set
    in SetBuilders.jl package for all Julia integer data types
    such as Int64 and Int32.
"""
macro setfilter(var_part, pred, metadata_part...)

    pred = prewalk(rmlines, pred)

    # convert to tuples of (variable, set)
    vars = postwalk(x -> @capture(x, v_ in S_) ?
             Expr(:tuple, :($(QuoteNode(v))), esc(S)) :
             x::Union{Symbol, Expr}, var_part::Union{Symbol, Expr}) :: Expr

    # normalize variable syntax
    if !isexpr(vars, Expr, :tuple) || length(vars.args) < 1
        error("Variable syntax error: $vars.")

    elseif !isexpr(vars.args[1], Expr, :tuple)
        vars = Expr(:tuple, vars)

    end

    # create a dictionary for set metadata and environment
    metadata = :(Dict{Symbol, Any}())
    env = :(Dict{Symbol, Any}())

    for ex in metadata_part

        if ex.head != :(=) || length(ex.args) != 2
            error("The syntax of set metadata is not correct: $ex.")
        end

        if startswith(string(ex.args[1]), "sb_")
            push!(metadata.args, :($(QuoteNode(ex.args[1])) => $(esc(ex.args[2]))))
        else
            push!(env.args, :($(QuoteNode(ex.args[1])) => $(esc(ex.args[2]))))
        end
    end

    if pred == true
        sym_true = Expr(:quote, true)
        return :(FilteredSet($vars, $(QuoteNode(sym_true)), $metadata, $env))

    elseif pred == false
        return esc(:(SetBuilders.SB_SET_EMPTY))
    else
        return :(FilteredSet($vars, $(QuoteNode(pred)), $metadata, $env))
    end

end


"""
A set converter from a set to another

    struct MyStruct
        a
    end

    I = SB_SET_INT
    S = setfromtype(MyStruct)

    A = @setconvert(y in S, x -> mystruct(x), y -> y.a, x in I,
                    mystruct=MyStruct)

    is similar to the mathematical set notation of 

    A = {y ∈ S | y = MyStruct(x) and x = y.a where x ∈ I}

    @assert MyStruct(1) in A
    @assert !(MyStruct(1.0) in A)

    , and where I is the integer set and S is the set of all possible
    MyStruct objects. SB_SET_INT is a pre-defined set in SetBuilders.jl
    package for all Julia integer data types such as Int64 and Int32.
"""
macro setconvert(var_part, forward_map, backward_map, metadata_part...)

    forward_map = prewalk(rmlines, forward_map)
    backward_map = prewalk(rmlines, backward_map)

    # check codomain syntax
    if !isexpr(var_part, Expr, :call) || var_part.args[1] != :(in)
        error("Variable syntax error: $var_part.")
    end

    # collect codomain
    codomain = Expr(:tuple)
    #push!(codomain.args, :(Symbol($(QuoteNode(var_part.args[2])))))
    push!(codomain.args, :($(QuoteNode(var_part.args[2]))))
    push!(codomain.args, esc(var_part.args[3]))

    # check forward_map syntax
    if !isexpr(forward_map, Expr, :(->))
        error("The syntax of forward mapping is not correct: $forward_map.")
    end

    # check backward_map syntax
    if !isexpr(backward_map, Expr, :(->))
        error("The syntax of backward mapping is not correct: $backward_map.")
    end

    # collect domain and metadata
    metadata = :(Dict{Symbol, Any}())
    domain_vars = Dict{Symbol, Expr}()

    env = :(Dict{Symbol, Any}($(QuoteNode(codomain.args[2].args[1])) =>
            $(codomain.args[2])))

    for ex in metadata_part

        if ex.head == :(=) 

            if startswith(string(ex.args[1]), "sb_")
                push!(metadata.args, :($(QuoteNode(ex.args[1])) => $(esc(ex.args[2]))))
            else
                push!(env.args, :($(QuoteNode(ex.args[1])) => $(esc(ex.args[2]))))
            end

        elseif ex.head == :call && ex.args[1] == :(in)

            if ex.args[2] isa Symbol
                domain_vars[ex.args[2]] = esc(ex.args[3])

            elseif isexpr(ex.args[2], :tuple)
                for dvar in ex.args[2].args
                    domain_vars[dvar] = esc(ex.args[3])
                end
            else
                error("The syntax of set domain/metadata is not correct: $ex.")
            end
        else
            error("The syntax of set domain/metadata is not correct: $ex.")
        end
    end

    domain = Expr(:tuple)

    if forward_map.args[1] isa Symbol
        push!(domain.args, Expr(:tuple,
            :($(QuoteNode(forward_map.args[1]))),
            domain_vars[forward_map.args[1]]))

    elseif forward_map.args[1].head == :tuple
        for dvar in forward_map.args[1].args
            push!(domain.args, Expr(:tuple,
            :($(QuoteNode(dvar))),
            domain_vars[dvar]))
        end
    else 
        error("The syntax of forward mapping is not correct: $forward_map.")
    end

    backward = Expr(:tuple)
    push!(backward.args, :($(QuoteNode(backward_map.args[1]))))
    push!(backward.args, :($(QuoteNode(backward_map))))

    return :(ConvertedSet($domain, $(QuoteNode(forward_map)), $backward, $codomain, $metadata, $env))
end

"""
A enumerated set builder


    A = @setenum([1, 2, 3])

    is similar to the mathematical set notation of 

    A = {1, 2, 3}

    @assert 1 in A
    @assert !(0 in A)

    This EnumSet wraps Julia Set objects.
"""
macro setenum(args...)

    function _kwparse(arg, types)
        if arg.args[1] == :type
            if arg.args[2] isa Expr
                if arg.args[2].head in (:tuple, :vect)
                    for t in arg.args[2].args
                        push!(types.args, t)
                    end
                elseif arg.args[2].head == :curly && arg.args[2].args[1] == :Union
                    for t in arg.args[2].args[2:end]
                        push!(types.args, t)
                    end
                else
                    error("EnumSet syntax error: unknown keyword argument, $arg")
                end
            else
                push!(types.args, arg.args[2])
            end
        else
            error("EnumSet syntax error: unknown keyword argument, $arg")
        end
    end

    elems           = Expr(:tuple)
    elem_types      = Expr(:tuple)
    keyword_types   = Expr(:tuple)
    esargs          = Expr(:tuple)

    for (idx, arg) in enumerate(args)

        if idx == 1
            if arg isa Symbol

            elseif arg isa Expr
                if arg.head in (:tuple, :vect)
                    for e in arg.args
                        push!(elem_types.args, :(typeof($e)))
                        push!(elems.args, e)
                    end
                elseif arg.head == :(=)
                    _kwparse(arg, keyword_types)
                else
                    error("Not supported yet: $arg.head")
                end

            else
                push!(elem_types.args, typeof(arg))
                push!(elems.args, arg)

            end
        elseif arg.head == :(=)
            _kwparse(arg, keyword_types)

        else
            error("EnumSet syntax error: $args")
        end
    end

    if length(keyword_types.args) == 0
        if length(elem_types.args) == 0
            error("EnumSet requires at least one concrete type.")
        else
            keyword_types = elem_types
        end
    end

    for t in keyword_types.args
        push!(esargs.args, :($t => Set{$t}()))
    end

    elems = esc(elems)

    ex = quote
        for t in $keyword_types
            if !isconcretetype(t)
                error("EnumSet requires concreate type, but got " * string(t) * ".")
            end
        end

        _sb_enum_set = EnumSet(Dict($esargs))
        for e in $elems
            push!(_sb_enum_set, e)
        end
        _sb_enum_set
    end

    return ex
end
