using Revise
using POMDPs
using POMDPModelTools
using Compose
import Cairo

using DroneSurveillance

pomdp = DroneSurveillancePOMDP(size=(5,5))

s0 = DSState([2,2],[3,3])
c = render(pomdp, (s=s0,))

c |> PDF("dronesurveillance.pdf")

using RockSample
using Random

pomdp = RockSamplePOMDP{3}(rocks_positions=[[4,2], [2,3], [4, 4]])

s0 = initialstate(pomdp, MersenneTwister(1))

c = render(pomdp, (s=s0,a=1))

c |> PDF("rocksample.pdf")

using POMDPModels
using POMDPModelChecking
using Colors
include("blind_gridworld.jl")

mdp = SimpleGridWorld(size=(5,5), rewards=Dict(GWPos(9,3)=>10.0), terminate_from=Set([]))


const LABELLED_STATES = Dict(GWPos(2,3) => :C,  GWPos(4,4)=>:A, GWPos(5,2)=>:B)

function POMDPModelChecking.labels(mdp::SimpleGridWorld, s, a)
    if haskey(LABELLED_STATES, s)
        return tuple(LABELLED_STATES[s])
    else
        return ()
    end
end

pomdp = BlindGridWorld(exit=GWPos(4,3), simple_gw = mdp)

c = render(mdp, (s=GWPos(1,1),), valuecolor=nothing, landmark = s -> s in keys(LABELLED_STATES));

c |> PDF("gridworld.pdf")
