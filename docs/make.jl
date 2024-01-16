using SetBuilders
using Documenter

DocMeta.setdocmeta!(SetBuilders, :DocTestSetup, :(using SetBuilders); recursive=true)

#repo="https://github.com/grnydawn/SetBuilders.jl/blob/{commit}{path}#{line}",

makedocs(;
    modules=[SetBuilders],
    authors="Youngsung Kim <youngsung.kim.act2@gmail.com>",
    repo=Remotes.GitHub("grnydawn", "SetBuilders.jl"),
    sitename="SetBuilders",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grnydawn.github.io/SetBuilders.jl",
        edit_link="master",
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
    devbranch="main",
)
