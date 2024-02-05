# utils.jl

function TAB(width; mark="") :: String
    return repeat(" ", max(0, 4 * width - length(mark))) * mark
end

function SETNAME(x)

    Q = div(x-1,26)
    R = (x-1)%26

    return Q == 0 ? "$('A'+x-1)" : ('A'+Q-1)*('A'+R)
end

setops_syms = Dict{Symbol, AbstractString}(
                    :union      => "∪",
                    :intersect  => "∩",
                    :setdiff    => "-",
                    :symdiff    => "∆"
                )

find_param(vect::Vector{T}) where T  = T

function sb_eval(expr, env::Dict{Symbol, Any}=Dict{Symbol, Any}())

    M = Module(:MyModule)
    for (k, v) in env
        Base.eval(M, :($k = $v))
    end

    try
        return Base.eval(M, expr)

    catch err
        error("Evaluating set expression, $expr, is failed: $err")
    end
end
