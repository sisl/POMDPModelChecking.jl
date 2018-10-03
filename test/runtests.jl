using MDPModelChecking
using Test

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


function POMDPs.initial_state_distribution(mdp::GridWorld)
    return SparseCat(states(mdp), 1/n_states(mdp)*ones(n_states(mdp)))
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

# test overwrite
println("There should be a warning between here: ")
result = model_checking(mdp, labeling, property, 
    transition_file_name="gw.tra",
    labels_file_name="gw.lab",
    overwrite = true)
println("And here. ")

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

# test masked policy 
masked_eg = MaskedEpsGreedyPolicy(mdp, 0.7, safety_mask, MersenneTwister(1))
masked_v = MaskedValuePolicy(ValuePolicy(mdp), safety_mask)

p0 = initial_probability(mdp, result)
@test isapprox(p0, 0.964, atol=0.001)