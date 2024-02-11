# membership.jl : SetBuilder Set Membership Checks

# TODO: function compositon : setA -> setB -> setC ==> setA -> setC
# TODO: debug=true, on_nomember=(h->println(describe(h[1].set, mark=h[end].set)))
# TODO: rewriting set operations to CNF??

function _init_sb_kw()
    return Dict{Symbol, Any}(:set_history=>[], :map_events=>[])
end

function _event(set, eventtype, event, sb_kw; kwargs...)

    if eventtype == :member
        hist = sb_kw[:set_history]

        (haskey(kwargs, :on_member) && event == true &&
         kwargs[:on_member] isa Function && kwargs[:on_member](hist))

        (haskey(kwargs, :on_nomember) && event == false &&
         kwargs[:on_nomember] isa Function && kwargs[:on_nomember](hist))

        (hasfield(typeof(set), :_meta) && haskey(set._meta, :sb_on_member) &&
         event == true && set._meta[:sb_on_member] isa Function &&
         set._meta[:sb_on_member](hist))

        (hasfield(typeof(set), :_meta) && haskey(set._meta, :sb_on_nomember) &&
         event == false && set._meta[:sb_on_nomember] isa Function &&
         set._meta[:sb_on_nomember](hist))

    elseif eventtype == :mapping
        events = sb_kw[:map_events]

        (haskey(kwargs, :on_mapping) && event == true &&
         kwargs[:on_mapping] isa Function && kwargs[:on_mapping](events))

        (haskey(kwargs, :on_nomapping) && event == false &&
         kwargs[:on_nomapping] isa Function && kwargs[:on_nomapping](events))

        (hasfield(typeof(set), :_meta) && haskey(set._meta, :sb_on_mapping) &&
         event == true && set._meta[:on_mapping] isa Function &&
         set._meta[:sb_on_mapping](events))

        (hasfield(typeof(set), :_meta) && haskey(set._meta, :sb_on_nomapping) &&
         event == false && set._meta[:on_nomapping] isa Function &&
         set._meta[:sb_on_nomapping](events))

    else
        error("Unknown event type: $eventtype.")
    end

    return event
end

function _check_pred(elem, checks, env, names)

    all_passed = true

    for check in checks
        if check isa Bool
            if check == false
                all_passed = false
                break
            end
        elseif !sb_eval(check, env)
            all_passed = false
            break
        end
    end

    return all_passed
end

function _check_member(elem, setpart, sb_kw; kwargs...)

    if length(setpart) == 1
        return ismember(elem, setpart[1][2], sb_kw; kwargs...)
    else
        for (e, sp) in zip(elem, setpart)
            ismember(e, sp[2], sb_kw; kwargs...) || return false
        end
        return true
    end
end

function gen_doelems(c::Channel, elems, env, names)

    buf = []

    for name in names
        push!(buf, elems[name])
    end

    for elem in zip(buf...)

        if length(names) == 1
            env[names[1]] = elem[1]
            put!(c, (elem[1], env))

        else
            for (n, e) in zip(names, elem)
                env[n] = e
            end
            put!(c, (elem, env))
        end

    end
end

function get_setnames(set)

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

    return donames, conames
end

