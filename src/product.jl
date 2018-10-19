# Build the product of an MDP/POMDP and a deterministic finite state automata 

struct ProductState{S, Q} 
    s::S
    q::Q
end

function Base.:(==)(a::ProductState{S, Q}, b::ProductState{S, Q}) where {S, Q}
    return a.s == b.s && a.q == b.q
end

function Base.hash(s::ProductState{S, Q}, h::UInt64) where {S, Q}
    return hash(s.s, hash(s.q, h))
end

mutable struct ProductMDP{S, A, Q, T} <: MDP{ProductState{S, Q}, A}
    problem::MDP{S, A}
    automata::Automata{Q, T}
    accepting_states::Set{ProductState{S, Q}} 
end

function ProductMDP(mdp::MDP{S, A}, automata::Automata{Q, T}) where {S, A, Q, T}
    return ProductMDP(mdp, automata, Set{ProductState{S, Q}}())
end

mutable struct ProductPOMDP{S, A, O, Q, T} <: POMDP{ProductState{S, Q}, A, O}
    problem::POMDP{S, A, O}
    automata::Automata{Q, T}
    accepting_states::Set{ProductState{S, Q}} 
end


function ProductPOMDP(pomdp::POMDP{S, A, O}, automata::Automata{Q, T}) where {S, A, O, Q, T}
    return ProductPOMDP(pomdp, automata, Set{ProductState{S, Q}}())
end


# should be implemented by the problem writer
"""
Returns the labels associated with state s 
labels(mdp::M, s) where {M <: Union{MDP,POMDP}}
"""
function labels end


# returns the set of accepting states
function accepting_states!(mdp::M; verbose::Bool=false) where {M <: Union{ProductMDP, ProductPOMDP}}
    MECs = maximal_end_components(mdp, verbose=verbose)
    state_space = states(mdp)
    mdp.accepting_states = Set{statetype(mdp)}()
    inf_q, fin_q = acceptance_condition(mdp.automata)
    verbose ? println("Extracting accepting states from MECs ... \n") : nothing
    for ec in MECs
        ec_states = Set(state_space[i].q for i in ec)
        if !isempty(intersect(ec_states, inf_q)) && isempty(intersect(ec_states, fin_q))
            for si in ec
                push!(mdp.accepting_states, state_space[si])
            end
        end
    end
    verbose ? println("Accepting states computed. \n") : nothing
    return mdp.accepting_states
end

# inherit functions from the MDP api

function POMDPs.reward(mdp::Union{ProductMDP, ProductPOMDP}, s::ProductState{S, Q}, a::A, sp::ProductState{S, Q}) where {S, A, Q}
    if sp ∈ mdp.accepting_states
        return 1.
    end
    return 0.0
end

function POMDPs.isterminal(mdp::Union{ProductMDP, ProductPOMDP}, s::ProductState{S, Q}) where {S, Q}
    if s ∈ mdp.accepting_states
        return true
    end
    return false
end

POMDPs.discount(problem::Union{ProductMDP, ProductPOMDP}) = 1.0

# in the product MDP, some transitions are "undefined" because the automata does not allow them.
# the transitions does not necessarily sums up to one!
function POMDPs.transition(problem::Union{ProductMDP, ProductPOMDP}, state::ProductState{S, Q}, action::A) where {S, A, Q}
    d = transition(problem.problem, state.s, action) # regular mdp transition 
    new_probs = Float64[]
    new_vals = Vector{statetype(problem)}()
    true_lab = ["t"]
    l = labels(problem.problem, state.s)
    for (sp, p) in weighted_iterator(d)
        if p == 0.
            continue
        end
        if has_transition(problem.automata, state.q, l)
            qp = transition(problem.automata, state.q, l)
            push!(new_probs, p)
            push!(new_vals, ProductState(sp, qp))
        elseif has_transition(problem.automata, state.q, true_lab)
            qp = transition(problem.automata, state.q, true_lab)
            push!(new_probs, p)
            push!(new_vals, ProductState(sp, qp))
        end
    end
    normalize!(new_probs, 1)
    return SparseCat{Vector{statetype(problem)}, Vector{Float64}}(new_vals, new_probs)
end


