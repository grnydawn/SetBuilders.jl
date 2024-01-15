# membership.jl : SetBuilder Set Membership Checks

# TODO: function compositon : setA -> setB -> setC ==> setA -> setC
# TODO: debug=true, on_notamember=(h->println(describe(h[1].set, mark=h[end].set)))
# TODO: rewriting set operations to CNF??

function _event(set, eventtype, event, hist, kwargs)

    if eventtype == :member
        if length(hist) == 0 || hist[1].set != set
            return event
        end

        if haskey(kwargs, :on_member) && event == true
            kwargs[:on_member](hist)

        elseif haskey(kwargs, :on_notamember) && event == false
            kwargs[:on_notamember](hist)
        end

        if haskey(hist[1].set._meta, :sb_on_member) && event == true
            set._meta[:sb_on_member](hist)

        elseif haskey(hist[end].set._meta, :sb_on_notamember) && event == false
            set._meta[:sb_on_notamember](hist)
        end
    else
        error("Unknown event type: $eventtype.")
    end

    return event
end

function _filter_elem(elems, check, names)

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

function _check_member(e, d, h, kwargs)
    if length(d) == 1

        if haskey(kwargs, :_imhist_)
            return is_member(d[1][2], e; kwargs...)
        else
            return is_member(d[1][2], e; _imhist_=h, kwargs...)
        end
    else
        for (_e, _d) in zip(e, d)
            if haskey(kwargs, :_imhist_)
                is_member(_d[2], _e; kwargs...) || return false
            else
                (is_member(_d[2], _e; _imhist_=h, kwargs...) ||
                    return false)
            end
        end
        return true
    end
end

function backward_map(set::MappedSet, coelems; hist=[], kwargs...)

    doelems = []

    # setvar names
    if haskey(set._meta, :_domain_names_)
        donames = set._meta[:_domain_names]
    else
        donames = [n[1] for n in set._domain]
        set._meta[:_domain_names] = donames
    end

    if haskey(set._meta, :_codomain_names_)
        conames = set._meta[:_codomain_names]
    else
        conames = [n[1] for n in set._codomain]
        set._meta[:_codomain_names] = conames
    end

    for coelem in coelems

        # check coelem in codomain
        _check_member(coelem, set._codomain, hist, kwargs) || continue

        # filter doelems
        filtered_coelem = _filter_elem(coelem, set._forward_map[2], conames)

        if length(filtered_coelem) == 0
            push!(hist, (set = set, elem = coelem))
            _event(set, :member, false, hist, kwargs)
            continue
        end
        
        # generate backward func
        bfunc = sb_eval(set._backward_map[1], set._env)

        # generate doelem from coelem using the backward func
        try
            if length(conames) > 1
                gen_doelems = Base.invokelatest(bfunc, filtered_coelem[1]...)
            else
                gen_doelems = Base.invokelatest(bfunc, filtered_coelem[1])
            end

            # filter doelems
            for e in _filter_elem(gen_doelems, set._backward_map[2], donames)
                _check_member(e, set._domain, hist, kwargs) || continue
                push!(doelems, e)
            end
        catch err
            error("Invoking set expression, $(set._backward_map[1]), " *
                  "is failed: $err")
        end
    end

    return doelems
end

function forward_map(set::MappedSet, doelems; hist=[], kwargs...)

    coelems = []

    # setvar names
    if haskey(set._meta, :_domain_names_)
        donames = set._meta[:_domain_names]
    else
        donames = [n[1] for n in set._domain]
        set._meta[:_domain_names] = donames
    end

    if haskey(set._meta, :_codomain_names_)
        conames = set._meta[:_codomain_names]
    else
        conames = [n[1] for n in set._codomain]
        set._meta[:_codomain_names] = conames
    end

    for doelem in doelems

        # first, check doelem in domain
        _check_member(doelem, set._domain, hist, kwargs) || continue

        filtered_doelem = _filter_elem(doelem, set._backward_map[2], donames)

        if length(filtered_doelem) == 0
            push!(hist, (set = set, elem = doelem))
            _event(set, :member, false, hist, kwargs)
            continue
        end

        # generate forward func
        ffunc = sb_eval(set._forward_map[1], set._env)

        # generate coelem2 from the generated doelem using forward func
        try
            # generate codomain elems
            if length(donames) > 1
                gen_coelems = Base.invokelatest(ffunc, filtered_doelem[1]...)
            else
                gen_coelems = Base.invokelatest(ffunc, filtered_doelem[1])
            end

            # filter codomain elems
            for e in _filter_elem(gen_coelems, set._forward_map[2], conames)
                _check_member(e, set._codomain, hist, kwargs) || continue
                push!(coelems, e)
            end
        catch err
            error("Invoking set expression, $(set._forward_map[1]), " *
                  "is failed: $err")
        end
    end

    return coelems
end

