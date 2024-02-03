# membership.jl : SetBuilder Set Membership Checks

import Base.Iterators

# TODO: function compositon : setA -> setB -> setC ==> setA -> setC
# TODO: debug=true, on_notamember=(h->println(describe(h[1].set, mark=h[end].set)))
# TODO: rewriting set operations to CNF??

function _event(set, eventtype, event, hist, kwargs)

    if eventtype == :member

        if length(hist) == 0 || hist[1].set != set
            return event
        end

        (haskey(kwargs, :on_member) && event == true &&
            kwargs[:on_member](hist))

        (haskey(kwargs, :on_notamember) && event == false &&
            kwargs[:on_notamember](hist))

        if hasproperty(hist[1].set, :_meta)
            (haskey(hist[1].set._meta, :sb_on_member) && event == true &&
                set._meta[:sb_on_member](hist))

            (haskey(hist[end].set._meta, :sb_on_notamember) && event == false &&
                set._meta[:sb_on_notamember](hist))
        end
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

#function backward_map(set::MappedSet, coelems; hist=[], kwargs...)
#
#    doelems = []
#
#    # setvar names
#    if haskey(set._meta, :_domain_names_)
#        donames = set._meta[:_domain_names]
#    else
#        donames = [n[1] for n in set._domain]
#        set._meta[:_domain_names] = donames
#    end
#
#    if haskey(set._meta, :_codomain_names_)
#        conames = set._meta[:_codomain_names]
#    else
#        conames = [n[1] for n in set._codomain]
#        set._meta[:_codomain_names] = conames
#    end
#
#    for coelem in coelems
#
#        # check coelem in codomain
#        _check_member(coelem, set._codomain, hist, kwargs) || continue
#
#        # filter doelems
#        filtered_coelem = _filter_elem(coelem, set._forward_map[2], conames)
#
#        if length(filtered_coelem) == 0
#            push!(hist, (set = set, elem = coelem))
#            _event(set, :member, false, hist, kwargs)
#            continue
#        end
#        
#        # generate backward func
#        bfunc = sb_eval(set._backward_map[1], set._env)
#
#        # generate doelem from coelem using the backward func
#        try
#            if length(conames) > 1
#                gen_doelems = Base.invokelatest(bfunc, filtered_coelem[1]...)
#            else
#                gen_doelems = Base.invokelatest(bfunc, filtered_coelem[1])
#            end
#
#            # filter doelems
#            for e in _filter_elem(gen_doelems, set._backward_map[2], donames)
#                _check_member(e, set._domain, hist, kwargs) || continue
#                push!(doelems, e)
#            end
#        catch err
#            error("Invoking set expression, $(set._backward_map[1]), " *
#                  "is failed: $err")
#        end
#    end
#
#    return doelems
#end

function gen_doelems(c::Channel, elems, env, names)

    buf = []

    for name in names
        push!(buf, elems[name])
    end

    for elem in Iterators.product(buf...)

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

#    _domain::NTuple{N, Tuple{Symbol, SBSet}} where N
#    _forward_map::Dict{Symbol, NTuple{N, Any} where N}
#    _codomain_pred::NTuple{N, Union{Bool, Expr}} where N
#    _codomain::NTuple{N, Tuple{Symbol, SBSet}} where N
#    _backward_map::Dict{Symbol, NTuple{N, Any} where N}
#    _domain_pred::NTuple{N, Union{Bool, Expr}} where N
#    _env::Dict{Symbol, Any}
#    _meta::Dict{Symbol, Any}

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
        hist, kwargs)

    # check if a vector input
    is_vector = srcelems isa Vector

    if !is_vector
        srcelems = [srcelems]            
    end

    dstelems = []

    srcenv = deepcopy(set._env)
    _dstenv = deepcopy(set._env)

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
        _check_member(srcelem, srcdomain, hist, kwargs) || continue

        # check if elem passes pred
        if !_check_pred(srcelem, srcpred, srcenv, srcnames)
            push!(hist, (set = set, elem = srcelem))
            _event(set, :member, false, hist, kwargs)
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

            for (dstelem, dstenv) in my_channel
                _check_member(dstelem, dstdomain, hist, kwargs) || continue

                # check if elem passes pred
                if !_check_pred(dstelem, dstpred, dstenv, dstnames)
                    push!(hist, (set = set, elem = dstelem))
                    _event(set, :member, false, hist, kwargs)
                    continue
                end

                push!(dstelems, dstelem)
            end

        catch err
            error("Invoking set expression, $mapping, " *
                  "is failed: $err")
        end
    end

    if is_vector
        return dstelems

    elseif length(dstelems) == 0
        return nothing

    elseif length(dstelems) == 1
        return dstelems[1]

    else
        return dstelems
    end
end


function backward_map(set::MappedSet, coelems; hist=[], kwargs...)

    donames, conames = get_setnames(set)

    return do_mapping(
            set, coelems, set._backward_map,
            conames, set._codomain, set._codomain_pred,
            donames, set._domain, set._domain_pred,
            hist, kwargs)