function POMDPs.initialstate_distribution(problem::Union{ProductMDP, ProductPOMDP})
    b0 = initialstate_distribution(problem.problem)
    new_probs = Float64[]
    new_vals = Vector{statetype(problem)}()
    q0 = problem.automata.initialstate
    for (s0, p) in weighted_iterator(b0)
        push!(new_vals, ProductState(s0, q0))
        push!(new_probs, p)
    end
    normalize!(new_probs, 1)
    return SparseCat{Vector{statetype(problem)}, Vector{Float64}}(new_vals, new_probs)
end

function POMDPs.states(problem::Union{ProductMDP, ProductPOMDP}) 
    S = statetype(problem.problem)
    Q = eltype(problem.automata.states)
    state_space = ProductState{S, Q}[]
    for s in ordered_states(problem.problem)
        for q in problem.automata.states
            push!(state_space, ProductState(s, q))
        end
    end
    return state_space
end

POMDPs.actions(problem::Union{ProductMDP, ProductPOMDP}) = actions(problem.problem)

POMDPs.n_states(problem::Union{ProductMDP, ProductPOMDP}) = n_states(problem.problem)*length(problem.automata.states)

POMDPs.n_actions(problem::Union{ProductMDP, ProductPOMDP}) = n_actions(problem.problem)

function POMDPs.stateindex(problem::Union{ProductMDP, ProductPOMDP}, s::S) where S 
    si = stateindex(problem.problem, s.s)
    qi = stateindex(problem.automata, s.q)
    return LinearIndices((length(problem.automata.states), n_states(problem.problem)))[qi, si]
end

POMDPs.statetype(p::Union{ProductMDP, ProductPOMDP}) = ProductState{statetype(p.problem), eltype(p.automata.states)}

POMDPs.actiontype(p::Union{ProductMDP, ProductPOMDP}) = actiontype(p.problem)

POMDPs.actionindex(p::Union{ProductMDP, ProductPOMDP}, a::A) where A = actionindex(p.problem, a) 

POMDPs.convert_a(T::Type{V}, a, p::Union{ProductMDP, ProductPOMDP}) where V<:AbstractArray = convert_a(T, a, p.problem)
POMDPs.convert_a(T::Type{A}, vec::V, p::Union{ProductMDP, ProductPOMDP}) where {A,V<:AbstractArray} = convert_a(T, vec, p.problem)

function POMDPs.convert_s(T::Type{Vector{Float64}}, s::ProductState{S,Int64}, p::Union{ProductMDP, ProductPOMDP}) where S
    v_mdp = convert_s(T, s.s, p.problem) # convert mdp state 
    v_autom = zeros(n_states(p.automata))
    v_autom = 1.0
    return cat(1, v_mdp, v_autom)
end

function POMDPs.convert_s(::Type{ProductState{S,Int64}}, vec::Vector{Float64}, p::Union{ProductMDP, ProductPOMDP}) where {S}
    v_mdp = vec[1:end-n_states(p.automata)]
    v_autom = vec[end-n_states(p.automata)+1:end]
    s = convert_s(S, v_mdp, p.problem)
    q = findfirst(v_autom)
    return ProductState(s, q)
end

## POMDP Only 

POMDPs.observation(p::ProductPOMDP, s::S) where S = observation(p.pomdp, s)
POMDPs.observation(p::ProductPOMDP, a::A, s::S) where {S,A} = observation(p.pomdp, a, s)
POMDPs.observation(p::ProductPOMDP, s::S, a::A, sp::S) where {S,A}= observation(p.pomdp, s, a, sp)
POMDPs.observations(p::ProductPOMDP) = observations(p.pomdp)
POMDPs.n_observations(p::ProductPOMDP) = n_observations(p.pomdp)
POMDPs.obsindex(p::ProductPOMDP, o::O) where O = obsindex(p.pomdp, o)

POMDPs.convert_o(T::Type{V}, o, p::ProductPOMDP) where V<:AbstractArray = convert_o(T, o, p.pomdp)
POMDPs.convert_o(T::Type{O}, vec::V, p::ProductPOMDP) where {O,V<:AbstractArray} = convert_o(T, vec, p.pomdp)
