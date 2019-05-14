using Distributed
addprocs(2)

@everywhere begin 
    using Random
    using POMDPs
    using Spot
    using POMDPModelChecking
    import Cairo
    using POMDPModelTools
    using POMDPModels
    using POMDPSimulators
    using POMDPGifs
    using ProgressMeter
    using BeliefUpdaters
    using SARSOP
    using FileIO
    using JLD2

    include("blind_gridworld.jl")

    const LABELLED_STATES = Dict(GWPos(4,3) => :crash,  GWPos(4,6)=>:crash, GWPos(9,3)=>:a, GWPos(8,8)=>:b)

    function POMDPModelChecking.labels(mdp::SimpleGridWorld, s, a)
        if haskey(LABELLED_STATES, s)
            return tuple(LABELLED_STATES[s])
        else
            return ()
        end
    end

    include("mc_simulation.jl")

end


prop = ltl"!crash U a & !crash U b"

mdp = SimpleGridWorld(rewards=Dict(GWPos(9,3)=>10.0), terminate_from=Set([]))

POMDPModelChecking.labels(pomdp::BlindGridWorld, s, a) = labels(pomdp.simple_gw, s, a)
pomdp = BlindGridWorld(exit=GWPos(4,3), simple_gw = mdp)

sarsop = SARSOPSolver(precision=1e-2, timeout=10.0)
solver = ModelCheckingSolver(solver=sarsop, property=prop, verbose=true)

policy = solve(solver, pomdp)

UBOUND = 0.914258
LBOUND = 0.900412

successes, mu, sig = many_sims(policy.problem, policy, 500);


using Plots
pgfplots()

p = plot(mu, label="MC estimate", linewidth=3);
plot!(1:length(mu), LBOUND*ones(length(mu)), c="black", linestyle=:dot, label="SARSOP lower bound");
plot!(1:length(mu), UBOUND*ones(length(mu)), c="black", linestyle=:dash, label="SARSOP upper bound", legend=:bottom);
plot!(label=nothing);

savefig(p, "succ.png")

#=

up = DiscreteUpdater(policy.problem)
b0 = initialize_belief(up, initialstate_distribution(policy.problem))
@show value(policy, b0)

policy.memory = 1
ctx1 = POMDPModels.render(mdp, Dict(), valuecolor=s->value(policy, deterministic_belief(policy.problem, ProductState(s, policy.memory))), 
                                      action=s->action(policy, deterministic_belief(policy.problem, ProductState(s, policy.memory))), 
                                      landmark = s -> s ∈ keys(LABELLED_STATES));
ctx1 |> PNG("gw.png")

## simulation 

up = DiscreteUpdater(policy.problem)
b0 = initialize_belief(up, initialstate_distribution(policy.problem))
hr = HistoryRecorder(max_steps=50)
hist = simulate(hr, policy.problem, policy, up, b0)
prod_state_hist = hist.state_hist
state_hist = [s.s for s in hist.state_hist];
hist2 = POMDPHistory(state_hist, [getfield(hist, f) for f in fieldnames(POMDPHistory) if f != :state_hist]...);
makegif(pomdp, hist2, filename="bgw.gif", spec="(s,a)")

pomdp = BlindGridWorld()



sarsop = SARSOPSolver(precision=1e-3)
solver = ModelCheckingSolver(solver=sarsop, property=prop, verbose=true)

solve(solver, pomdp)



automata = DeterministicRabinAutomata(prop)

label_to_array(prop)

translator = LTLTranslator(deterministic=true, buchi=true, state_based_acceptance=true)
aut = translate(translator, prop)

aut = SpotAutomata(aut)

get_rabin_acceptance(aut)

dra = to_generalized_rabin(aut)

get_rabin_acceptance(dra)

dra.a.to_str()
get_rabin_acceptance(dra)

states = 1:num_states(dra)
initial_state = get_init_state_number(dra) 
APs = atomic_propositions(dra)
edgelist, labels = get_edges_labels(dra)

conditions = label_to_array.(labels)

label_to_array(labels[1])

=#