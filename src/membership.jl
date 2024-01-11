# membership.jl : SetBuilder Set Membership Checks


function _event(set::SBSet, check, data, kwargs)

    if haskey(kwargs, :sb_on_member) && check == true
        kwargs[:sb_on_member](data)

    elseif haskey(kwargs, :sb_on_notamember) && check == false
        kwargs[:sb_on_notamember](data)
    end

    if haskey(set._meta, :sb_on_member) && check == true
        set._meta[:sb_on_member](data)

    elseif haskey(set._meta, :sb_on_notamember) && check == false
        set._meta[:sb_on_notamember](data)
    end

    return check
end

function is_member(set::PartiallyEnumerableSet, elem; kwargs...)

    type_elem = typeof(elem)

    # NOTE: having SBSet as an element is not supported yet
    #       due to lack of the is_equal function of SBSets
    if haskey(set._elems, type_elem)
        return _event(set, elem in set._elems[type_elem], elem, kwargs)
    end

    return _event(set, false, elem, kwargs)
end

function is_member(set::PredicateSet, elem; kwargs...) :: Bool

    if length(set._vars) == 1
        elem in  set._vars[1][2] || return _event(set, false, elem, kwargs)

        if set._pred isa Bool
            return _event(set, set._pred, elem, kwargs)

        else
            varmap = Dict{Symbol, Any}(set._vars[1][1] => elem)
            return _event(set, sb_eval(set._pred, merge(varmap, set._env)),
                          elem, kwargs)
        end

    else
        length(set._vars) == length(elem) || return _event(set,
                                                        false, elem, kwargs)

        varmap = Dict{Symbol, Any}()

        for ((v, s), e) in zip(set._vars, elem)
            e in s || return _event(set, false, e, kwargs)

            if v isa Symbol
                varmap[v] = e
            end
        end

        if set._pred isa Bool
            return _event(set, set._pred, elem, kwargs)

        else
            return _event(set, sb_eval(set._pred, merge(varmap, set._env)),
                                        elem, kwargs)
        end
    end 

    return _event(set, false, elem, kwargs)
end

function is_member(set::MappedSet, coelem; kwargs...)

    function _filter_elems(elems, check, names)

        if !(elems isa Vector)
            elems = [elems]            
        end

        buf = []

        for elem in elems
            env = Dict{Symbol, Any}()

            if length(names) == 1
                env[names[1]] = elem

            else
                for (n, e) in zip(names, elem)
                    env[n] = e
                end
            end 

            if check isa Bool
                if check == true
                    push!(buf, elem)
                end
            elseif sb_eval(check, env)
                push!(buf, elem)
            end
        end

        return buf
    end

    function _check_member(e, d)
        if length(d) == 1
            return e in d[1][2]
        else
            for (_e, _d) in zip(e, d)
                _e in _d[2] || return false
            end
            return true
        end
    end

    # check coelem in codomain
    _check_member(coelem, set._codomain) || return _event(set, false, coelem,
                                                            kwargs)

    # codomain setvar names
    conames = [n[1] for n in set._codomain]

    # filter doelems
    coelems = _filter_elems(coelem, set._forward_map[2], conames)
    length(coelems) == 0 && return _event(set, false, coelem, kwargs)
    
    # generate backward func
    bfunc = sb_eval(set._backward_map[1], set._env)

    # generate doelem from coelem using the generated backward func
    _doelems = nothing
    try
        _doelems = Base.invokelatest(bfunc, coelems...)
    catch err
        error("Invoking set expression, $(set._backward_map[1]), " *
              "is failed: $err")
    end

    # domain setvar names
    donames = [n[1] for n in set._domain]

    # filter doelems
    doelems = _filter_elems(_doelems, set._backward_map[2], donames)

    # check doelems in domain
    for doelem in doelems

        # first, check doelem in domain
        _check_member(doelem, set._domain) || continue

        # generate forward func
        ffunc = sb_eval(set._forward_map[1], set._env)

        # generate coelem2 from the generated doelem using the generated
        # forward func
        _coelems2 = nothing
        try
            _coelems2 = Base.invokelatest(ffunc, doelem...)
        catch err
            error("Invoking set expression, $(set._forward_map[1]), " *
                  "is failed: $err")
        end

        # filter coelem2
        coelems2 = _filter_elems(_coelems2, set._forward_map[2], conames)

        for coelem2 in coelems2
            # check coelem == coelem2
            coelem == coelem2 && return _event(set, true, coelem, kwargs)
        end
    end

    return _event(set, false, coelem, kwargs)
end

function is_member(set::CompositeSet, elem; kwargs...)

    length(set._sets) == 0 && return false

    if set._op == :union
        return _event(set, any(s -> elem in s, set._sets), elem, kwargs)

    elseif set._op == :intersect
        return _event(set, all(s -> elem in s, set._sets), elem, kwargs)

    elseif set._op == :setdiff

        return _event(set, elem in set._sets[1] && all(s -> !(elem in s),
                                                        set._sets[2:end]),
                                                        elem, kwargs)

    elseif set._op == :symdiff

        work_set = set._sets[1]

        for s in set._sets[2:end]
            work_set = union((work_set - s), (s - work_set))
        end

        return _event(set, elem in work_set, elem, kwargs)
    end

    println("WARN: set operation, $(set._op), is not implemented yet.")

    return _event(set, false, elem, kwargs)
end

function is_member(set::TypeSet, elem; kwargs...)

    return _event(set, elem isa find_param(set), elem, kwargs)
    
end

Base.:in(e, set::SBSet)         = is_member(set, e)
Base.:in(e, set::EmptySet)      = false
Base.:in(e, set::UniversalSet)  = true
