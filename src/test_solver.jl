using DiscreteValueIteration

mdp = GridWorld(sx=10,sy=10)
mdp.reward_states = [GridWorldState(4, 3), GridWorldState(4, 6), GridWorldState(9, 3)]
mdp.reward_values = [-200, -200, 10.0]
mdp.terminals = Set(mdp.reward_states)
mdp.bounds_penalty = 0.

function MDPModelChecking.labels(mdp::GridWorld, s::GridWorldState)
    good_states = mdp.reward_states[mdp.reward_values .> 0.]
    bad_states = mdp.reward_states[mdp.reward_values .< 0.]
    labeling = Dict{state_type(mdp), Vector{String}}()
    if s in bad_states
        return ["bad"]
#     elseif s == GridWorldState(0, 0, true)
#         return ["good"]
    else
#         return ["!bad", "!good"]
        return ["!bad"]
    end
    return labeling
end

solver = ModelCheckingSolver(property = "G!bad", solver=ValueIterationSolver())

policy = solve(solver, mdp);

s = rand(states(mdp))

value(policy, s)

value_vector(policy, s)

reset_memory!(policy)