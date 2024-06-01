#=
Blind GridWorld
The robot has a noisy measurement of its position, it is modeled
by a uniform distribution around the neighbor of the current state (diagonal included)
=#

using StaticArrays
using LinearAlgebra
using Random
using POMDPs
using POMDPModels
using POMDPTools
using Compose
using ColorSchemes
using Parameters

@with_kw struct BlindGridWorld <: POMDP{GWPos, Symbol, GWPos} #GWPos/Bool
    size::Tuple{Int64, Int64} = (10,10)
    exit::GWPos = GWPos(10,1)
    simple_gw::SimpleGridWorld = SimpleGridWorld(size=size, rewards=Dict(exit=>1.0), terminate_from=Set([exit]))
end

## States 

POMDPs.states(pomdp::BlindGridWorld) = states(pomdp.simple_gw)
POMDPs.stateindex(pomdp::BlindGridWorld, s::AbstractVector{Int}) = stateindex(pomdp.simple_gw, s)
POMDPs.initialstate(pomdp::BlindGridWorld) = uniform_belief(pomdp)

## Actions 

POMDPs.actions(pomdp::BlindGridWorld) = actions(pomdp.simple_gw)
POMDPs.actionindex(pomdp::BlindGridWorld, a::Symbol) = actionindex(pomdp.simple_gw, a)

## Transition

POMDPs.isterminal(m::BlindGridWorld, s::AbstractVector{Int}) = (s == m.exit || s == GWPos(-1,-1))
POMDPs.transition(pomdp::BlindGridWorld, s::AbstractVector{Int}, a::Symbol) = transition(pomdp.simple_gw, s, a)

## Observation 

POMDPs.observations(pomdp::BlindGridWorld) = states(pomdp)
POMDPs.obsindex(pomdp::BlindGridWorld, o) = stateindex(pomdp, o)
function POMDPs.initialobs(pomdp::BlindGridWorld, s) 
    ImplicitDistribution(s) do s, rng 
        return rand(rng, observation(pomdp, first(actions(pomdp)), s))
    end
end

const NEIGHBORS_DIRECTIONS = Set([GWPos(0,1), GWPos(0,-1), GWPos(-1,0), GWPos(1,0), 
                                  GWPos(1,1), GWPos(-1,1), GWPos(1,-1), GWPos(-1,-1)])

function POMDPs.observation(pomdp::BlindGridWorld, a::Symbol, sp::AbstractVector{Int})
    if sp == GWPos(-1,-1)
        return SparseCat(states(pomdp), normalize!(ones(length(states(pomdp))), 1))
    end

    neighbors = MVector{length(NEIGHBORS_DIRECTIONS) + 1, GWPos}(undef)
    neighbors[1] = sp

    probs = @MVector(ones(9)) 
    for (i, dir) in enumerate(NEIGHBORS_DIRECTIONS)
        neighbors[i+1] = sp + dir

        if !POMDPModels.inbounds(pomdp.simple_gw, neighbors[i+1]) # hit an edge and come back
            probs[i+1] = 0.
        end
    end
    normalize!(probs, 1)

    return SparseCat(neighbors, probs)
end

## Reward 
POMDPs.reward(pomdp::BlindGridWorld, s::GWPos) = reward(pomdp.simple_gw, s)
POMDPs.reward(pomdp::BlindGridWorld, s, a, sp) = reward(pomdp.simple_gw, s)
POMDPs.reward(pomdp::BlindGridWorld, s, a) = reward(pomdp.simple_gw, s)
POMDPs.discount(pomdp::BlindGridWorld) = 1.0

## helpers

function deterministic_belief(pomdp, s)
    b = zeros(length(states(pomdp)))
    si = stateindex(pomdp, s)
    b[si] = 1.0
    return DiscreteBelief(pomdp, b)
end

function POMDPs.isterminal(pomdp::ProductPOMDP, b::DiscreteBelief)
    belief_support = states(policy.problem)[findall(b.b .> 0)]
    if ProductState(GWPos(8,5),4) ∈ belief_support || ProductState(GWPos(3,7), 3) ∈ belief_support 
        return true
    end
    for s in belief_support
        if !isterminal(pomdp, s)
            return false 
        end
    end
    return true
