using GlobalMetadata
using Documenter

DocMeta.setdocmeta!(GlobalMetadata, :DocTestSetup, :(using GlobalMetadata); recursive=true)

makedocs(;
    modules=[GlobalMetadata],
    authors="Zachary P. Christensen <zchristensen7@gmail.com> and contributors",
    repo="https://github.com/Tokazama/GlobalMetadata.jl/blob/{commit}{path}#{line}",
    sitename="GlobalMetadata.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Tokazama.github.io/GlobalMetadata.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Tokazama/GlobalMetadata.jl",
    devbranch="main",
)