end

function forward_map(set::MappedSet, doelems; hist=[], kwargs...)

    donames, conames = get_setnames(set)

    return do_mapping(
            set, doelems, set._forward_map,
            donames, set._domain, set._domain_pred,
            conames, set._codomain, set._codomain_pred,
            hist, kwargs)
end

#function backward_map(set::MappedSet, coelems; hist=[], kwargs...)
#
#    doelems = []
#
#    donames, conames = get_setnames(set)
#
#    # check if a vector input
#    is_vector = coelems isa Vector
#
#    if !is_vector
#        coelems = [coelems]            
#    end
#
#    coenv = deepcopy(set._env)
#    _doenv = deepcopy(set._env)
#
#    # generate domain element(s) per each codomain element
#    for coelem in coelems
#
#        if length(conames) == 1
#            coenv[conames[1]] = coelem isa Vector ? coelem[1] : coelem
#
#        else
#            for (n, e) in zip(conames, coelem)
#                coenv[n] = e
#            end
#        end
#
#        # check coelem in codomain
#        _check_member(coelem, set._codomain, hist, kwargs) || continue
#
#        # check if elem passes pred
#        if !_check_pred(coelem, set._codomain_pred, coenv, conames)
#            push!(hist, (set = set, elem = coelem))
#            _event(set, :member, false, hist, kwargs)
#            continue
#        end
#
#        # generate doelem from coelem using the backward func
#        try
#            _doelems = Dict{Symbol, Any}()
#
#            for (dvar, bconvs) in set._backward_map
#
#                if haskey(_doelems, dvar)
#                    _dvarelems = _doelems[dvar]
#                else
#                    _dvarelems = []
#                    _doelems[dvar] = _dvarelems 
#                end
#
#                for bconv in bconvs
#                    _elems = sb_eval(bconv, coenv)
#
#                    if _elems isa Vector
#                        append!(_dvarelems, _elems)
#
#                    else
#                        push!(_dvarelems, _elems)
#                    end
#                end
#            end
#
#            # filter doelems
#            my_channel = Channel( (c) -> gen_doelems(c, _doelems, _doenv, donames)) 
#
#            for (doelem, doenv) in my_channel
#                println("SSS ", doelem, doenv)
#                _check_member(doelem, set._domain, hist, kwargs) || continue
#
#                # check if elem passes pred
#                if !_check_pred(doelem, set._domain_pred, doenv, donames)
#                    push!(hist, (set = set, elem = doelem))
#                    _event(set, :member, false, hist, kwargs)
#                    continue
#                end
#
#                push!(doelems, doelem)
#            end
#
#        catch err
#            error("Invoking set expression, $(set._backward_map[1]), " *
#                  "is failed: $err")
#        end
#    end
#
#    if is_vector
#        return doelems
#
#    elseif length(doelems) == 0
#        return nothing
#
#    elseif length(doelems) == 1
#        return doelems[1]
#
#    else
#        return doelems
#    end
#end

#function forward_map(set::MappedSet, doelems; hist=[], kwargs...)
#
#    coelems = []
#
#    donames, conames = get_setnames(set)
#
#    is_vector = doelems isa Vector
#
#    if !is_vector
#        doelems = [doelems]
#    end
#
#    doenv = deepcopy(set._env)
#    _coenv = deepcopy(set._env)
#
#    for doelem in doelems
#
#        # first, check doelem in domain
#        _check_member(doelem, set._domain, hist, kwargs) || continue
#
#        if !_check_pred(doelem, set._domain_pred, doenv, donames)
#            push!(hist, (set = set, elem = doelem))
#            _event(set, :member, false, hist, kwargs)
#            continue
#        end
#
##33
#        # generate coelem from doelem using the forward func
#        try
#            _coelems = Dict{Symbol, Any}()
#
#            for (cvar, fconvs) in set._forward_map
#
#                if haskey(_coelems, cvar)
#                    _cvarelems = _coelems[cvar]
#                else
#                    _cvarelems = []
#                    _doelems[dvar] = _dvarelems 
#                end
#
#                for bconv in bconvs
#                    _elems = sb_eval(bconv, coenv)
#
#                    if _elems isa Vector
#                        append!(_dvarelems, _elems)
#
#                    else
#                        push!(_dvarelems, _elems)
#                    end
#                end
#            end
#
#            # filter doelems
#            my_channel = Channel( (c) -> gen_doelems(c, _doelems, _doenv, donames)) 
#
#            for (doelem, doenv) in my_channel
#                println("SSS ", doelem, doenv)
#                _check_member(doelem, set._domain, hist, kwargs) || continue
#
#                # check if elem passes pred
#                if !_check_pred(doelem, set._domain_pred, doenv, donames)
#                    push!(hist, (set = set, elem = doelem))
#                    _event(set, :member, false, hist, kwargs)
#                    continue
#                end
#
#                push!(doelems, doelem)
#            end
#
#        catch err
#            error("Invoking set expression, $(set._backward_map[1]), " *
#                  "is failed: $err")
#        end
#    end
####
#
#        # generate forward func
#        ffunc = sb_eval(set._forward_map[1], set._env)
#
#        # generate coelem2 from the generated doelem using forward func
#        try
#            # generate codomain elems
#            if length(donames) > 1
#                gen_coelems = Base.invokelatest(ffunc, filtered_doelem[1]...)
#            else
#                gen_coelems = Base.invokelatest(ffunc, filtered_doelem[1])
#            end
#
#            # filter codomain elems
#            for e in _filter_elem(gen_coelems, set._forward_map[2], conames)
#                _check_member(e, set._codomain, hist, kwargs) || continue
#                push!(coelems, e)
#            end
#        catch err
#            error("Invoking set expression, $(set._forward_map[1]), " *
#                  "is failed: $err")
#        end
#    end
#
#    if is_vector
#        return coelems
#
#    elseif length(coelems) == 0
#        return nothing
#
#    elseif length(coelems) == 1
#        return coelems[1]
#
#    else
#        return coelems
#
#    end
#end

