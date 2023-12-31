using InteractiveUtils: subtypes, supertypes

@enum LoggingSeverity begin
    SB_LOG_CRITICAL = 5
    SB_LOG_ERROR    = 4
    SB_LOG_WARN     = 3
    SB_LOG_INFO     = 2
    SB_LOG_DEBUG    = 1
end

const SB_CONFIG= Dict{Symbol, Any}()

# logging
#SB_CONFIG[:logging_severity] = SB_LOG_INFO
SB_CONFIG[:logging_severity] = SB_LOG_ERROR

function sb_eval(expr, env::Dict{Symbol, Any})

    M = Module(:MyModule)
    for (k, v) in env
        Base.eval(M, :($k = $v))
    end
    return Base.eval(M, expr)
end


function sb_log(msg::Any, severity=SB_LOG_INFO)
    if severity >= SB_CONFIG[:logging_severity]
        sevstr = string(severity)[8:end]
        stack = stacktrace()
        if length(stack) >= 3
            # The caller is usually the third entry in the stack trace
            path, line = string(stack[3].file), stack[3].line
            dir, file = splitdir(path)
            println("$(sevstr)\t: $(file)#$(line) : $(string(msg))")
        else
            println("$(sevstr)\t: $(string(msg))")
        end
    end
end

function all_subtypes(t::Type; filter::Union{Nothing, Function}=nothing)
    direct_subtypes = subtypes(t)
    if isempty(direct_subtypes)
        return []
    else
        indirect_subtypes = Vector{Type}()

        for s in vcat(direct_subtypes, map(all_subtypes, direct_subtypes)...)
            if !(s in indirect_subtypes)
                if filter isa Function && !filter(s)
                    continue
                end
                push!(indirect_subtypes, s)
            end
        end
        
        indirect_subtypes
    end
end
