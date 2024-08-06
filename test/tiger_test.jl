using Revise
using POMDPModelChecking
using POMDPs
using POMDPModels
using POMDPSimulators
using BeliefUpdaters
using QMDP
using SARSOP
using POMCPOW

pomdp = TigerPOMDP()

function POMDPModelChecking.labels(pomdp::TigerPOMDP, s::Bool, a::Int64)
    if (a == 1 && s) || (a == 2 && !s)
        return ["eaten"]
    elseif (a == 2 && s) || (a == 1 && !s)
        return ["!eaten"]
    else
        return ["!eaten"]
    end
end

# POMDPs.reward(pomdp::TigerPOMDP, s::Bool, a::Int64) = ((a == 1 && s) || (a == 2 && !s)) ? -1. : 0.
# POMDPs.reward(pomdp::TigerPOMDP, s::Bool, a::Int64, sp::Int64) = (a == 1 && sp) || (a == 2 && !sp) ? -1. : 0.
γ =  1 - 1e-3
POMDPs.discount(::ProductPOMDP{Bool,Int64,Bool,Int64,String}) = γ
sarsop = SARSOPSolver(precision = 1e-3)
solver = ModelCheckingSolver(property = "!eaten", solver=sarsop)

ltl2tgba(solver.property, solver.automata_file)
autom_type = automata_type(solver.automata_file)
automata = nothing
if autom_type == "Buchi"
    automata = hoa2buchi(solver.automata_file)
elseif autom_type == "Rabin"
    automata = hoa2rabin(solver.automata_file)
end

pmdp = ProductPOMDP(pomdp, automata, Set{ProductState{Bool, Int64}}(), ProductState(false, -1))
accepting_states!(pmdp)


policy = solve(sarsop, pmdp)

updater = DiscreteUpdater(pmdp)
b0 = initialize_belief(up, initialstate_distribution(pmdp))


b0 = initialize_belief(up, initialstate_distribution(pmdp))
using Random
rng = MersenneTwister(1)

n_ep = 1000
avg_r = 0.
for ep=1:n_ep
    global avg_r
    s0 = initialstate(pomdp, rng)
    hist = simulate(hr, pomdp, policy, up, b0, s0);
    if hist.reward_hist[end] > 0.
        avg_r += 1
    end
end
avg_r /= n_ep




policy = solve(QMDPSolver(), pomdp)






pomcpow = POMCPOWSolver()

solver = ModelCheckingSolver(property = "!eaten U safe", solver=sarsop)

POMDPs.discount(::ProductPOMDP{Bool, Int64, Bool, Int64, String}) = γ

policy = solve(solver, pomdp)
pmdp = policy.mdp

function POMDPs.action(policy::ModelCheckingPolicy{P,M}, b::DiscreteBelief) where {P<:Policy, M<:ProductPOMDP}
    return action(policy.policy, b)
end

policy = solve(sarsop, pomdp)

hr = HistoryRecorder(max_steps = 20)
up = DiscreteUpdater(policy.mdp)
b0 = initialize_belief(up, initialstate_distribution(pmdp))
using Random
rng = MersenneTwister(1)

n_ep = 1000
avg_r = 0.
for ep=1:n_ep
    global avg_r
    s0 = initialstate(pomdp, rng)
    hist = simulate(hr, pomdp, policy, up, b0, s0);
    if hist.reward_hist[end] > 0.
        avg_r += 1
    end
end
avg_r /= n_ep




trans_prob_consistency_check(pmdp) 

for s in states(pmdp)
    for a in actions(pmdp)
        d = transition(pmdp, s, a)
        println("Transition from state ", s, " action ", a, " : ", d.vals, " ", d.probs)
    end
end















solver = ModelCheckingSolver(property = "!eaten U safe", solver=pomcpow)

policy = solve(solver, pomdp);

action(policy, b0)

using POMDPTools
using Random
using ParticleFilters

rng = MersenneTwister(1)
filter = SimpleParticleFilter(pomdp, LowVarianceResampler(1000))
b0 = initialize_belief(filter, initialstate_distribution(pomdp))
s0 = initialstate(pomdp, rng)
hr = HistoryRecorder(max_steps=100)
simulate(hr, pomdp, policy, filter, b0)





state_space = states(pmdp)
transition(pmdp, state_space[4], 2)

solve(sarsop, pmdp, pomdp_file_name="model.pomdpx")
