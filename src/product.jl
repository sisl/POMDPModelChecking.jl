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

mutable struct ProductMDP{S, A, Q <: Int, R <: AbstractAutomata} <: MDP{ProductState{S, Q}, A}
    problem::MDP{S, A}
    automata::R
    accepting_states::Set{ProductState{S, Q}} 
    sink_state::ProductState{S, Q}
end

function ProductMDP(mdp::MDP{S}, automata::AbstractAutomata, sink_state::ProductState{S,Q}) where {S,Q}
    ProductMDP(mdp, automata, Set{ProductState{S, Q}}(), sink_state)
end

mutable struct ProductPOMDP{S, A, O, Q <: Int, R <: AbstractAutomata} <: POMDP{ProductState{S, Q}, A, O}
    problem::POMDP{S, A, O}
    automata::R
    accepting_states::Set{ProductState{S, Q}} 
    sink_state::ProductState{S, Q}
end

function ProductPOMDP(pomdp::POMDP{S}, automata::AbstractAutomata, sink_state::ProductState{S,Q}) where {S,Q}
    ProductPOMDP(pomdp, automata, Set{ProductState{S, Q}}(), sink_state)
end

# should be implemented by the problem writer
"""
Returns the labels associated with state s 
For each state, it should return a list of atomic proposition that evaluate to true, all the other propositions are assumed false.
labels(mdp::M, s, a) where {M <: Union{MDP,POMDP}}
"""
function labels end


# returns the set of accepting states
function accepting_states!(mdp::M; verbose::Bool=false) where {M <: Union{ProductMDP, ProductPOMDP}}
    MECs = maximal_end_components(mdp, verbose=verbose)
    state_space = states(mdp)
    mdp.accepting_states = Set{statetype(mdp)}()
    fin_inf_sets = get_rabin_acceptance(mdp.automata)
    verbose ? println("Extracting accepting states from MECs ... \n") : nothing
    for ec in MECs
        ec_states = Set(state_space[i].q for i in ec)
        for (fin_q, inf_q) in fin_inf_sets
            if !isempty(intersect(ec_states, inf_q)) && isempty(intersect(ec_states, fin_q))
                for si in ec
                    push!(mdp.accepting_states, state_space[si])
                end
            end
        end
    end
    verbose ? println("Accepting states computed. \n") : nothing
    return mdp.accepting_states
end

# # inherit functions from the MDP api

function POMDPs.reward(mdp::Union{ProductMDP, ProductPOMDP}, s::ProductState{S, Q}, a::A, sp::ProductState{S, Q}) where {S, A, Q}
    if sp ∈ mdp.accepting_states
        return 1.
    end
    return 0.0
end

POMDPs.reward(mdp::Union{ProductMDP, ProductPOMDP}, s::ProductState{S, Q}, a::A) where {S, A, Q} = reward(mdp, s, a, s)

function POMDPs.isterminal(mdp::Union{ProductMDP, ProductPOMDP}, s::ProductState{S, Q}) where {S, Q}
    if s ∈ mdp.accepting_states || s == mdp.sink_state
        return true
    end
    return false
end

POMDPs.discount(problem::Union{ProductMDP, ProductPOMDP}) = 0.9

# in the product MDP, some transitions are "undefined" because the automata does not allow them.
# the transitions does not necessarily sums up to one!
function POMDPs.transition(problem::Union{ProductMDP, ProductPOMDP}, state::ProductState{S, Q}, action::A) where {S, A, Q}
    d = transition(problem.problem, state.s, action) # regular mdp transition 
    if state ∈ problem.accepting_states || state == problem.sink_state
        return SparseCat{Vector{statetype(problem)}, Vector{Float64}}([problem.sink_state], [1.0])
    end
    l = labels(problem.problem, state.s, action)
    qp = nextstate(problem.automata, state.q, l)
    if qp != nothing 
        new_vals = Vector{ProductState{S,Q}}(undef, length(support(d)))
        new_probs = Vector{Float64}(undef, length(support(d)))
        for (i, sp) in enumerate(support(d))
            new_vals[i] = ProductState(sp,qp)
            new_probs[i] = pdf(d, sp)
        end
        return SparseCat{Vector{ProductState{S,Q}}, Vector{Float64}}(new_vals, new_probs)
    # for (sp, p) in weighted_iterator(d)
    #     if p == 0.
    #         continue
    #     end
    #     # l = labels(problem.problem, sp, action)
        
    #     if qp != nothing
    #         push!(new_probs, p)
    #         push!(new_vals, ProductState(sp, qp))
    #     end
    # end
    else
        return SparseCat{Vector{statetype(problem)}, Vector{Float64}}([problem.sink_state], [1.0])
    end
    # normalize!(new_probs, 1)
    # return SparseCat{Vector{statetype(problem)}, Vector{Float64}}(new_vals, new_probs)
end


