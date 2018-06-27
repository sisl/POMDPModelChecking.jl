# Masked Eps Greedy Policy
"""
Epsilon greedy policy that operates within a safety mask. Both actions from the greedy part and the random part are drawn from the safe actions returned by 
the safety mask.
`MaskedEpsGreedyPolicy{S, A, M}(mdp::MDP{S, A}, epsilon::Float64, mask::M, rng::AbstractRNG)`
"""
struct MaskedEpsGreedyPolicy{M <: SafetyMask} <: Policy
    val::ValuePolicy # the greedy policy
    epsilon::Float64
    mask::M
    rng::AbstractRNG
end

MaskedEpsGreedyPolicy(mdp::MDP{S, A}, epsilon::Float64, mask::M, rng::AbstractRNG) where {S, A, M <: SafetyMask} = MaskedEpsGreedyPolicy{M}(ValuePolicy(mdp), epsilon, mask, rng)

function POMDPs.action{M}(policy::MaskedEpsGreedyPolicy{M}, s)
    acts = safe_actions(policy.mask, s)
    if rand(policy.rng) < policy.epsilon
        return rand(policy.rng, acts)
    else
        return best_action(acts, policy.val, s)
    end
end

"""
A value policy that operates within a safety mask, it takes the action in the set of safe_actions that maximizes the given value function. 
`MaskedValuePolicy{M <: SafetyMask}(val::ValuePolicy, mask::M`
"""
struct MaskedValuePolicy{M <: SafetyMask} <: Policy
    val::ValuePolicy
    mask::M
end

function POMDPs.action{M}(policy::MaskedValuePolicy{M}, s)
    acts = safe_actions(policy.mask, s)
    return best_action(acts, policy.val, s)
end

function best_action{A, M}(acts::Vector{A}, policy::ValuePolicy{A, M}, s)
    si = state_index(policy.mdp, s)
    best_ai = 1
    best_val = policy.value_table[si, best_ai]
    for a in acts
        ai = action_index(policy.mdp, a)
        val =  policy.value_table[si, ai]
        if val > best_val
            best_ai = ai 
            best_val = val 
        end
    end
    return policy.act[best_ai]
end
