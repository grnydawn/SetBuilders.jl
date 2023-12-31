using SetBuilders
using Documenter

DocMeta.setdocmeta!(SetBuilders, :DocTestSetup, :(using SetBuilders); recursive=true)

makedocs(;
    modules=[SetBuilders],
    authors="Youngsung Kim <youngsung.kim.act2@gmail.com>",
    repo="https://github.com/grnydawn/SetBuilders.jl/blob/{commit}{path}#{line}",
    sitename="SetBuilders.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grnydawn.github.io/SetBuilders.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/grnydawn/SetBuilders.jl",
    devbranch="main",
)
