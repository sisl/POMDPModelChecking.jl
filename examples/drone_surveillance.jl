using Revise
using Random
using POMDPs
using Spot
using POMDPModelChecking
using POMDPPolicies
using BeliefUpdaters
using SARSOP
using DroneSurveillance
using POMDPSimulators
import Cairo
using POMDPGifs
using ProgressMeter

# pomdp = DroneSurveillancePOMDP(size=(5,5), camera=PerfectCam(), agent_policy=:restricted)

pomdp = DroneSurveillancePOMDP(size=(8,8), camera=PerfectCam())

# pomdp = DroneSurveillancePOMDP(size=(10,10), camera=PerfectCam())


function POMDPModelChecking.labels(pomdp::DroneSurveillancePOMDP, s::DSState, a::Int64)
    return labels(pomdp, s)
end
function POMDPModelChecking.labels(pomdp::DroneSurveillancePOMDP, s::DSState)
    if s.quad == pomdp.region_A
        # return (:a,)
        return ()
    elseif s.quad == pomdp.region_B
        return (:b,)
        # return ()
    elseif s.quad == s.agent && !(isterminal(pomdp, s))
        return (:det,)
        # return ()
    elseif isterminal(pomdp, s)
        # return (:exit,)
        return ()
    else
        return ()
    end
end


@show n_states(pomdp)
@show n_actions(pomdp)
@show n_observations(pomdp)


prop = ltl"!det U b"
# prop = ltl"G!det & G!exit"
# prop = ltl"F b"
# prop = ltl"G !hover & G !det & G!exit"
# prop = ltl"!det U b & !det U a & G!exit"
# prop = ltl"!det U b & !det U a & b => !det U a"

run(`rm model.pomdpx`)
solver = ModelCheckingSolver(property = prop, 
                             solver = SARSOPSolver(precision=1e-2), verbose=true)

policy = solve(solver, pomdp);


rng = MersenneTwister(2)
up = DiscreteUpdater(policy.problem)
b0 = initialize_belief(up, initialstate_distribution(policy.problem))
s0 = initialstate(pomdp, rng)
s0 = DSState([1,1], [1,2])
hr = HistoryRecorder(max_steps=20)
hist = simulate(hr, policy.problem, policy, up, b0);
success = undiscounted_reward(hist) > 0.0
state_hist = [s.s for s in hist.state_hist]
shist = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
makegif(pomdp, shist, filename="test.gif", spec="(s,a)")

@showprogress for n=1:100
    hr = HistoryRecorder(max_steps=10)
    hist = simulate(hr, policy.problem, policy, up, b0);
    success = undiscounted_reward(hist) > 0.0
    println("discounted reward: ", discounted_reward(hist))
    if !success
        println("Crash")
        state_hist = [s.s for s in hist.state_hist]
        shist = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
        makegif(pomdp, shist, filename="test.gif", spec="(s,a)")
    end
end



actionvalues(policy, b0)

undiscounted_reward(hist)

b0 = b

for (i,s) in enumerate(b0.state_list)
    if b0.b[i] != 0
        println(s)
    end
end

# predict
using Printf
a = 1
for (i,s) in enumerate(b0.state_list)
    if b0.b[i] != 0
        d = transition(policy.problem, s, a)
        for ss in d.vals
            sss = (ss.s.quad, ss.s.agent, s.q)
            @printf("%s", ss)
        end
        @printf("\n")
    end
end

s0 = rand(rng, b0)
sp, o, r = generate_sor(policy.problem, s0, 1, rng)

b = update(up, b0, 5, o);


a = actionvalues(policy, b)
 
empty!(policy.problem.accepting_states)

s0 = initialstate(pomdp, rng)
hr = HistoryRecorder(max_steps=10)
hist = simulate(hr, pomdp, policy, up, b0, s0);
state_hist = [s for s in hist.state_hist]
hist = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
makegif(pomdp, hist, filename="test.gif", spec="(s,a)")


function deterministic_belief(pomdp, s)
    b = zeros(length(states(pomdp)))
    si = stateindex(pomdp, s)
    b[si] = 1.0
    return DiscreteBelief(pomdp, b)
end


dra = DeterministicRabinAutomata(prop)
sink_state = ProductState(first(states(pomdp)), -1)
pmdp = ProductPOMDP(pomdp, dra, sink_state)

mecs = maximal_end_components(pmdp, verbose=true)

stateindex(pmdp, ProductState(DSState([5,5], [1,1]), 1))

for si in mecs[2]
    s = states(pmdp)[si]
end
