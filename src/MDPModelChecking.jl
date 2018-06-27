module MDPModelChecking

# package code goes here
using POMDPs, POMDPToolbox
using LightGraphs
using DiscreteValueIteration
using Parameters

export 

    # automata processing
    BuchiAutomata,
    RabinAutomata,
    acceptance_condition,
    ltl2tgba,
    automata_type,
    hoa2buchi,
    hoa2rabin

include("automata.jl")

export
    # graph analysis and product MDP
    maximal_end_components,
    mdp_to_graph,
    sub_mdp,
    ProductState,
    ProductMDP, 
    ProductPOMDP,
    labels,
    accepting_states!,
    ModelCheckingSolver,
    ModelCheckingPolicy,
    reset_memory!,
    value_vector

include("product_mdp.jl")
include("product_pomdp.jl")
include("end_component.jl")
include("model_checking_solver.jl")

export
    # safety mask 
    SafetyMask,
    safe_actions,
    value_vector,
    MaskedEpsGreedyPolicy,
    MaskedValuePolicy


include("safety_mask.jl")
include("masked_policies.jl")

# export     write_mdp_transition,
#     write_mdp_labels,
#     parse_mdp_model, 
#     model_checking,
#     ModelCheckingResult,
#     Scheduler, 
#     get_proba, 
#     get_state_action_proba,
#     initial_probability,
#     SafetyMask,
#     safe_actions,
#     MaskedEpsGreedyPolicy,
#     MaskedValuePolicy,

# using PyCall

# @pyimport stormpy

# include("writer.jl")
# include("storm_model_checking.jl")
# include("scheduler.jl")
# include("masked_policies.jl")

end # MDPModelChecking module
