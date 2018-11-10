using POMDPModels, POMDPs, POMDPModelTools
using MDPModelChecking

# test state indexing 
function test_stateindexing(problem::ProductMDP)
    for (i,s) in enumerate(states(pmdp))
        si = stateindex(pmdp, s)
        if si != i
            return false
        end
    end
    return true
end

function MDPModelChecking.labels(mdp::LegacyGridWorld, s::GridWorldState, a::Symbol)
    good_states = mdp.reward_states[mdp.reward_values .> 0.]
    bad_states = mdp.reward_states[mdp.reward_values .< 0.]
    labeling = Dict{statetype(mdp), Vector{String}}()
    if s in good_states
        return ["good"]
    elseif s in bad_states
        return ["bad"]
    elseif s == GridWorldState(0, 0, true)
        return ["good"]
    else
        return ["!bad", "!good"]
    end
    return labeling
end

function POMDPs.initialstate_distribution(mdp::LegacyGridWorld)
    states = [GridWorldState(1, y) for y=1:mdp.size_y]
    return SparseCat(states, 1/length(states)*ones(length(states)))
end

property = "!bad U good"
ltl2tgba(property, "test.hoa")
automata = hoa2buchi("test.hoa")
mdp = GridWorld()

pmdp = ProductMDP(mdp, automata, Set{ProductState{GridWorldState, Int64}}(), ProductState(GridWorldState(0,0), -1))

b0 = initialstate_distribution(pmdp)

state_space = states(pmdp)
action_space = actions(pmdp)
γ = discount(pmdp)
n_states(pmdp) == n_states(mdp)*n_states(automata) +1
n_states(pmdp) == length(state_space)
n_actions(pmdp) == length(action_space)
statetype(pmdp) == ProductState{GridWorldState, Int64}
actiontype(pmdp) == Symbol

test_stateindexing(pmdp)
trans_prob_consistency_check(pmdp) 

acc = accepting_states!(pmdp)

inf_q, fin_q = acceptance_condition(pmdp.automata)
