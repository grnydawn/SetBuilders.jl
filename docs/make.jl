
push!(LOAD_PATH,"../src/")

using SetBuilders
using Documenter

DocMeta.setdocmeta!(SetBuilders, :DocTestSetup, :(using SetBuilders); recursive=true)

makedocs(;
    modules=[SetBuilders],
    authors="Youngsung Kim <youngsung.kim.act2@gmail.com>",
    source  = "src",
    build   = "build",
    repo="https://github.com/grnydawn/SetBuilders.jl/blob/{commit}{path}#{line}",
    sitename="SetBuilders",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grnydawn.github.io/SetBuilders.jl",
        edit_link="dev",
        assets=String[],
    ),
    checkdocs=:exports,
    pages=[
        "SetBuilders Documentation" => "index.md",
        "Manual" => [
            "creation.md",
            "operations.md",
            "description.md",
            "event.md",
            "mapping.md",
            "sharing.md",
        ],
        "Reference" => "reference.md",
        "Developer Documentation" => "developer.md",
    ],
)

deploydocs(;
    repo="github.com/grnydawn/SetBuilders.jl",
    branch = "gh-pages",
    devbranch="dev",
)