"""
    is_member(set::EnumerableSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> A = @setbuild(Union{Int64, Float64}[1])
EnumerableSet([{Float64}*0, {Int64}*1])

julia> is_member(A, 1)
true

julia> is_member(A, Int32(1))
false

julia> push!(A, Float64(2.0))
EnumerableSet([{Float64}*1, {Int64}*1])

julia> is_member(A, Float64(2.0))
true

julia> pop!(A, Float64(2.0))
2.0

julia> is_member(A, Float64(2.0))
false
```
"""
function is_member(set::EnumerableSet, elem; kwargs...)

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

"""
    is_member(set::PredicateSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> A = @setbuild(x in I, 0 <= x < 10)
PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)

julia> is_member(A, 0)  # 0 in A 
true

julia> is_member(A, 10) # 10 in A
false
```
"""
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

"""
    is_member(set::MappedSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> struct MyStruct
       a
       b
       end

julia> S = @setbuild(MyStruct)
TypeSet(MyStruct)

julia> A = @setbuild(s in S, (x in I, y in I) -> mystruct(x,y), s -> (s.a, s.b),
                     mystruct=MyStruct)
MappedSet((x ∈ TypeSet(Integer)), (y ∈ TypeSet(Integer)) -> (s ∈ TypeSet(MyStruct)))

julia> is_member(A, MyStruct(1, 1))   # MyStruct(1, 1) in A
true

julia> is_member(A, MyStruct(1.0, 1)) # MyStruct(1.0, 1) in A
false
```
"""
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

"""
    is_member(set::CompositeSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> A = @setbuild(x in I, 0 <= x < 10)
PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10)

julia> B = @setbuild(x in I, 5 <= x < 15)
PredicateSet((x ∈ TypeSet(Integer)) where 5 <= x < 15)

julia> C = A ∩ B
CompositeSet(PredicateSet((x ∈ TypeSet(Integer)) where 0 <= x < 10) ∩ PredicateSet((x ∈ TypeSet(Integer)) where 5 <= x < 15))

julia> is_member(C, 5) # 5 in C
true

julia> is_member(C, 0) # 0 in C
false
```
"""
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

"""
    is_member(set::TypeSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> is_member(I, 1)   # 1 in I
true

julia> is_member(I, 0.1) # 0.1 in I
false
```
"""
function is_member(set::TypeSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, elem isa find_param(set), hist, kwargs)
end

"""
    is_member(set::UniversalSet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> U = @setbuild(Any)
UniversalSet()

julia> is_member(U, 1)   # 1 in U
true

julia> is_member(U, 0.1) # 0.1 in U
true
```
"""
function is_member(set::UniversalSet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, true, hist, kwargs)
end

"""
    is_member(set::EmptySet, elem; kwargs...)

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> E = @setbuild()
EmptySet()

julia> is_member(E, 1)   # 1 in E
false

julia> is_member(E, 0.1) # 0.1 in E
false
```
"""
function is_member(set::EmptySet, elem; kwargs...)

    hist = get(kwargs, :_imhist_, [])
    push!(hist, (set = set, elem = elem))

    return _event(set, :member, false, hist, kwargs)
end

"""
    elem in set -> Bool

Check if `elem` is a member of `set`

# Examples
```julia-repl
julia> I = @setbuild(Integer)
TypeSet(Integer)

julia> 1 in I   # is_member(I, 1)
true

julia> 0.1 in I # is_member(I, 0.1)
false
```
"""
Base.:in(e, set::SBSet)         = is_member(set, e)

Base.:in(e, set::EmptySet)      = false
Base.:in(e, set::UniversalSet)  = true
