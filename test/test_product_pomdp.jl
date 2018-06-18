using POMDPs, POMDPModels, POMDPToolbox, MDPModelChecking
using QMDP

pomdp = FullyObservablePOMDP(GridWorld())

function MDPModelChecking.labels(pomdp::FullyObservablePOMDP{POMDPModels.GridWorldState,Symbol}, s::GridWorldState)
    good_states = pomdp.mdp.reward_states[pomdp.mdp.reward_values .> 0.]
    bad_states = pomdp.mdp.reward_states[pomdp.mdp.reward_values .< 0.]
    if s in bad_states 
        return ["bad"]    
    elseif s in good_states
        return ["good"]
    elseif s == GridWorldState(0, 0, true)
        return ["good"]
    else
        return ["!bad", "!good"]
    end
    return labeling
end

property =  "!crash U goal"

solver = ModelCheckingSolver(property = "G!bad", solver=ValueIterationSolver())

policy = solve(solver, pomdp);