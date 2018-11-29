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

export
    # safety mask 
    SafetyMask,
    safe_actions,
    MaskedEpsGreedyPolicy,
    MaskedValuePolicy


include("safety_mask.jl")
include("masked_policies.jl")

# broken for now
# export     write_mdp_transition,
#     write_mdp_labels,
#     parse_mdp_model, 
#     model_checking,
#     ModelCheckingResult,
#     StormPolicy,
#     get_proba,
#     get_state_action_proba
#     Scheduler, 
#     get_proba, 
#     get_state_action_proba,
#     initial_probability,
#     SafetyMask,
#     safe_actions,
#     MaskedEpsGreedyPolicy,
#     MaskedValuePolicy,

# include("writer.jl")
# include("storm_model_checking.jl")
# include("scheduler.jl")
# include("masked_policies.jl")

end # POMDPModelChecking module
