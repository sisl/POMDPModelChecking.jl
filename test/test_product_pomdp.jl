using POMDPs, POMDPModels, POMDPModelTools, MDPModelChecking
using DiscreteValueIteration

pomdp = FullyObservablePOMDP(SimpleGridWorld())

function MDPModelChecking.labels(pomdp::FullyObservablePOMDP{GWPos,Symbol}, s::GWPos)
    if get(pomdp.mdp.rewards, s, 0.) < 0.
        return ["bad"]    
    elseif get(pomdp.mdp.rewards, s, 0.) > 0.
        return ["good"]
    elseif s == GWPos(-1,-1)
        return ["good"]
    else
        return ["!bad", "!good"]
    end
end

property =  "!crash U goal"

solver = ModelCheckingSolver(property = "G!bad", solver=ValueIterationSolver())

policy = solve(solver, pomdp);