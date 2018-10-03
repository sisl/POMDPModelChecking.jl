# Build the product of a POMDP and a Buchi automata 


mutable struct ProductPOMDP{S, A, O, Q, T} <: POMDP{ProductState{S, Q}, A, O}
    pomdp::POMDP{S, A, O}
    automata::Automata{Q, T}
    accepting_states::Set{ProductState{S, Q}} 
end


function ProductPOMDP(pomdp::POMDP{S, A, O}, automata::Automata{Q, T}) where {S, A, O, Q, T}
    return ProductPOMDP(pomdp, automata, Set{ProductState{S, Q}}())
end

# returns the set of accepting states
function accepting_states!(pomdp::ProductPOMDP{S, A, O, Q, T}; verbose::Bool=false) where {S, A, O, Q, T}
    MECs = maximal_end_components(pomdp, verbose=verbose)
    state_space = states(pomdp)
    pomdp.accepting_states = Set{ProductState{S, Q}}()
    inf_q, fin_q = acceptance_condition(pomdp.automata)
    for ec in MECs
        ec_states = Set(state_space[i].q for i in ec)
        if !isempty(intersect(ec_states, inf_q)) && isempty(intersect(ec_states, fin_q))
            for si in ec
                push!(pomdp.accepting_states, state_space[si])
            end
        end
    end
    return pomdp.accepting_states
end

# inherit functions from the MDP api
function POMDPs.reward(pomdp::ProductPOMDP{S, A, O, Q, T}, s::ProductState{S, Q}, a::A, sp::ProductState{S, Q}) where {S, A, O, Q, T}
    if sp ∈ pomdp.accepting_states
        return 1.
    end
    return 0.0
end

function POMDPs.isterminal(pomdp::ProductPOMDP{S, A, O, Q, T}, s::ProductState{S, Q}) where {S, A, O, Q, T}
    if s ∈ pomdp.accepting_states
        return true
    end
    return false
end

POMDPs.discount(problem::ProductPOMDP) = 1.0

# in the product MDP, some transitions are "undefined" because the automata does not allow them.
# the transitions does not necessarily sums up to one!
function POMDPs.transition(problem::ProductPOMDP{S, A, O, Q, T}, state::ProductState{S, Q}, action::A) where {S, A, O, Q, T}
    d = transition(problem.pomdp, state.s, action) # regular pomdp transition 
    new_probs = Float64[]
    new_vals = Vector{ProductState{S, Q}}()
    true_lab = ["t"]
    l = labels(problem.pomdp, state.s)
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


function POMDPs.initialstate_distribution(problem::ProductPOMDP{S, A, O, Q, T}) where {S, A, O, Q, T}
    b0 = initialstate_distribution(problem.pomdp)
    new_probs = Float64[]
    new_vals = Vector{ProductState{S, Q}}(undef,0)
    q0 = problem.automata.initial_state
    for (s0, p) in weighted_iterator(b0)
        push!(new_vals, ProductState(s0, q0))
        push!(new_probs, p)
    end
    normalize!(new_probs, 1)
    return SparseCat{Vector{ProductState{S, Q}}, Vector{Float64}}(new_vals, new_probs)
end

function POMDPs.states(problem::ProductPOMDP) 
    S = statetype(problem.pomdp)
    Q = eltype(problem.automata.states)
    state_space = ProductState{S, Q}[]
    for s in ordered_states(problem.pomdp)
        for q in problem.automata.states
            push!(state_space, ProductState(s, q))
        end
    end
    return state_space
end

POMDPs.actions(problem::ProductPOMDP) = actions(problem.pomdp)

POMDPs.n_states(problem::ProductPOMDP) = n_states(problem.pomdp)*length(problem.automata.states)

POMDPs.n_actions(problem::ProductPOMDP) = n_actions(problem.pomdp)

function POMDPs.stateindex(problem::ProductPOMDP, s::S) where S <: ProductState
    si = stateindex(problem.pomdp, s.s)
    qi = stateindex(problem.automata, s.q)
    return LinearIndices((length(problem.automata.states), n_states(problem.pomdp)))[qi, si]
end

POMDPs.statetype(p::ProductPOMDP) = ProductState{statetype(p.pomdp), eltype(p.automata.states)}

POMDPs.actiontype(p::ProductPOMDP) = actiontype(p.pomdp)

POMDPs.actionindex(p::ProductPOMDP, a::A)  where A = actionindex(p.pomdp, a)

POMDPs.observation(p::ProductPOMDP, s::S) where S = observation(p.pomdp, s)
POMDPs.observation(p::ProductPOMDP, a::A, s::S) where {S,A} = observation(p.pomdp, a, s)
POMDPs.observation(p::ProductPOMDP, s::S, a::A, sp::S) where {S,A}= observation(p.pomdp, s, a, sp)
POMDPs.observations(p::ProductPOMDP) = observations(p.pomdp)
POMDPs.n_observations(p::ProductPOMDP) = n_observations(p.pomdp)
POMDPs.obsindex(p::ProductPOMDP, o::O) where O = obsindex(p.pomdp, o)

POMDPs.convert_a(T::Type{V}, a, p::ProductPOMDP) where V<:AbstractArray = convert_a(T, a, p.pomdp)
POMDPs.convert_a(T::Type{A}, vec::V, p::ProductPOMDP) where {A,V<:AbstractArray} = convert_a(T, vec, p.pomdp)
POMDPs.convert_o(T::Type{V}, o, p::ProductPOMDP) where V<:AbstractArray = convert_o(T, o, p.pomdp)
POMDPs.convert_o(T::Type{O}, vec::V, p::ProductPOMDP) where {O,V<:AbstractArray} = convert_o(T, vec, p.pomdp)

function POMDPs.convert_s(T::Type{Vector{Float64}}, s::ProductState{S,Int64}, p::ProductPOMDP) where S
    v_pomdp = convert_s(T, s.s, p.pomdp) # convert pomdp state 
    v_autom = zeros(n_states(p.automata))
    v_autom = 1.0
    return cat(1, v_pomdp, v_autom)
end

function POMDPs.convert_s(::Type{ProductState{S,Int64}}, vec::Vector{Float64}, p::ProductPOMDP) where S
    v_pomdp = vec[1:end-n_states(p.automata)]
    v_autom = vec[end-n_states(p.automata)+1:end]
    s = convert_s(S, v_pomdp, p.pomdp)
    q = findfirst(v_autom)
    return ProductState(s, q)
end




# POMDPs.convert_s(::Type{V}, s, problem::Union{MDP,POMDP}) where V<:AbstractArray
# POMDPs.convert_s(::Type{S}, vec::V, problem::Union{MDP,POMDP}) where {S,V<:AbstractArray}
# POMDPs.convert_a(::Type{V}, a, problem::Union{MDP,POMDP}) where V<:AbstractArray
# POMDPs.convert_a(::Type{A}, vec::V, problem::Union{MDP,POMDP}) where {A,V<:AbstractArray}