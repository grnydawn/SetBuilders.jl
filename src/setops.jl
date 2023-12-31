# set operations

function is_varmember(var, set)

    if !(var in set)
        sb_log("Variable, $var, is not a member of $set")
        return false
    end

    return true
end

function hold_predicate(pred, env::Dict{Symbol, Any})

    ret = sb_eval(pred, env)

    if !ret
        sb_log("Predicate, $pred, does not hold for " *
                join(["$key = $value" for (key, value) in env], ", "))
    end

    return ret
end

function is_member(set::FilteredSet, elem)

    sb_log("enter 'is_member' for $set, with an object, $elem.")

    if length(set._vars) == 1
        is_varmember(elem, set._vars[1][2]) || return false

        varmap = Dict{Symbol, Any}(set._vars[1][1] => elem)
        hold_predicate(set._pred, merge(varmap, set._env)) || return false

        return true

    else

        if length(set._vars) != length(elem)
            sb_log("The number of set variables($(length(set._vars)))"
                * "mismatches with the number of elements($(length(elem))).")
            return false
        end

        varmap = Dict{Symbol, Any}()

        for ((v, s), e) in zip(set._vars, elem)
            is_varmember(e, s) || return false
            varmap[v] = e
        end

        hold_predicate(set._pred, merge(varmap, set._env)) || return false

        return true
    end 
end

function check_correspondence(set, ref_codomain_elem, domain_elem)

    domain_check = true
    inverse_check = true
    
    for ((dvarname, domain_set), delem) in zip(set._domain, domain_elem)
        if !(delem in domain_set)
            sb_log("$delem is not a member of $domain_set.")
            domain_check = false
            break
        end
    end 

    forward_func = sb_eval(set._forward_map, set._env)
    codomain_elem = Base.invokelatest(forward_func, domain_elem...)

    if codomain_elem != ref_codomain_elem
        sb_log("Mappings are not invertible each other: " *
                "$codomain_elem != $ref_codomain_elem.")
        return (domain_check, false)
    end

    return (domain_check, true)
end

function is_member(set::ConvertedSet, elem) ::Bool

    sb_log("enter 'is_member' for $set, with an object, $elem.")

    if !(elem in set._codomain[2])
        sb_log("$elem is not a member of codomain, $(set._codomain[2]).")
        return false
    end

    backward_func = sb_eval(set._backward_map[2], set._env)
    domain_elem = Base.invokelatest(backward_func, elem)

    if domain_elem isa Vector
        for d_elem in domain_elem
            if d_elem isa Tuple
                d_check, i_check = check_correspondence(set, elem, d_elem)
            else
                d_check, i_check = check_correspondence(set, elem, (d_elem,))
            end

            if d_check == true && i_check == true
                return true
            end
        end

        return false

    elseif domain_elem isa Tuple
        d_check, i_check = check_correspondence(set, elem, domain_elem)

    else
        d_check, i_check = check_correspondence(set, elem, (domain_elem,))
    end

    if d_check == true && i_check == true
        return true
    end

    return false
end

function is_member(set::TypeSet, elem)

    ret = elem isa findparam(set)

    if !ret
        sb_log("The type of elem, $elem, does not match to $set.")
    end

    return ret
end

function is_member(set::CompositeSet, elem)

    len_sets = length(set._sets)

    if len_sets == 0
        return false
    end

    if set._op == :union
        return any(s -> elem in s, set._sets)

    elseif set._op == :intersect
        return all(s -> elem in s, set._sets)

    elseif set._op == :setdiff

        return elem in set._sets[1] && all(s -> !(elem in s), set._sets[2:end])

    elseif set._op == :symdiff

        work_set = set._sets[1]

        for s in set._sets[2:end]
            work_set = union((work_set - s), (s - work_set))
        end

        return elem in work_set
    end

    sb_log("Set operation, $(set._op), is not implemented yet.")

    return false
end


function is_member(set::EnumSet, elem)

    sb_log("enter 'is_member' for $set, with an object, $elem.")

    type_elem = typeof(elem)

    if haskey(set._elems, type_elem)
        return elem in set._elems[type_elem]

    else
        return false
    end
end

function do_setop(setop::Symbol, sets::NTuple{N, SBSet} where N) :: SBSet

    if length(sets) == 0
        error("No set is provided for the set opration, $setop.")
    end

    _sets = Vector{SBSet}()

    for (idx, set) in enumerate(sets)
        if set isa UniversalSet
            if setop == :union
                return SB_SET_UNIVERSAL

            elseif setop == :intersect

            elseif setop == :setdiff
                idx == 1 ? push!(_sets, set) : return SB_SET_EMPTY

            elseif setop == :symdiff
                push!(_sets, set)
            end

        elseif set isa EmptySet
            if setop == :union

            elseif setop == :intersect
                return SB_SET_EMPTY
         
            elseif setop == :setdiff
                if idx == 1 return SB_SET_EMPTY end

            elseif setop == :symdiff
                push!(_sets, set)
            end
        else
            push!(_sets, set)
        end
    end

    if length(_sets) == 0
        return SB_EMPTY_SET

    elseif length(_sets) == 1
        return _sets[1]

    else
        return CompositeSet(setop, Tuple(_sets))
    end
end

function cartesian(sets::SBSet...; metadata=Dict{Symbol, Any}(),
                    env=Dict{Symbol, Any}())
    if length(sets) < 2
        error("CartesionSet requires at least two member sets.")
    end

    v = []
    for (i, set) in enumerate(sets)
        push!(v, (Symbol("x$i"), set))
    end

    vars = Tuple(v)
    pred = :(:true)
    metadata = Dict{Symbol, Any}()
    env = Dict{Symbol, Any}()

    return FilteredSet(vars, pred, metadata, env)
end

function do_push!(set::EnumSet, elem)

    type_elem = typeof(elem)

    if haskey(set._elems, type_elem)
        push!(set._elems[type_elem], elem)

    else
        error("push! failed due to element type mismatch: " *
                "$type_elem not in $(keys(set._elems)).")
    end
end

function do_pop!(set::EnumSet, elem)

    type_elem = typeof(elem)

    if haskey(set._elems, type_elem)
        pop!(set._elems[type_elem], elem)

    else
        error("pop! failed due to element type mismatch: " *
                "$type_elem not in $(keys(set._elems)).")
    end
end

Base.:in(elem, set::SBSet)      = is_member(set, elem)
Base.:in(elem, set::EmptySet)   = false
Base.:in(elem, set::UniversalSet)= true

Base.push!(set::EnumSet, elem)  = do_push!(set, elem)
Base.pop!(set::EnumSet, elem)   = do_pop!(set, elem)

complement(set::SBSet)          = do_setop(:setdiff, (SB_SET_UNIVERSAL, set))

Base.union(sets::SBSet...)      = do_setop(:union, sets)
Base.intersect(sets::SBSet...)  = do_setop(:intersect, sets)
Base.setdiff(sets::SBSet...)    = do_setop(:setdiff, sets) 
Base.symdiff(sets::SBSet...)    = do_setop(:symdiff, sets) 
Base.:-(sets::SBSet...)         = do_setop(:setdiff, sets) 
Base.:*(sets::SBSet...)         = cartesian(sets...)
Base.:~(set::SBSet)             = do_setop(:setdiff, (SB_SET_UNIVERSAL, set))
