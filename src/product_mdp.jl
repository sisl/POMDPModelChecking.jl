# Build the product of an MDP and a Buchi automata 

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
    mdp::MDP{S, A}
    automata::Automata{Q, T}
    accepting_states::Set{ProductState{S, Q}} 
end

function ProductMDP(mdp::MDP{S, A}, automata::Automata{Q, T}) where {S, A, Q, T}
    return ProductMDP(mdp, automata, Set{ProductState{S, Q}}())
end

# should be implemented by the problem writer
"""
Returns the labels associated with state s 
labels(mdp::M, s) where {M <: Union{MDP,POMDP}}
"""
function labels end

# returns the set of accepting states
function accepting_states!(mdp::ProductMDP{S, A, Q, T}; verbose::Bool=false) where {S, A, Q, T}
    MECs = maximal_end_components(mdp, verbose=verbose)
    state_space = states(mdp)
    mdp.accepting_states = Set{ProductState{S, Q}}()
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

function POMDPs.reward(mdp::ProductMDP{S, A, Q, T}, s::ProductState{S, Q}, a::A, sp::ProductState{S, Q}) where {S, A, Q, T}
    if sp ∈ mdp.accepting_states
        return 1.
    end
    return 0.0
end

function POMDPs.isterminal(mdp::ProductMDP{S, A, Q, T}, s::ProductState{S, Q}) where {S, A, Q, T}
    if s ∈ mdp.accepting_states
        return true
    end
    return false
end

POMDPs.discount(problem::ProductMDP) = 1.0

# in the product MDP, some transitions are "undefined" because the automata does not allow them.
# the transitions does not necessarily sums up to one!
function POMDPs.transition(problem::ProductMDP{S, A, Q, T}, state::ProductState{S, Q}, action::A) where {S, A, Q, T}
    d = transition(problem.mdp, state.s, action) # regular mdp transition 
    new_probs = Float64[]
    new_vals = Vector{ProductState{S, Q}}()
    true_lab = ["t"]
    l = labels(problem.mdp, state.s)
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
    return SparseCat{Vector{ProductState{S, Q}}, Vector{Float64}}(new_vals, new_probs)
end


function POMDPs.initialstate_distribution(problem::ProductMDP{S, A, Q, T}) where {S, A, Q, T}
    b0 = initialstate_distribution(problem.mdp)
    new_probs = Float64[]
    new_vals = Vector{ProductState{S, Q}}()
    q0 = problem.automata.initialstate
    for (s0, p) in weighted_iterator(b0)
        push!(new_vals, ProductState(s0, q0))
        push!(new_probs, p)
    end
    normalize!(new_probs, 1)
    return SparseCat{Vector{ProductState{S, Q}}, Vector{Float64}}(new_vals, new_probs)
end

function POMDPs.states(problem::ProductMDP) 
    S = statetype(problem.mdp)
    Q = eltype(problem.automata.states)
    state_space = ProductState{S, Q}[]
    for s in ordered_states(problem.mdp)
        for q in problem.automata.states
            push!(state_space, ProductState(s, q))
        end
    end
    return state_space
end

POMDPs.actions(problem::ProductMDP) = actions(problem.mdp)

POMDPs.n_states(problem::ProductMDP) = n_states(problem.mdp)*length(problem.automata.states)

POMDPs.n_actions(problem::ProductMDP) = n_actions(problem.mdp)

function POMDPs.stateindex(problem::ProductMDP, s::S) where S <: ProductState
    si = stateindex(problem.mdp, s.s)
    qi = stateindex(problem.automata, s.q)
    return LinearIndices((length(problem.automata.states), n_states(problem.mdp)))[qi, si]
end

POMDPs.statetype(p::ProductMDP) = ProductState{statetype(p.mdp), eltype(p.automata.states)}

POMDPs.actiontype(p::ProductMDP) = actiontype(p.mdp)

POMDPs.actionindex(p::ProductMDP, a::A) where A = actionindex(p.mdp, a) 

POMDPs.convert_a(T::Type{V}, a, p::ProductMDP) where V<:AbstractArray = convert_a(T, a, p.mdp)
POMDPs.convert_a(T::Type{A}, vec::V, p::ProductMDP) where {A,V<:AbstractArray} = convert_a(T, vec, p.mdp)

function POMDPs.convert_s(T::Type{Vector{Float64}}, s::ProductState{S,Int64}, p::ProductMDP) where S
    v_mdp = convert_s(T, s.s, p.mdp) # convert mdp state 
    v_autom = zeros(n_states(p.automata))
    v_autom = 1.0
    return cat(1, v_mdp, v_autom)
end

function POMDPs.convert_s(::Type{ProductState{S,Int64}}, vec::Vector{Float64}, p::ProductMDP) where {S}
    v_mdp = vec[1:end-n_states(p.automata)]
    v_autom = vec[end-n_states(p.automata)+1:end]
    s = convert_s(S, v_mdp, p.mdp)
    q = findfirst(v_autom)
    return ProductState(s, q)
end

# POMDPs.convert_s(::Type{V}, s, problem::Union{MDP,POMDP}) where V<:AbstractArray
# POMDPs.convert_s(::Type{S}, vec::V, problem::Union{MDP,POMDP}) where {S,V<:AbstractArray}
# POMDPs.convert_a(::Type{V}, a, problem::Union{MDP,POMDP}) where V<:AbstractArray
# POMDPs.convert_a(::Type{A}, vec::V, problem::Union{MDP,POMDP}) where {A,V<:AbstractArray}