function POMDPs.initialstate_distribution(problem::Union{ProductMDP, ProductPOMDP})
    b0 = initialstate_distribution(problem.problem)
    new_probs = Float64[]
    new_vals = Vector{statetype(problem)}()
    q0 = get_init_state_number(problem.automata)
    for (s0, p) in weighted_iterator(b0)
        push!(new_vals, ProductState(s0, q0))
        push!(new_probs, p)
    end
    normalize!(new_probs, 1)
    return SparseCat{Vector{statetype(problem)}, Vector{Float64}}(new_vals, new_probs)
end

function POMDPs.initialstate(problem::Union{ProductMDP, ProductPOMDP}, rng::AbstractRNG)
    q0 = get_init_state_number(problem.automata)
    return ProductState(initialstate(problem.problem, rng), q0)
end

function POMDPs.states(problem::Union{ProductMDP, ProductPOMDP}) 
    S = statetype(problem.problem)
    Q = eltype(problem.automata.states)
    state_space = ProductState{S, Q}[]
    for s in ordered_states(problem.problem)
        for q in 1:num_states(problem.automata)
            push!(state_space, ProductState(s, q))
        end
    end
    push!(state_space, problem.sink_state)
    return state_space
end

POMDPs.actions(problem::Union{ProductMDP, ProductPOMDP}) = actions(problem.problem)

POMDPs.n_states(problem::Union{ProductMDP, ProductPOMDP}) = n_states(problem.problem)*num_states(problem.automata) + 1

POMDPs.n_actions(problem::Union{ProductMDP, ProductPOMDP}) = n_actions(problem.problem)

function POMDPs.stateindex(problem::Union{ProductMDP, ProductPOMDP}, s::ProductState{S,Q}) where {S,Q} 
    if s == problem.sink_state 
        return n_states(problem)
    end
    si = stateindex(problem.problem, s.s)
    qi = s.q
    return LinearIndices((num_states(problem.automata), n_states(problem.problem)))[qi, si]
end

POMDPs.statetype(p::Union{ProductMDP, ProductPOMDP}) = ProductState{statetype(p.problem), typeof(p.sink_state.q)}

POMDPs.actiontype(p::Union{ProductMDP, ProductPOMDP}) = actiontype(p.problem)

POMDPs.actionindex(p::Union{ProductMDP, ProductPOMDP}, a) = actionindex(p.problem, a) 
# POMDPs.actionindex(p::Union{ProductMDP, ProductPOMDP}, a::Int64) = actionindex(p.problem, a) # to avoid clashes with POMDPModelTools

POMDPs.convert_a(T::Type{V}, a, p::Union{ProductMDP, ProductPOMDP}) where V<:AbstractArray = convert_a(T, a, p.problem)
POMDPs.convert_a(T::Type{A}, vec::V, p::Union{ProductMDP, ProductPOMDP}) where {A,V<:AbstractArray} = convert_a(T, vec, p.problem)

function POMDPs.convert_s(T::Type{Vector{Float64}}, s::ProductState{S,Int64}, p::Union{ProductMDP, ProductPOMDP}) where S
    v_mdp = convert_s(T, s.s, p.problem) # convert mdp state 
    v_autom = zeros(num_states(p.automata))
    v_autom = 1.0
    return cat(1, v_mdp, v_autom)
end

function POMDPs.convert_s(::Type{ProductState{S,Int64}}, vec::Vector{Float64}, p::Union{ProductMDP, ProductPOMDP}) where {S}
    v_mdp = vec[1:end-num_states(p.automata)]
    v_autom = vec[end-num_states(p.automata)+1:end]
    s = convert_s(S, v_mdp, p.problem)
    q = findfirst(v_autom)
    return ProductState(s, q)
end

# ## POMDP Only 

POMDPs.observation(p::ProductPOMDP, s::ProductState{S, Q}) where {S,Q} = observation(p.problem, s.s)
POMDPs.observation(p::ProductPOMDP, a::A, s::ProductState{S, Q}) where {S,Q,A} = observation(p.problem, a, s.s)
POMDPs.observation(p::ProductPOMDP, s::ProductState{S, Q}, a::A, sp::ProductState{S, Q}) where {S,Q,A}= observation(p.problem, s.s, a, sp.s)
POMDPs.observations(p::ProductPOMDP) = observations(p.problem)
POMDPs.n_observations(p::ProductPOMDP) = n_observations(p.problem)
POMDPs.obsindex(p::ProductPOMDP, o::O) where O = obsindex(p.problem, o)
# POMDPs.obsindex(p::ProductPOMDP, o::Bool) = obsindex(p.problem, o) # to avoid clash with POMDPModelTools

POMDPs.convert_o(T::Type{V}, o, p::ProductPOMDP) where V<:AbstractArray = convert_o(T, o, p.problem)
POMDPs.convert_o(T::Type{O}, vec::V, p::ProductPOMDP) where {O,V<:AbstractArray} = convert_o(T, vec, p.problem)