function do_mapping(
        set::MappedSet, srcelems, mapping,
        srcnames, srcdomain, srcpred,
        dstnames, dstdomain, dstpred,
        sb_kw; on_mapping=nothing, on_nomapping=nothing,
        on_member=nothing, on_nomember=nothing)

    # check if a vector input
    is_vector = srcelems isa Vector

    if !is_vector
        srcelems = [srcelems]            
    end

    dstelems = []

    srcenv = deepcopy(set._env)
    _dstenv = deepcopy(set._env)

    events = sb_kw[:map_events]

    # generate dst element(s) per each src element
    for srcelem in srcelems

        if length(srcnames) == 1
            srcenv[srcnames[1]] = srcelem isa Vector ? srcelem[1] : srcelem

        else
            for (n, e) in zip(srcnames, srcelem)
                srcenv[n] = e
            end
        end

        # check srcelem in src domain
        if !_check_member(srcelem, srcdomain, sb_kw, on_member=on_member,
                         on_nomember=on_nomember)
            push!(events, (event=:source_membership_fail, element=srcelem,
                           settuple=srcdomain))
            _event(set, :mapping, false, sb_kw, on_nomapping=on_nomapping)
            push!(dstelems, nothing)
            continue
        end

        # check if elem passes pred
        if !_check_pred(srcelem, srcpred, srcenv, srcnames)
            push!(events, (event=:source_predicate_fail, element=srcelem,
                           predicate=srcpred))
            _event(set, :mapping, false, sb_kw, on_nomapping=on_nomapping)
            push!(dstelems, nothing)
            continue
        end

        # generate dst elem from srcelem using the srcmap
        try
            _dstelems = Dict{Symbol, Any}()

            for (svar, convs) in mapping
                if haskey(_dstelems, svar)
                    _dvarelems = _dstelems[svar]
                else
                    _dvarelems = []
                    _dstelems[svar] = _dvarelems 
                end

                for conv in convs
                    _elems = sb_eval(conv, srcenv)

                    if _elems isa Vector
                        append!(_dvarelems, _elems)

                    else
                        push!(_dvarelems, _elems)
                    end
                end
            end

            # filter doelems
            my_channel = Channel( (c) -> gen_doelems(c, _dstelems, _dstenv, dstnames)) 

            elembuf = []

            for (dstelem, dstenv) in my_channel
                # check dstelem in target domain
                if !_check_member(dstelem, dstdomain, sb_kw, on_member=on_member,
                                 on_nomember=on_nomember)
                    push!(events, (event=:target_membership_fail, element=dstelem,
                                   settuple=dstdomain))
                    continue
                end

                # check if elem passes pred
                if !_check_pred(dstelem, dstpred, dstenv, dstnames)
                    push!(events, (event=:target_predicate_fail, element=dstelem,
                                   predicate=dstpred))
                    continue
                end

                push!(elembuf, dstelem)
            end


            if length(elembuf) > 0
                append!(dstelems, elembuf)

            else
                _event(set, :mapping, false, sb_kw, on_nomapping=on_nomapping)
                push!(dstelems, nothing)
            end

        catch err
            error("Invoking set expression, $mapping, " *
                  "is failed: $err")
        end
    end

    if is_vector
        (length(dstelems) > 0 && all(e->!(e isa Nothing), dstelems) &&
            _event(set, :mapping, true, sb_kw, on_mapping=on_mapping))
        return dstelems

    elseif length(dstelems) == 0
        return nothing

    elseif length(dstelems) == 1
       (!(dstelems[1] isa Nothing) && _event(set, :mapping, true, sb_kw,
                                              on_mapping=on_mapping))
        return dstelems[1]

    else
        (length(dstelems) > 0 && all(e->!(e isa Nothing), dstelems) &&
            _event(set, :mapping, true, sb_kw, on_mapping=on_mapping))
        return dstelems
    end
end

"""
    bmap(set::MappedSet, elems; on_mapping::Function, on_nomapping::Function,
            on_member::Function, on_nomember::Function)

convert `elems` in the argument to element(s) in domain of a MappedSet.

# Keywords
* **on_mapping**: A callback function that will be called when a mapping is successful.
* **on_nomapping**: A callback function that will be called when a mapping is not successful.
* **on_member**: A callback function that will be called when a membership check is successful.
* **on_nomember**: A callback function that will be called when a membership check is not successful.
"""
function bmap(set::MappedSet, coelems, sb_kw=nothing; on_mapping=nothing,
        on_nomapping=nothing, on_member=nothing, on_nomember=nothing)

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    donames, conames = get_setnames(set)

    return do_mapping(
            set, coelems, set._backward_map,
            conames, set._codomain, set._codomain_pred,
            donames, set._domain, set._domain_pred,
            sb_kw, on_mapping=on_mapping, on_nomapping=on_nomapping,
            on_member=on_member, on_nomember=on_nomember)
end

"""
    fmap(set::MappedSet, elems; on_mapping::Function, on_nomapping::Function,
            on_member::Function, on_nomember::Function)

convert `elems` in the argument to element(s) in codomain of a MappedSet.

# Keywords
* **on_mapping**: A callback function that will be called when a mapping is successful.
* **on_nomapping**: A callback function that will be called when a mapping is not successful.
* **on_member**: A callback function that will be called when a membership check is successful.
* **on_nomember**: A callback function that will be called when a membership check is not successful.
"""
function fmap(set::MappedSet, doelems, sb_kw=nothing; on_mapping=nothing,
        on_nomapping=nothing, on_member=nothing, on_nomember=nothing)

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    donames, conames = get_setnames(set)

    return do_mapping(
            set, doelems, set._forward_map,
            donames, set._domain, set._domain_pred,
            conames, set._codomain, set._codomain_pred,
            sb_kw, on_mapping=on_mapping, on_nomapping=on_nomapping,
            on_member=on_member, on_nomember=on_nomember)
end

function ismember(elem, set::EnumerableSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing) :: Bool

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    type_elem = typeof(elem)

    # NOTE: having SBSet as an element is not supported yet
    #       due to lack of the is_equal function of SBSets
    if haskey(set._elems, type_elem)
        return _event(set, :member, elem in set._elems[type_elem], sb_kw,
                      on_member=on_member, on_nomember=on_nomember)
    else
        return _event(set, :member, false, sb_kw, on_nomember=on_nomember)
    end

end

