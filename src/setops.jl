# setops.jl : SetBuilder Set Operations

function do_push!(set::PartiallyEnumerableSet, elem)

    type_elem = typeof(elem)

    if haskey(set._elems, type_elem)
        push!(set._elems[type_elem], elem)

    else
        error("push! failed due to element type mismatch: " *
                "$type_elem not in $(keys(set._elems)).")
    end
end

function do_pop!(set::PartiallyEnumerableSet, elem)

    type_elem = typeof(elem)

    if haskey(set._elems, type_elem)
        pop!(set._elems[type_elem], elem)

    else
        error("pop! failed due to element type mismatch: " *
                "$type_elem not in $(keys(set._elems)).")
    end
end

function do_setop(setop::Symbol, sets::NTuple{N, SBSet} where N, kwargs) :: SBSet

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
        meta  = Dict{Symbol, Any}(kwargs)
        return CompositeSet(setop, Tuple(_sets), meta)
    end
end

Base.push!(set::PartiallyEnumerableSet, elem)  = do_push!(set, elem)
Base.pop!(set::PartiallyEnumerableSet, elem)   = do_pop!(set, elem)


Base.union(sets::SBSet...; kwargs...)       = do_setop(:union, sets, kwargs)
Base.intersect(sets::SBSet...; kwargs...)   = do_setop(:intersect, sets, kwargs)
Base.setdiff(sets::SBSet...; kwargs...)     = do_setop(:setdiff, sets, kwargs) 
Base.symdiff(sets::SBSet...; kwargs...)     = do_setop(:symdiff, sets, kwargs) 
Base.:-(sets::SBSet...)                     = do_setop(:setdiff, sets, ()) 
Base.:~(set::SBSet)                         = do_setop(:setdiff,
                                                       (UniversalSet(), set), ())
complement(set::SBSet; kwargs...)           = do_setop(:setdiff,
                                                       (UniversalSet(), set), kwargs)
