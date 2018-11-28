using MDPModelChecking
using POMDPs
using POMDPModels
using DiscreteValueIteration
using QMDP
using Test

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
