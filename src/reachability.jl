@with_kw struct ReachabilitySolver{S} <: Solver
    reach::Set{S} = Set{S}()
    avoid::Set{S} = Set{S}()
    solver::Solver = ValueIterationSolver()# can use any solver that returns a value function :o
end

function POMDPs.solve(solver::ReachabilitySolver, mdp::MDP)
    rmdp = ReachabilityMDP(mdp, solver.reach, solver.avoid)
    policy = solve(solver.solver, rmdp)
    return ReachabilityPolicy(policy, mdp, solver.reach, solver.avoid)
end

function POMDPs.solve(solver::ReachabilitySolver, pomdp::POMDP)
    rmdp = ReachabilityPOMDP(pomdp, solver.reach, solver.avoid)
    policy = solve(solver.solver, rmdp)
    return ReachabilityPolicy(policy, pomdp, solver.reach, solver.avoid)
end

struct ReachabilityPolicy{P <: Policy, M <: Union{MDP, POMDP}, S} <: Policy
    policy::P
    problem::M
    reach::Set{S}
    avoid::Set{S}
end

POMDPs.action(policy::ReachabilityPolicy, s) = action(policy.policy, s)
function POMDPs.value(policy::ReachabilityPolicy, s)
    if s ∈ policy.reach
        return 1.0 
    else
        return value(policy.policy, s)
    end
end
function POMDPPolicies.actionvalues(policy::ReachabilityPolicy, s)
    if s ∈ policy.reach 
        return ones(n_actions(policy.problem))
    else
        return actionvalues(policy.policy, s)
    end
end

struct ReachabilityPOMDP{S, A, O, P <: POMDP{S,A,O}} <: POMDP{S,A,O} 
    problem::P 
    reach::Set{S}
    avoid::Set{S}
end

struct ReachabilityMDP{S, A, P <: MDP{S,A}} <: MDP{S,A} 
    problem::P 
    reach::Set{S}
    avoid::Set{S}
end

POMDPs.states(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = states(r.problem) 
POMDPs.stateindex(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s) = stateindex(r.problem, s)
POMDPs.n_states(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = n_states(r.problem)
POMDPs.statetype(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = statetype(r.problem)
POMDPs.actions(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = actions(r.problem)
POMDPs.actionindex(r::Union{ReachabilityMDP, ReachabilityPOMDP}, a) = actionindex(r.problem, a)
POMDPs.actiontype(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = actiontype(r.problem)
POMDPs.n_actions(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = n_actions(r.problem)
POMDPs.observation(r::ReachabilityPOMDP, s, a) = observation(r.problem, s, a)
POMDPs.observations(r::ReachabilityPOMDP) = observations(r.problem)
POMDPs.obsindex(r::ReachabilityPOMDP, o) = obsindex(r.problem, o)
POMDPs.n_observations(r::ReachabilityPOMDP) = n_observations(r.problem)
POMDPs.obstype(r::ReachabilityPOMDP) = obstype(r.problem)

POMDPs.transition(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s, a) = transition(r.problem, s, a)

POMDPs.isterminal(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s) = (s ∈ r.reach) || (s ∈ r.avoid)
POMDPs.initialstate_distribution(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = initialstate_distribution(r.problem)
POMDPs.initialstate(r::Union{ReachabilityMDP, ReachabilityPOMDP}, rng::AbstractRNG) = initialstate(r.problem, rng)

POMDPs.reward(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s) = float(s ∈ r.reach)
POMDPs.reward(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s, a) = reward(r, s)
POMDPs.reward(r::Union{ReachabilityMDP, ReachabilityPOMDP}, s, a, sp) = reward(r, sp)
POMDPs.discount(r::Union{ReachabilityMDP, ReachabilityPOMDP}) = 1.0
