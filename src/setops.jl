# setops.jl : SetBuilder Set Operations

# TODO: support util functions for EnumerableSet

function do_push!(set::EnumerableSet, elems...)

    for elem in elems
        type_elem = typeof(elem)

        if haskey(set._elems, type_elem)
            push!(set._elems[type_elem], elem)

        else
            error("push! failed due to element type mismatch: " *
                    "$type_elem not in $(keys(set._elems)).")
        end
    end

    return set
end

function do_pop!(set::EnumerableSet, elems...)

    item = nothing

    if length(elems) == 0
        buf = []
        for s in values(set._elems)
            length(s) > 0 && push!(buf, s)
        end

        length(buf) == 0 && throw(ArgumentError("set must be non-empty"))

        item = pop!(rand(buf))
 
    else
        for elem in elems
            type_elem = typeof(elem)

            if haskey(set._elems, type_elem)
                item = pop!(set._elems[type_elem], elem)

            else
                error("pop! failed due to element type mismatch: " *
                        "$type_elem not in $(keys(set._elems)).")
            end
        end
    end

    return item
end

function do_setop(setop::Symbol, sets::NTuple{N, SBSet} where N; kwargs...) :: SBSet

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

"""
    push!(set::EnumerableSet, elems...)

  Insert one or more items in Enumerable set.

# Examples
```julia-repl
julia> A = @setbuild(Union{Int64, Float64}[1])
EnumerableSet([{Float64}*0, {Int64}*1])

julia> ismember(1, A)
true

julia> ismember(Int32(1), A)
false

julia> push!(A, Float64(2.0))
EnumerableSet([{Float64}*1, {Int64}*1])

julia> ismember(Float64(2.0), A)
true

julia> pop!(A, Float64(2.0))
2.0

julia> ismember(Float64(2.0), A)
false
```
"""
Base.push!(set::EnumerableSet, elems...)    = do_push!(set, elems...)

"""
    push!(set::EnumerableSet, elems...)

  Insert one or more items in Enumerable set.

# Examples
```julia-repl
julia> A = @setbuild(Union{Int64, Float64}[1])
EnumerableSet([{Float64}*0, {Int64}*1])

julia> ismember(1, A)
true

julia> ismember(Int32(1), A)
false

julia> push!(A, Float64(2.0))
EnumerableSet([{Float64}*1, {Int64}*1])

julia> ismember(Float64(2.0), A)
true

julia> pop!(A, Float64(2.0))
2.0

julia> ismember(Float64(2.0), A)
false
```
"""
Base.pop!(set::EnumerableSet, elems...)     = do_pop!(set, elems...)

Base.union(sets::SBSet...; kwargs...)       = do_setop(:union, sets; kwargs...)
Base.intersect(sets::SBSet...; kwargs...)   = do_setop(:intersect, sets; kwargs...)
Base.setdiff(sets::SBSet...; kwargs...)     = do_setop(:setdiff, sets; kwargs...) 
Base.symdiff(sets::SBSet...; kwargs...)     = do_setop(:symdiff, sets; kwargs...) 
Base.:-(sets::SBSet...)                     = do_setop(:setdiff, sets) 
Base.:~(set::SBSet)                         = do_setop(:setdiff,
                                                (UniversalSet(), set))
"""
    complement(set <: SBSet)

generates a complement set

```julia
julia> complement(@setbuild()) == @setbuild(Any)
true

julia> ~@setbuild() == @setbuild(Any)
true
```
"""
complement(set::SBSet; kwargs...)           = do_setop(:setdiff,
                                                (UniversalSet(), set); kwargs...)
