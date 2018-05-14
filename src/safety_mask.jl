"""
extract a vector P of size |S| where P(s) is the probability of satisfying a property
when starting in state s 
"""
function get_proba(mdp::MDP, result::ModelCheckingResult)
    P = zeros(n_states(mdp))
    for (i, val) in enumerate(result.result[:get_values]())
        P[i] = val
    end
    return P
end

#XXX Not sure is this algorithm is mathematically sound!!! (should technically be over the product MDP)
# return matrix of dimension |S|x|A|
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

# can be precomputed and stored when constructing the mask
function safe_actions{M, A, S}(mask::SafetyMask{M,A}, s::S)
    safe_acts = A[]
    sizehint!(safe_acts, n_actions(mask.mdp))
    si = state_index(mask.mdp, s)
    safe = mask.risk_vec[si] > mask.threshold ? true : false
    if !safe # follow safe controller
        push!(safe_acts, mask.actions[indmax(mask.risk_mat[s, :])])
    else
        for (j, a) in enumerate(mask.actions)
            if mask.risk_mat[si, j] > mask.threshold
                push!(safe_acts, a)
            end
        end
    end
    return safe_acts
end

