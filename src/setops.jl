# setops.jl : SetBuilder Set Operations

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

function do_setop(setop::Symbol, sets::NTuple{N, SBSet} where N) :: SBSet

    if length(sets) == 0
        error("No set is provided for the set opration, $setop.")
    end

    _sets = Vector{SBSet}()

    for (idx, set) in enumerate(sets)
        if set isa UniversalSet
            if setop == :union
                return UniversalSet()

            elseif setop == :intersect

            elseif setop == :setdiff
                idx == 1 ? push!(_sets, set) : return EmptySet()

            elseif setop == :symdiff
                push!(_sets, set)
            end

        elseif set isa EmptySet
            if setop == :union

            elseif setop == :intersect
                return EmptySet()
         
            elseif setop == :setdiff
                idx == 1 && return EmptySet()

            elseif setop == :symdiff
                push!(_sets, set)
            end
        elseif idx == 1
            push!(_sets, set)

        elseif length(_sets) > 0 && set == _sets[1]
            if setop == :union

            elseif setop == :intersect
         
            elseif setop == :setdiff
                return EmptySet()

            elseif setop == :symdiff
                return EmptySet()
            end
        else
            push!(_sets, set)
        end
    end

    if length(_sets) == 0
        return EmptySet()

    elseif length(_sets) == 1
        return _sets[1]

    else
        return CompositeSet(setop, Tuple(_sets))
    end
end

Base.push!(set::EnumSet, elem)  = do_push!(set, elem)
Base.pop!(set::EnumSet, elem)   = do_pop!(set, elem)

complement(set::SBSet)          = do_setop(:setdiff, (UniversalSet(), set))

Base.union(sets::SBSet...)      = do_setop(:union, sets)
Base.intersect(sets::SBSet...)  = do_setop(:intersect, sets)
Base.setdiff(sets::SBSet...)    = do_setop(:setdiff, sets) 
Base.symdiff(sets::SBSet...)    = do_setop(:symdiff, sets) 
Base.:-(sets::SBSet...)         = do_setop(:setdiff, sets) 
Base.:~(set::SBSet)             = do_setop(:setdiff, (UniversalSet(), set))
