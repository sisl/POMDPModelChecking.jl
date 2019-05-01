using Revise
using Random
using POMDPs
using Spot
using POMDPModelChecking
using BeliefUpdaters
using SARSOP
using RockSample
using POMDPSimulators
using Cairo
using POMDPGifs

pomdp = RockSamplePOMDP{3}(rocks_positions=[(2,3), (4,4), (4,2)], 
                           sensor_efficiency=10.0,
                           discount_factor=0.95, 
                           good_rock_reward = 10.0)

## Probability of getting at least one good rock 

function POMDPModelChecking.labels(pomdp::RockSamplePOMDP, s::RSState, a::Int64)
    if a == RockSample.BASIC_ACTIONS_DICT[:sample] && in(s.pos, pomdp.rocks_positions) # sample 
        rock_ind = findfirst(isequal(s.pos), pomdp.rocks_positions) # slow ?
        if s.rocks[rock_ind]
            return (:good_rock,)
        else
            return (:bad_rock,)
        end
    end
    if isterminal(pomdp, s)
        return (:exit,)
    end
    return ()
end

prop = ltl"!bad_rock U exit"

solver = ModelCheckingSolver(property = prop, solver=SARSOPSolver(precision=1e-3), verbose=true)

policy = solve(solver, pomdp);


rng = MersenneTwister(2)
up = DiscreteUpdater(policy.problem)
b0 = initialize_belief(up, initialstate_distribution(policy.problem))
hr = HistoryRecorder(max_steps=50)
hist = simulate(hr, policy.problem, policy, up, b0);
prod_state_hist = hist.state_hist
state_hist = [s.s for s in hist.state_hist];
hist = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
makegif(pomdp, hist, filename="test.gif", spec="(s,a)")

a = Spot.translate(LTLTranslator(buchi=true, deterministic=true, state_based_acceptance=true), prop)
spot.to_generalized_rabin(a)
display(a)

a = Spot.translate(LTLTranslator(buchi=false, deterministic=true, state_based_acceptance=true), prop)