end

## Rendering 

function tocolor(r::Float64, minr=0., maxr=1.0)
    frac = (r-minr)/(maxr-minr)
    return get(ColorSchemes.redgreensplit, frac)
end

function POMDPModels.render(blindmdp::BlindGridWorld, step::Union{NamedTuple,Dict};
                valuecolor = s -> reward(mdp, s),
                value = nothing,
                action = nothing,
                landmark = nothing,
                minr = 0.,
                maxr = 1.0,
               )
    mdp = blindmdp.simple_gw
    nx, ny = mdp.size
    cells = []
    vals = []
    acts = []
    landmarks = []
    for x in 1:nx, y in 1:ny
        clr = valuecolor !== nothing ? tocolor(valuecolor(GWPos(x,y)), minr, maxr) : RGB(1.0,1.0,1.0)
        ctx = POMDPModels.cell_ctx((x,y), mdp.size)
        cell = compose(ctx, rectangle(), fill(clr))
        if value !== nothing
            val = compose(ctx, text(0.5,0.5, round(value(GWPos(x,y)), digits=3), hcenter, vcenter))
            push!(vals, val)
        end
        
        if action !== nothing 
            act = actionarrow(ctx, action(GWPos(x,y)))
            push!(acts, act)
        end

        if landmark !== nothing 
            if landmark(GWPos(x,y))#haskey(landmark, GWPos(x,y))
                txt = string(LABELLED_STATES[GWPos(x,y)])
                # push!(landmarks, compose(ctx, text(0.5, 0.5, txt, hcenter, vcenter), circle(0.5, 0.5, 0.3), fill("purple")))
                push!(landmarks, compose(ctx, text(0.5, 0.5, txt, hcenter, vcenter)))
                # push!(landmarks, compose(ctx, text(0.5,0.5, landmark[GWPos(x,y)], hcenter, vcenter)))
            end
        end

        push!(cells, cell)
    end
    vals = compose(context(), vals...)
    acts = compose(context(), acts...)
    landmarks = compose(context(), landmarks...)
    grid = compose(context(), linewidth(1Compose.mm), stroke("gray"), cells...)
    outline = compose(context(), linewidth(1Compose.mm), rectangle())

    if haskey(step, :s)
        agent_ctx = POMDPModels.cell_ctx(step[:s], mdp.size)
        agent = compose(agent_ctx, circle(0.5, 0.5, 0.4), fill("orange"))
        if haskey(step, :a)
            agent = compose(agent, actionarrow(agent_ctx, step[:a]))
        end 
    else
        agent = nothing
    end
    
    sz = min(w,h)
    gw_ctx = context((w-sz)/2, (h-sz)/2, sz, sz)
    if value !== nothing
        gw_ctx = compose(gw_ctx, vals)
    end
    if action !== nothing 
        gw_ctx = compose(gw_ctx, acts)
    end
    if landmark !== nothing 
        gw_ctx = compose(gw_ctx, landmarks)
    end
    return compose(gw_ctx, agent, grid)
end

function actionarrow(ctx, act::Symbol)
    if act == :up 
        return compose(ctx, line([(0.5,0.5), (0.5, 0.35)]), stroke(["gray"]), arrow())
    elseif act == :down
        return compose(ctx, line([(0.5,0.5), (0.5, 0.65)]), stroke(["gray"]), arrow())
                        
    elseif act == :right
        return compose(ctx, line([(0.5,0.5), (0.65, 0.5)]), stroke(["gray"]), arrow())
                      
    elseif act == :left 
        return compose(ctx, line([(0.5,0.5), (0.35, 0.5)]), stroke(["gray"]), arrow())            
    end
end

function highlight_goodstates(ctx, blindmdp::BlindGridWorld, states::Vector{GWPos})
    mdp = blindmdp.simple_gw
    goodstates = []
    for s in states
        x, y = s
        cctx = POMDPModels.cell_ctx((x,y), mdp.size)
        push!(goodstates, compose(cctx, circle(), fill("purple")))
    end
    goodstates = compose(context(), goodstates...)
    compose(goodstates, ctx)
end