function is_member(set::PartiallyEnumerableSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    type_elem = typeof(elem)

    # NOTE: having SBSet as an element is not supported yet
    #       due to lack of the is_equal function of SBSets
    if haskey(set._elems, type_elem)
        return _event(set, :member, elem in set._elems[type_elem], hist, kwargs)
    else
        return _event(set, :member, false, hist, kwargs)
    end

end

function is_member(set::PredicateSet, elem; kwargs...) :: Bool

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    if length(set._vars) == 1

        if haskey(kwargs, :_imhist_)
            res = is_member(set._vars[1][2], elem; kwargs...)
        else
            res = is_member(set._vars[1][2], elem; _imhist_=hist, kwargs...)
        end

        res == false && return _event(set, :member, res, hist, kwargs)

        if set._pred isa Bool
            push!(hist, (set = set, elem = elem))
            return _event(set, :member, set._pred, hist, kwargs)

        else
            varmap = Dict{Symbol, Any}(set._vars[1][1] => elem)
            push!(hist, (set = set, elem = elem))
            return _event(set, :member, sb_eval(set._pred,
                                merge(varmap, set._env)), hist, kwargs)
        end

    else
        if length(set._vars) != length(elem)
            push!(hist, (set = set, elem = elem))
            return _event(set, :member, false, hist, kwargs)
        end

        varmap = Dict{Symbol, Any}()

        for ((v, s), e) in zip(set._vars, elem)

            if haskey(kwargs, :_imhist_)
                res = is_member(s, e; kwargs...)
            else
                res = is_member(s, e; _imhist_=hist, kwargs...)
            end

            res == false && return _event(set, :member, res, hist, kwargs)
            
            if v isa Symbol
                varmap[v] = e
            end
        end

        push!(hist, (set = set, elem = elem))

        if set._pred isa Bool
            return _event(set, :member, set._pred, hist, kwargs)

        else
            return _event(set, :member, sb_eval(set._pred,
                            merge(varmap, set._env)), hist, kwargs)
        end
    end 

    push!(hist, (set = set, elem = elem))
    return _event(set, :member, false, hist, kwargs)
end

function is_member(set::MappedSet, coelem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = coelem))

    doelems = backward_map(set, [coelem]; hist=hist, kwargs...)

    if length(doelems) == 0
        return _event(set, :member, false, hist, kwargs)
    end

    # per every generated elem in domain
    for doelem in doelems

        # generate elem in co-domain
        coelems2 = forward_map(set, [doelem]; hist=hist, kwargs...)

        # check if generate elem in co-domain equals to
        # the original elem in codomain
        for coelem2 in coelems2
            if coelem == coelem2
                push!(hist, (set = set, elem = coelem))
                return _event(set, :member, true, hist, kwargs)
            end
        end
    end

    push!(hist, (set = set, elem = coelem))
    return _event(set, :member, false, hist, kwargs)
end

function is_member(set::CompositeSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    length(set._sets) == 0 && return _event(set, :member, false, hist, kwargs)

    res = false

    if set._op == :union
        if haskey(kwargs, :_imhist_)
            res = any(s -> is_member(s, elem; kwargs...), set._sets)
        else
            res = any(s -> is_member(s, elem; _imhist_=hist,
                        kwargs...), set._sets)
        end

        res == false && push!(hist, (set = set, elem = elem))

    elseif set._op == :intersect
        if haskey(kwargs, :_imhist_)
            _res = any(s -> !is_member(s, elem; kwargs...), set._sets)
        else
            _res = any(s -> !is_member(s, elem; _imhist_=hist,
                        kwargs...), set._sets)
        end
        res = !_res

        res == true && push!(hist, (set = set, elem = elem))

    elseif set._op == :setdiff

        if haskey(kwargs, :_imhist_)
            _res = (!is_member(set._sets[1], elem; kwargs...) ||
                any(s -> is_member(s, elem; kwargs...), set._sets[2:end]))
        else
            _res = (!is_member(set._sets[1], elem; _imhist_=hist, kwargs...) ||
                    any(s -> is_member(s, elem; _imhist_=hist,
                                        kwargs...), set._sets[2:end]))
        end

        res = !_res
        push!(hist, (set = set, elem = elem))

    elseif set._op == :symdiff

        work_set = set._sets[1]

        for s in set._sets[2:end]
            work_set = union((work_set - s), (s - work_set))
        end

        if haskey(kwargs, :_imhist_)
            res = is_member(work_set, elem; kwargs...)
        else
            res = is_member(work_set, elem; _imhist_=hist, kwargs...)
        end

        push!(hist, (set = set, elem = elem))

    else
        println("WARN: set operation, $(set._op), is not implemented yet.")
    end

    return _event(set, :member, res, hist, kwargs)

end

function is_member(set::TypeSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, elem isa find_param(set), hist, kwargs)
end

function is_member(set::UniversalSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, true, hist, kwargs)
end

function is_member(set::EmptySet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, false, hist, kwargs)
end

Base.:in(e, set::SBSet)         = is_member(set, e)
Base.:in(e, set::EmptySet)      = false
Base.:in(e, set::UniversalSet)  = true
