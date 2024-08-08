using ContinuousTimeMarkovChain
using Documenter

DocMeta.setdocmeta!(ContinuousTimeMarkovChain, :DocTestSetup, :(using ContinuousTimeMarkovChain); recursive=true)

makedocs(;
    modules=[ContinuousTimeMarkovChain],
    authors="Jonathan Miller jonathan.miller@fieldofnodes.com",
    sitename="ContinuousTimeMarkovChain.jl",
    format=Documenter.HTML(;
        canonical="https://fieldofnodes.github.io/ContinuousTimeMarkovChain.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/fieldofnodes/ContinuousTimeMarkovChain.jl",
    devbranch="main",
)
