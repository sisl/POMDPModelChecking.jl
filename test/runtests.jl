using POMDPModelChecking
using POMDPs
using POMDPModels
using DiscreteValueIteration
using QMDP
using POMDPTesting
using Spot
using Test

# test state indexing 
function test_stateindexing(problem::Union{ProductMDP, ProductPOMDP})
    for (i,s) in enumerate(states(problem))
        si = stateindex(problem, s)
        if si != i
            return false
        end
    end
    return true
end

@testset "MDP reachability" begin 
    mdp = SimpleGridWorld(size=(10,10), terminate_from=Set([GWPos(9,3), GWPos(4,3)]), tprob=0.7)
    reach = Set([GWPos(10,1)])
    avoid = mdp.terminate_from
    solver = ReachabilitySolver(reach, avoid, ValueIterationSolver())
    policy = solve(solver, mdp)
    @test value(policy, GWPos(10,1)) == 1.
    @test value(policy, GWPos(4,3)) == 0.
    @test value(policy, GWPos(9,3)) == 0.
    @test action(policy, GWPos(9,1)) == :right
end

@testset "POMDP reachability" begin 
    include("blind_gridworld.jl")
    pomdp = BlindGridWorld(size=(10,10), 
                           exit=GWPos(10,1), 
                           simple_gw=SimpleGridWorld(size=(10,10), terminate_from=Set([GWPos(9,3), GWPos(4,3)]), tprob=0.7))
    reach = Set([GWPos(10,1)])
    avoid = pomdp.simple_gw.terminate_from
    solver = ReachabilitySolver(reach, avoid, QMDPSolver())
    policy = solve(solver, pomdp)
    @test value(policy, deterministic_belief(pomdp, GWPos(10,1))) == 0. # terminal state in QMDP value function is 0.
    @test value(policy, deterministic_belief(pomdp, GWPos(4,3))) == 0.
    @test value(policy, deterministic_belief(pomdp, GWPos(9,3))) == 0.
    @test action(policy, deterministic_belief(pomdp, GWPos(9,1))) == :right
end

@testset "Product" begin 
    mdp = SimpleGridWorld(size=(10,10), terminate_from=Set([]), tprob=0.7);

    LABELLED_STATES = Dict(GWPos(3,7) => :a, GWPos(8,5) => :b, GWPos(4,3) => :c)

    function POMDPModelChecking.labels(mdp::SimpleGridWorld, s, a)
        if haskey(LABELLED_STATES, s)
            return tuple(LABELLED_STATES[s])
        else
            return ()
        end
    end

    dra = DeterministicRabinAutomata(ltl"(!c U b) & (!c U a)")
    pmdp = ProductMDP(mdp, dra, Set{ProductState{GWPos, Int64}}(), ProductState(GWPos(1,1), -1))
    state_space = states(pmdp)
    action_space = actions(pmdp)
    @test discount(pmdp) == 1.0
    @test n_states(pmdp) == n_states(mdp)*num_states(dra) + 1
    @test n_states(pmdp) == length(state_space)
    @test n_actions(pmdp) == length(action_space)
    @test statetype(pmdp) == ProductState{GWPos, Int64}
    @test actiontype(pmdp) == Symbol
    @test test_stateindexing(pmdp)
    trans_prob_consistency_check(pmdp) 

    include("blind_gridworld.jl")
    POMDPModelChecking.labels(pomdp::BlindGridWorld, s, a) = labels(pomdp.simple_gw, s, a)
    pomdp = BlindGridWorld(size=(10,10), 
                           exit=GWPos(10,1), 
                           simple_gw=SimpleGridWorld(size=(10,10), terminate_from=Set([GWPos(9,3), GWPos(4,3)]), tprob=0.7))
    ppomdp = ProductPOMDP(pomdp, dra, Set{ProductState{GWPos, Int64}}(), ProductState(GWPos(1,1), -1))
    state_space = states(ppomdp)
    action_space = actions(ppomdp)
    observation_space = observations(ppomdp)
    @test discount(ppomdp) == 1.0
    @test n_states(ppomdp) == n_states(pomdp)*num_states(dra) + 1
    @test n_states(ppomdp) == length(state_space)
    @test n_actions(ppomdp) == length(action_space)
    @test statetype(ppomdp) == ProductState{GWPos, Int64}
    @test actiontype(ppomdp) == Symbol
    @test n_observations(ppomdp) == length(observation_space)
    @test n_observations(ppomdp) == n_observations(pomdp)
    @test obstype(ppomdp) == obstype(pomdp)
    @test test_stateindexing(ppomdp)
    trans_prob_consistency_check(ppomdp) 
    obs_prob_consistency_check(ppomdp)
end

@testset begin "MDP Model Checking"
    mdp = SimpleGridWorld(size=(10,10), terminate_from=Set([]), tprob=0.7);

    LABELLED_STATES = Dict(GWPos(3,7) => :a, GWPos(8,5) => :b, GWPos(4,3) => :c)

    function POMDPModelChecking.labels(mdp::SimpleGridWorld, s, a)
        if haskey(LABELLED_STATES, s)
            return tuple(LABELLED_STATES[s])
        else
            return ()
        end
    end

    solver = ModelCheckingSolver(property=ltl"(!c U b) & (!c U a)", solver=ValueIterationSolver(), verbose=true)
    policy = solve(solver, mdp)
end