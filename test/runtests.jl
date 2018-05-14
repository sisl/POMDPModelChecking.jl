using POMDPStorm
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

using POMDPs, POMDPModels, POMDPToolbox

function label_grid_world(mdp::GridWorld)
    good_states = mdp.reward_states[mdp.reward_values .> 0.]
    bad_states = mdp.reward_states[mdp.reward_values .< 0.]
    labeling = Dict{state_type(mdp), Vector{String}}()
    for s in good_states
        labeling[s] = ["good"]
    end
    for s in bad_states
        labeling[s] = ["bad"]
    end
    labeling[GridWorldState(0, 0, true)] = ["good", "term"]
    return labeling
end

rng = MersenneTwister(1)

mdp = GridWorld()
labeling = label_grid_world(mdp)
property = "Pmax=? [ (!\"bad\") U \"good\"]"  # follow stormpy syntax

# test model writing
write_mdp_transition(mdp)
write_mdp_labels(mdp, labeling)

# test model parsing
model = parse_mdp_model(mdp, labeling)
model = parse_mdp_model("mdp.tra", "mdp.lab")

# test model checking 
result = model_checking(mdp, labeling, property, 
    transition_file_name="gw.tra",
    labels_file_name="gw.lab")

# test scheduler extraction 
scheduler = Scheduler(mdp, result)

# test scheduler actions 
s = rand(rng, states(mdp))
a = action(scheduler, s)

# test proba extraction 
P = get_proba(mdp, result)
P_sa = get_state_action_proba(mdp, P)

# test policy creation from model checking result
vec_policy = VectorPolicy(mdp, result)
a = action(vec_policy, s)

# test masking
threshold = 0.99
safety_mask = SafetyMask(mdp, result, threshold)
safe_actions(safety_mask, s)

