__precompile__(false)

module POMDPModelChecking

# package code goes here
using POMDPs
using POMDPModelTools
using POMDPPolicies
using LightGraphs
using Parameters
using Random
using DiscreteValueIteration
using LinearAlgebra
using Distributions
using Spot

export
    ReachabilitySolver,
    ReachabilityPolicy,
    ReachabilityMDP,
    ReachabilityPOMDP

include("reachability.jl")

export 
    ProductState,
    ProductMDP,
    ProductPOMDP,
    labels

include("product.jl")

export
    # graph analysis 
    maximal_end_components,
    mdp_to_graph,
    sub_mdp,
    accepting_states!

include("end_component.jl")

export 
    ModelCheckingSolver,
    ModelCheckingPolicy

include("model_checking_solver.jl")


end # POMDPModelChecking module
