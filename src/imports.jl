# imports.jl : SetBuilder Set Imports

function collect_expects(_mod::Expr) :: Tuple{Vector, Vector}

    function collect_args(args, vec)
        for arg in args
            arg isa LineNumberNode && continue

            if arg isa Expr && arg.head == :(::)
                push!(vec, (arg.args[1], arg.args[2]))
            end
        end
    end

    (_mod isa Expr || _mod.head == :module ||
        error("The target is not a Julia module."))
    
    isregular, modname, modblock = _mod.args

    expects = Vector{Tuple{Symbol, Union{Symbol, Expr}}}()
    options = Vector{Tuple{Symbol, Union{Symbol, Expr}}}()
    removes = Vector{Integer}()

    for (idx, (prev, node)) in enumerate(zip(modblock.args[1:end-1],
                                             modblock.args[2:end]))
        node isa LineNumberNode && continue

        if node isa Expr
            if node.head == :macrocall
                if node.args[1] == Symbol("@expect")
                    collect_args(node.args[2:end], expects)
                    push!(removes, idx+1)
                    continue

                elseif node.args[1] == Symbol("@option")
                    collect_args(node.args[2:end], options)
                    push!(removes, idx+1)
                    continue
                end
            end
        end
    end

    for idx in reverse(removes)
        deleteat!(modblock.args, idx)
    end

    return expects, options
end

function import_sets(target::AbstractString, env::Dict{Symbol, Any},
                        meta::Dict{Symbol, Any}) :: Nothing

    modstr = nothing

    if isfile(target)

        file = open(target, "r")
        modstr = read(file, String)
        close(file)

    else
        error("Cound not access to the target: $target.")
    end

    if modstr isa AbstractString

        modexpr = Meta.parse(modstr)

        expects, options = collect_expects(modexpr)

        # check if expected values are provided
        for (name, type) in expects
            if haskey(env, name)
                if !(env[name] isa Base.eval(type))
                    error("Type of $name is expected as $(string(type))," *
                          " but $(typeof(env[name])).")
                end
            else
                error("$name is expected by $target, but not provided.")
            end
        end

        modname = modexpr.args[2]
        modbody = modexpr.args[3].args

        M = Module(modname)

        # adds "using SetBuilders.jl"
        Base.eval(M, LineNumberNode(1, :none))
        Base.eval(M, :(using SetBuilders))

        for (k, v) in env
            Base.eval(M, :($k = $v))
        end

        for node in modbody
            Base.eval(M, node)
        end

        Base.eval(SetBuilders, :($modname = $M))
    else
        error("Could not parse set module: $target.")
    end

    return nothing
end
