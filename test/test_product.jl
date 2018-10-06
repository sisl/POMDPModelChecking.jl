using POMDPModels, POMDPs, POMDPToolbox
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

function test_transition(problem::ProductMDP)
    for s in states(problem)
        for a in actions(problem)
            d = transition(problem, s, a)
            tsum = 0. 
            for (sp, p) in weighted_iterator(d)
                tsum += p
            end
            if !(tsum ≈ 1.0)
                return false 
            end
        end
    end
    return true
end

function MDPModelChecking.labels(mdp::GridWorld, s::GridWorldState)
    good_states = mdp.reward_states[mdp.reward_values .> 0.]
    bad_states = mdp.reward_states[mdp.reward_values .< 0.]
    labeling = Dict{state_type(mdp), Vector{String}}()
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

function POMDPs.initialstate_distribution(mdp::GridWorld)
    states = [GridWorldState(1, y) for y=1:mdp.size_y]
    return SparseCat(states, 1/length(states)*ones(length(states)))
end

property = "!bad U good"
ltl2tgba(property, "test.hoa")
automata = hoa2buchi("test.hoa")
mdp = GridWorld()

pmdp = ProductMDP(mdp, automata)

b0 = initialstate_distribution(pmdp)



state_space = states(pmdp)
action_space = actions(pmdp)
γ = discount(pmdp)
n_states(pmdp) == length(state_space)
n_actions(pmdp) == length(action_space)
statetype(pmdp) == ProductState{GridWorldState, Int64}
action_type(pmdp) == Symbol

test_stateindexing(pmdp)
test_transition(pmdp) 

for s in states(pmdp)
    for a in actions(pmdp, s)
        d = transition(pmdp, s, a)
        tsum = 0. 
        for (sp, p) in weighted_iterator(d)
            tsum += p
        end
        if !(tsum ≈ 1.0)
            println("error for s ", s, " a ", a, " sums to ", tsum, " next states ", d.vals)
        end
    end
end

acc = accepting_states!(pmdp)

inf_q, fin_q = acceptance_condition(pmdp.automata)

using DiscreteValueIteration
solver = ValueIterationSolver()

policy = solve(solver, pmdp, verbose=true)
util = policy.util

# post process 
reach_prob = zeros(n_states(pmdp.mdp))
for (i, s) in enumerate(ordered_states(pmdp.mdp))
    ps = ProductState(s, pmdp.automata.initialstate)
    psi = stateindex(pmdp, ps)
    reach_prob[i] = util[psi]
    if i == 29
        println(s)
        println(ps)
        println(util[psi])
        ps2 = ProductState(s, 1)
        psi2 = stateindex(pmdp, ps2)
        println(util[psi2])
    end
end
    
P = reach_prob