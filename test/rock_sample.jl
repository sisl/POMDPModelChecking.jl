using Revise
using Random
using POMDPs
using Spot
using POMDPModelChecking
using BeliefUpdaters
using SARSOP
using RockSample
using POMDPSimulators
import Cairo
using POMDPGifs
using ProgressMeter
using Statistics


# pomdp = RockSamplePOMDP{2}(map_size=(4,4), 
#                            rocks_positions=[(2,3), (3,1)])


pomdp = RockSamplePOMDP{3}(map_size=(5,5),
                            rocks_positions=[(2,3), (4,4), (4,2)])

# pomdp = RockSamplePOMDP{8}(map_size=(7,7), 
#                            rocks_positions=[(1,2), (2,8), (3,1), (3,5), (4,2), (4,5), (6,6), (7,4)])


@show n_states(pomdp)
@show n_actions(pomdp)
@show n_observations(pomdp)

## Probability of getting at least one good rock 

function POMDPModelChecking.labels(pomdp::RockSamplePOMDP, s::RSState, a::Int64)
    if a == RockSample.BASIC_ACTIONS_DICT[:sample] && in(s.pos, pomdp.rocks_positions) # sample 
        rock_ind = findfirst(isequal(s.pos), pomdp.rocks_positions) # slow ?
        if s.rocks[rock_ind]
            # return ()
            return (:good_rock,)
        else
            # return (:bad_rock,)
        end
    end
    if isterminal(pomdp, s)
        return (:exit,)
        # return ()
    end
    return ()
end

# prop = ltl"G !bad_rock"
prop = ltl"F good_rock & F exit"
# prop = ltl" F good_rock & G !bad_rock & F exit" 
# prop = ltl" (!bad_rock U good_rock) && (!bad_rock U exit)" 

run(`rm model.pomdpx`)
solver = ModelCheckingSolver(property = prop, 
                      solver=SARSOPSolver(precision=1e-3), verbose=true)

policy = solve(solver, pomdp);



## visualize policy
rng = MersenneTwister(2)
up = DiscreteUpdater(policy.problem)
b0 = initialize_belief(up, initialstate_distribution(policy.problem))
hr = HistoryRecorder(max_steps=50)
hist = simulate(hr, policy.problem, policy, up, b0);
prod_state_hist = hist.state_hist
state_hist = [s.s for s in hist.state_hist];
hist = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
makegif(pomdp, hist, filename="test.gif", spec="(s,a)")

#=

## Monte carlo simulation
function sim(policy)
    n_sim = 300
    successes = zeros(n_sim)
    fails = zeros(n_sim)
    @showprogress for i=1:n_sim
        up = DiscreteUpdater(policy.problem)
        b0 = initialize_belief(up, initialstate_distribution(policy.problem))
        hr = HistoryRecorder(max_steps=50)
        hist = simulate(hr, policy.problem, policy, up, b0)
        println("discounted reward ", discounted_reward(hist))
        println("undiscounted_reward", undiscounted_reward(hist))
        mu_succ, std_mu_succ = running_stats(successes[1:i])
        println("mean: ", mu_succ[end])
        successes[i] = undiscounted_reward(hist) > 0.
        fails[i] = undiscounted_reward(hist) <= 0.
    end
    return successes, fails
end

successes, fails = sim(policy)

function running_stats(vec)
    mu = mean.(vec[1:i] for i=1:length(vec))
    std_mu = std.(mu[1:i] for i=1:length(vec))./collect(1:length(vec))
    return mu, std_mu
end

mu_succ, std_mu_succ = running_stats(successes)
# mu_fail, std_mu_fail = running_stats(fails)

LBOUND = 0.874038; UBOUND=  0.874175


using Plots
pgfplots()

p = plot(mu_succ, yerror=std_mu_succ, label="MC estimate", legend=:bottom, linewidth=3);
plot!(1:length(mu_succ), LBOUND*ones(length(mu_succ)), c="black", linestyle=:dot, label="SARSOP lower bound");
plot!(1:length(mu_succ), UBOUND*ones(length(mu_succ)), c="black", linestyle=:dash, label="SARSOP upper bound")


savefig(p, "succ.png")



dra = DeterministicRabinAutomata(prop)
sink_state = ProductState(first(states(pomdp)), -1)
pmdp = ProductPOMDP(pomdp, dra, sink_state)

mecs = maximal_end_components(pmdp, verbose=true)

states(pmdp)[801]

s = ProductState(pomdp.terminal_state, 1)
labels(pmdp.problem, s.s, 1)

nextstate(pmdp.automata, 1, (:exit,))

using LightGraphs, MetaGraphs
dra = pmdp.automata

nextstate(dra, 1, (:exit,))

lab = (:exit,)

neighbors(dra.transition, 1)

edge_it = filter_edges(dra.transition, 
                        (g, e) -> (src(e) == 1) && (lab ∈ props(g, e)[:cond] || (:true_constant,) ∈ props(g, e)[:cond]))

collect(edge_it)

props(dra.transition, 1, 1)

si = stateindex(pmdp, s)

for a in actions(pmdp) 
    println(length(support(transition(pmdp, s, a))))
    println(first(support(transition(pmdp, s, a))))
end

for (i, mec) in enumerate(mecs)
    if si in mec
        println(i)
    end
end


last(states(pmdp))


dra.acc_sets

dra = DeterministicRabinAutomata(prop)

translator = LTLTranslator(deterministic=true, buchi=true, state_based_acceptance=true)
aut = translate(translator, prop)



dra = SpotAutomata(aut)
@assert is_deterministic(dra)
states = 1:num_states(dra)
initial_state = get_init_state_number(dra) 
APs = atomic_propositions(dra)
edgelist, llabels = get_edges_labels(dra)
sdg = SimpleDiGraph(num_states(dra))
for e in edgelist
    add_edge!(sdg, e)
end
transition = MetaDiGraph(sdg)
conditions = label_to_array.(llabels)

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

=#