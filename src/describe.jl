# describe.jl : SetBuilder Set Descriptions

function get_mark(set, mark)

    if mark isa Nothing
        return nothing

    elseif mark isa SBSet
        return (set == mark) ? "=> " : nothing

    elseif mark isa Tuple && length(mark) == 2
        return (set == mark[1]) ? mark[2] : nothing

    elseif mark isa Vector
        for (s, m) in mark
            set == s && return m
        end
        return nothing
    else
        return nothing
    end
end

function describe(set::EmptySet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    return tabs * prepend * "EmptySet(Ø)"
end

function describe(set::UniversalSet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    return tabs * prepend * "UniversalSet(U)"
end

function describe(set::TypeSet{T}; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String where T

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    if haskey(set._meta, :sb_set_desc)
        return tabs * prepend * "\"$(set._meta[:sb_set_desc])\""
    else
        return tabs * prepend * "{ x ∈ ::$T }"
    end
end

function describe(set::EnumerableSet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    types = ["::$t" for t in keys(set._elems)]
    tnames = join(types, ", ")

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    if haskey(set._meta, :sb_set_desc)
        return tabs * prepend * "\"$(set._meta[:sb_set_desc])\""
    else
        return tabs * prepend * (length(types) > 1 ?
                                "{ x ∈ ($tnames,) }" : "{ x ∈ $tnames }")
    end
end

function describe(set::CompositeSet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    lines = String[]

    for s in set._sets
        if s isa CompositeSet
            push!(lines, describe(s, depth=depth+1, limit=limit, mark=mark,
                                    collect=collect))
        else
            push!(lines, describe(s, depth=depth, limit=limit,mark=mark, collect=collect))
        end
    end
        
    return join(lines, "\n"*tabs*setops_syms[set._op] * "\n")
end

function describe(set::PredicateSet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    N     = length(set._vars)
    vars  = [k for (k, v) in set._vars]
    sets  = [v for (k, v) in set._vars]
    names = [prefix*SETNAME(i) for i in 1:N]
    lines = String[]

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))

    if haskey(set._meta, :sb_set_desc)
        push!(lines, tabs*prepend*"\"$(set._meta[:sb_set_desc]))\"")
    else
        setvar = join(["$v ∈ $s" for (v, s) in zip(vars, names)], ", ")
        push!(lines, tabs*prepend*"{ $setvar | $(set._pred) }")

    end

    tlines = String[]
    for (n, s) in zip(names, sets)
        desc = describe(s, prepend=(n*" = "), prefix=(n*"."),
                depth=depth+1, limit=limit, mark=mark, collect=collect)
        desc != "" && push!(tlines, desc)
    end

    if length(tlines) > 0
        lines[end] *= ", where"
        append!(lines, tlines)
    end

    return join(lines, "\n")
end

function str_pred(preds)
    lines = String[]

    for pred in preds
        push!(lines, "$pred")
    end

    return join(lines, ", ")
end

function str_mapping(mapping)

    lines = String[]
    for (svar, exprtuple) in mapping
        if length(exprtuple) == 1
            push!(lines, "$svar = $(exprtuple[1])")

        elseif length(exprtuple) != 0
            push!(lines, "$svar = $(exprtuple)")
        end 
    end

    return join(lines, ", ")
end


function describe(set::MappedSet; prepend="", prefix="", depth=0,
                    limit=-1, mark=nothing, collect=nothing) :: String

    if collect isa Tuple && length(collect) == 2
        push!(collect[2], collect[1](set))
    end

    limit >= 0 && depth > limit && return ""

    if any(x->x==false, set._domain_pred) || any(x->x==false, set._codomain_pred) 
        return (describe(EmptySet(), prepend=prepend, prefix=prefix,
                depth=depth, limit=limit, mark=mark, collect=collect) *
                " : filtered all elements out")
    end

    DN     = length(set._domain)
    Dvars  = [k for (k, v) in set._domain]
    Dsets  = [v for (k, v) in set._domain]
    Dnames = [prefix*SETNAME(i) for i in 1:DN]

    CN     = length(set._codomain)
    Cvars  = [k for (k, v) in set._codomain]
    Csets  = [v for (k, v) in set._codomain]
    Cnames = [prefix*SETNAME(i) for i in (DN+1):(DN+CN)]

    mstr = get_mark(set, mark)
    tabs = (mstr isa AbstractString ? TAB(depth, mark=mstr) : TAB(depth))
    tabs1 = (mstr isa AbstractString ? TAB(depth+1, mark=mstr) : TAB(depth+1))

    lines = String[]

    if haskey(set._meta, :sb_set_desc)
        push!(lines, tabs*"\"$(set._meta[:sb_set_desc]))\"")
    else
        Dsetvar = join(["$v ∈ $s" for (v, s) in zip(Dvars, Dnames)], ", ")
        push!(lines, tabs*prepend)
        push!(lines, tabs*"{ $Dsetvar }")

        push!(lines, tabs*TAB(0)*"         /\\ B-MAP")
        push!(lines, tabs*TAB(0)*"      || ||")
        push!(lines, tabs*TAB(0, mark="F-MAP")*" \\/")


        Csetvar = join(["$v ∈ $s" for (v, s) in zip(Cvars, Cnames)], ", ")
        push!(lines, tabs*"{ $Csetvar }")
    end

    tlines = String[]
    for (n, s) in zip(Dnames, Dsets)
        desc = describe(s, prepend=(n*" = "), prefix=(n*"."),
                depth=depth+1, limit=limit, mark=mark, collect=collect)
        desc != "" && push!(tlines, desc)
    end

    if length(tlines) > 0
        lines[end] *= ", where"
        append!(lines, tlines)
    end

    if !haskey(set._meta, :sb_set_desc)
        push!(lines, tabs1*"F-MAP: $(str_mapping(set._forward_map))")

        if length(set._codomain_pred) > 0
            lines[end] *= ", with filter: $(str_pred(set._codomain_pred))"
        end
        
        push!(lines, tabs1*"B-MAP: $(str_mapping(set._backward_map))")

        if length(set._domain_pred) > 0
            lines[end] *= ", with filter: $(str_pred(set._domain_pred))"
        end
    end

    for (n, s) in zip(Cnames, Csets)
        desc = describe(s, prepend=(n*" = "), prefix=(n*"."),
                depth=depth+1, limit=limit, mark=mark, collect=collect)
        desc != "" && push!(lines, desc)
    end

    return join(lines, "\n")
end

Base.repr(set::SBSet)   = describe(set)
