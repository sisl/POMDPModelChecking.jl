# Masked Eps Greedy Policy
struct MaskedEpsGreedyPolicy{M <: SafetyMask} <: Policy
    val::ValuePolicy # the greedy policy
    epsilon::Float64
    mask::M
    rng::AbstractRNG
end

MaskedEpsGreedyPolicy{S, A, M}(mdp::MDP{S, A}, epsilon::Float64, mask::M, rng::AbstractRNG) = MaskedEpsGreedyPolicy(ValuePolicy(mdp), epsilon, mask, rng)

function POMDPs.action{M}(policy::MaskedEpsGreedyPolicy{M}, s)
    acts = safe_actions(policy.mask, s)
    if rand(policy.rng) < policy.epsilon
        return rand(policy.rng, acts)
    else
        return best_action(acts, policy.val, s)
    end
end

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
