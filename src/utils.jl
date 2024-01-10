# utils.jl

setops_syms = Dict{Symbol, AbstractString}(
                    :union      => "∪",
                    :intersect  => "∩",
                    :setdiff    => "-",
                    :symdiff    => "<>"
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

