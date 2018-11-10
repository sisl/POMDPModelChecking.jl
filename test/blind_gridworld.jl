# Blind GridWorld
# there is one exit the robot can only observe 1 if it is at the exit 
# it observes 0 otherwise
using StaticArrays
using Random
using POMDPs
using POMDPModels
using POMDPModelTools
using Compose
using ColorSchemes
using Parameters
using BeliefUpdaters

const GWPos = POMDPModels.GWPos

@with_kw struct BlindGridWorld <: POMDP{GWPos, Symbol, Bool}
    size::Tuple{Int64, Int64} = (10,10)
    exit::GWPos = GWPos(10,1)
    simple_gw::SimpleGridWorld = SimpleGridWorld(size=size, rewards=Dict(exit=>1.0), terminate_from=Set())
end

## States 

POMDPs.states(pomdp::BlindGridWorld) = states(pomdp.simple_gw)
POMDPs.n_states(pomdp::BlindGridWorld) = n_states(pomdp.simple_gw)
POMDPs.stateindex(pomdp::BlindGridWorld, s::AbstractVector{Int}) = stateindex(pomdp.simple_gw, s)
POMDPs.initialstate(pomdp::BlindGridWorld, rng::AbstractRNG) = initialstate(pomdp.simple_gw)
POMDPs.initialstate_distribution(pomdp::BlindGridWorld) = uniform_belief(pomdp)

## Actions 

POMDPs.actions(pomdp::BlindGridWorld) = actions(pomdp.simple_gw)
POMDPs.n_actions(pomdp::BlindGridWorld) = n_actions(pomdp.simple_gw)
POMDPs.actionindex(pomdp::BlindGridWorld, a::Symbol) = actionindex(pomdp.simple_gw, a)

## Transition

POMDPs.isterminal(m::BlindGridWorld, s::AbstractVector{Int}) = s == m.exit
POMDPs.transition(pomdp::BlindGridWorld, s::AbstractVector{Int}, a::Symbol) = transition(pomdp.simple_gw, s, a)

## Observation 

POMDPs.observations(pomdp::BlindGridWorld) = (false, true)
POMDPs.obsindex(pomdp::BlindGridWorld, s::Bool) = Int(s) + 1

function POMDPs.observation(pomdp::BlindGridWorld, a::Symbol, sp::AbstractVector{Int})
    if sp == pomdp.exit 
        return BoolDistribution(0.0)
    else
        return BoolDistribution(0.0)
    end
end

function POMDPModels.tocolor(r::Float64)
    minr = -1.0
    maxr = 1.0
    frac = (r-minr)/(maxr-minr)
    return get(ColorSchemes.redgreensplit, frac)
end

## Reward 
POMDPs.reward(pomdp::BlindGridWorld, s::GWPos) = reward(pomdp.simple_gw, s)
POMDPs.reward(pomdp::BlindGridWorld, s, a, sp) = reward(pomdp.simple_gw, s)
POMDPs.reward(pomdp::BlindGridWorld, s, a) = reward(pomdp.simple_gw, s)
POMDPs.discount(pomdp::BlindGridWorld) = 1.0


## Render 

function POMDPModels.render(mdp::SimpleGridWorld, step::Union{NamedTuple,Dict};
                color = s->reward(mdp, s)
               )

    nx, ny = mdp.size
    cells = []
    vals = []
    for x in 1:nx, y in 1:ny
        clr = POMDPModels.tocolor(color(GWPos(x,y)))
        ctx = POMDPModels.cell_ctx((x,y), mdp.size)
        cell = compose(ctx, rectangle(), fill(clr))
        val = compose(ctx, text(0.5,0.5, round(color(GWPos(x,y)), digits=3), hcenter, vcenter))
        push!(vals, val)
        push!(cells, cell)
    end
    vals = compose(context(), vals...)
    grid = compose(context(), linewidth(1Compose.mm), stroke("gray"), cells...)
    outline = compose(context(), linewidth(1Compose.mm), rectangle())

    if haskey(step, :s)
        agent_ctx = POMDPModels.cell_ctx(step[:s], mdp.size)
        agent = compose(agent_ctx, circle(0.5, 0.5, 0.4), fill("orange"))
    else
        agent = nothing
    end
    
    sz = min(w,h)
    return compose(context((w-sz)/2, (h-sz)/2, sz, sz), agent, vals, grid)
end