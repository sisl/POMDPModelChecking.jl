"""
extract a vector P of size |S| where P(s) is the probability of satisfying a property
when starting in state s 
`get_proba(mdp::MDP, result::ModelCheckingResult)`
"""
function get_proba(mdp::MDP, result::ModelCheckingResult)
    P = zeros(n_states(mdp))
    for (i, val) in enumerate(result.result[:get_values]())
        P[i] = val
    end
    return P
end

"""
Returns a matrix of dimension |S|x|A| where each element is the probability of satisfying an LTL formula for a given state action pair.
This algorithm is mathematically sound only for basic LTL property like "!a U b" !!! (should technically be over the product MDP)
Arguments: 
- `mdp::MDP` the MDP model
- `result::ModelCheckingResult` result from model checking
 `get_state_action_proba(mdp::MDP, P::Vector{Float64})`
"""
function get_state_action(mdp::MDP, result::ModelCheckingResult)
    P = get_proba(mdp, result)
    P_sa = get_state_action_proba(mdp, P)
    return P_sa
end
function get_state_action_proba(mdp::MDP, P::Vector{Float64})
    P_sa = zeros(n_states(mdp), n_actions(mdp))
    states = ordered_states(mdp)
    actions = ordered_actions(mdp)
    for (si, s) in enumerate(states)
        P[si] == 0. ? continue : nothing             
        for (ai, a) in enumerate(actions)
            dist = transition(mdp, s, a)
            for (sp, p) in  weighted_iterator(dist)
                p == 0.0 ? continue : nothing # skip if zero prob
                spi = state_index(mdp, sp)
                P_sa[si, ai] += p * P[spi]
            end
        end
    end
    return P_sa
end

"""
Extract a scheduler as a `VectorPolicy` from the model checking result 
"""
function POMDPToolbox.VectorPolicy{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult{S})
    P = get_proba(mdp, result)
    P_sa = get_state_action_proba(mdp, P)
    Pmax, amax = findmax(P_sa, 2)
    amax = ind2sub.((size(P_sa),), amax)
    actions = ordered_actions(mdp)
    act_vec = Vector{A}(n_states(mdp))
    map!(x -> actions[x[2]], act_vec, amax)
    return VectorPolicy(mdp, act_vec)
end

"""
Build a safety mask: a `SafetyMask` object contains infromation on the "safety" of each state action pair of the MDP. Safety is measure as the probability of satisfying the desired LTL formula. It takes as input the mdp model, the result from model checking and a threshold on the probability of success. State action pairs for which the probability of success is below the threshold are considered as unsafe. 
`SafetyMask{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult, threshold::Float64)`
"""
struct SafetyMask{M <: MDP, A} 
    mdp::M
    threshold::Float64
    risk_vec::Vector{Float64}
    risk_mat::Array{Float64, 2}
    actions::Vector{A}
end

function SafetyMask{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult, threshold::Float64)
    P = get_proba(mdp, result)
    P_sa = get_state_action_proba(mdp, P)
    return SafetyMask(mdp, threshold, P, P_sa, actions(mdp))
end

"""
Returns a vector of safe actions to execute in state s
An action is safe if the probability of success is above the threshold of the safety mask.
`safe_actions{M, A, S}(mask::SafetyMask{M,A}, s::S)`
"""
function safe_actions{M, A, S}(mask::SafetyMask{M,A}, s::S)
    safe_acts = A[]
    sizehint!(safe_acts, n_actions(mask.mdp))
    si = state_index(mask.mdp, s)
    safe = mask.risk_vec[si] > mask.threshold ? true : false
    if !safe # follow safe controller
        push!(safe_acts, mask.actions[indmax(mask.risk_mat[si, :])])
    else
        for (j, a) in enumerate(mask.actions)
            if mask.risk_mat[si, j] > mask.threshold
                push!(safe_acts, a)
            end
        end
    end
    return safe_acts
end

"""
returns the initial probability of satisfying \$\phi\$: 
\$\Sigma_s b(s)P(s \models \phi)\$

    initial_probability(mdp::MDP, result::ModelCheckingResult)
""" 
function initial_probability(mdp::MDP, result::ModelCheckingResult)
    P = get_proba(mdp, result)
    p_init = 0.
    d0 = initial_state_distribution(mdp)
    for (s, p) in weighted_iterator(d0)
        si = state_index(mdp, s)
        p_init += p*P[si]
    end
    return p_init 
end
