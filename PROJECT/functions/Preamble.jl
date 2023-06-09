# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.14.4
#   kernelspec:
#     display_name: Julia (6 threads) 1.8.2
#     language: julia
#     name: julia-_6-threads_-1.8
# ---

using Pkg
Pkg.activate(dir)
using Distributed

@everywhere dir = dirname(pwd()) * "/PROJECT"

# +
global const multiProcess = (nworkers()>1) ? true : false # only use multiprocessing if run with -p, otherwise use -t threads by default

if multiProcess
    print("Num workers: ", nworkers(), "\n\n")
    
    @everywhere using Pkg
    @everywhere Pkg.activate(dir)
    @everywhere using Distributed, StatsBase, Statistics, Distributions, Roots, PyPlot, LsqFit, Dates, ForwardDiff, Combinatorics, JLD
else
    print("Num threads: ", Threads.nthreads(), "\n\n")
    
    using StatsBase, Statistics, Distributions, Roots, PyPlot, LsqFit, Dates, ForwardDiff, Combinatorics, JLD
end

using Colors, PlotUtils

# +
# Also useful: Graphs, MetaGraphs, Plots, GraphRecipes