function ismember(elem, set::PredicateSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing) :: Bool

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    if length(set._vars) == 1
        res = ismember(elem, set._vars[1][2], sb_kw)

        (res == false && return _event(set, :member, res, sb_kw,
                                       on_nomember=on_nomember))

        push!(sb_kw[:set_history], (set = set, elem = elem))

        if set._pred isa Bool
            return _event(set, :member, set._pred, sb_kw, on_member=on_member,
                         on_nomember=on_nomember)

        elseif set._pred isa Nothing
            return _event(set, :member, true, sb_kw, on_member=on_member)

        else
            varmap = Dict{Symbol, Any}(set._vars[1][1] => elem)
            return _event(set, :member,
                          sb_eval(set._pred, merge(varmap, set._env)), sb_kw,
                          on_member=on_member, on_nomember=on_nomember)
        end

    else
        if length(set._vars) != length(elem)
            return _event(set, :member, false, sb_kw, on_nomember=on_nomember)
        end

        varmap = Dict{Symbol, Any}()

        for ((v, s), e) in zip(set._vars, elem)
            res = ismember(e, s, sb_kw)
            res == false && return _event(set, :member, res, sb_kw,
                                          on_nomember=on_nomember)
            
            if v isa Symbol
                varmap[v] = e
            end
        end

        push!(sb_kw[:set_history], (set = set, elem = elem))

        if set._pred isa Bool
            return _event(set, :member, set._pred, sb_kw, on_member=on_member,
                         on_nomember=on_nomember)

        elseif set._pred isa Nothing
            return _event(set, :member, true, sb_kw, on_member=on_member)

        else
            return _event(set, :member, sb_eval(set._pred,
                            merge(varmap, set._env)), sb_kw,
                          on_member=on_member, on_nomember=on_nomember)
        end
    end 

    error("This line should not be excuted.")
    return false
end

function ismember(coelem, set::MappedSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing) :: Bool

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = coelem))

    doelems = bmap(set, [coelem], sb_kw)

    #doelems = bmap(set, [coelem], sb_kw, on_member=on_member,
    #               on_nomember=on_nomember)

    if length(doelems) == 0
        return _event(set, :member, false, sb_kw, on_nomember=on_nomember)
    else
        # per every generated elem in domain
        for doelem in doelems
            doelem isa Nothing && continue

            # generate elem in co-domain
            coelems2 = fmap(set, [doelem], sb_kw)

            # check if generate elem in co-domain equals to
            # the original elem in codomain
            for coelem2 in coelems2
                if coelem == coelem2
                    push!(sb_kw[:set_history], (set = set, elem = coelem))
                    return _event(set, :member, true, sb_kw, on_member=on_member)
                end
            end
        end

    end

    return false
end

function ismember(elem, set::CompositeSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing) :: Bool

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    length(set._sets) == 0 && return _event(set, :member, false, sb_kw,
                                           on_nomember=on_nomember)

    res = false

    if set._op == :union
        res = any(s -> ismember(elem, s, sb_kw), set._sets)
        res == false && push!(sb_kw[:set_history], (set = set, elem = elem))

    elseif set._op == :intersect
        _res = any(s -> !ismember(elem, s, sb_kw), set._sets)
        res = !_res
        res == true && push!(sb_kw[:set_history], (set = set, elem = elem))

    elseif set._op == :setdiff
        _res = (!ismember(elem, set._sets[1], sb_kw) ||
                any(s -> ismember(elem, s, sb_kw), set._sets[2:end]))
        res = !_res
        push!(sb_kw[:set_history], (set = set, elem = elem))

    elseif set._op == :symdiff
        work_set = set._sets[1]

        for s in set._sets[2:end]
            work_set = union((work_set - s), (s - work_set))
        end

        res = ismember(elem, work_set, sb_kw)
        push!(sb_kw[:set_history], (set = set, elem = elem))

    else
        println("WARN: set operation, $(set._op), is not implemented yet.")
    end

    return _event(set, :member, res, sb_kw, on_member=on_member,
                  on_nomember=on_nomember)
end

function ismember(elem, set::TypeSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing)

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    return _event(set, :member, elem isa find_param(set), sb_kw,
        on_member=on_member, on_nomember=on_nomember)
end

function ismember(elem, set::UniversalSet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing)

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    on_member isa Function && on_member(sb_kw[:set_history])

    return true
end

function ismember(elem, set::EmptySet, sb_kw=nothing; on_member=nothing,
        on_nomember=nothing)

    sb_kw = sb_kw isa Nothing ? _init_sb_kw() : sb_kw
    push!(sb_kw[:set_history], (set = set, elem = elem))

    on_nomember isa Function && on_nomember(sb_kw[:set_history])

    return false
end

Base.:in(e, set::SBSet)         = ismember(e, set)
Base.:in(e, set::EmptySet)      = false
Base.:in(e, set::UniversalSet)  = true

"""
    ismember(elem, set <: SBSet; on_member::Function, on_nomember::Function)

returns `true` if `elem` is a member of `set`.
Otherwise returns false.

# Keywords

## `on_member`
A callback function registered with `on_member` 
will be called when `elem` is known to be a member of `set`.

## `on_nomember`
A callback function registered with `on_nomember` 
will be called when `elem` is known not to be a member of `set`.

```julia
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> P = @setbuild(x in I, 0 <= x < 10)
PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)

julia> F = h -> println(describe(h[1].set, mark=h[end].set))
#7 (generic function with 1 method)

julia> ismember(-1, P, on_nomember=F)
=> { x ∈ A | 0 <= x < 10 }, where
    A = { x ∈ ::Integer }
false
```
"""
ismember(elem, set::SBSet; kwargs...) = false
