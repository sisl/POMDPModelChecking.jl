struct Scheduler{S, A} <: Policy
    mdp::MDP{S, A}
    _scheduler::PyObject
    scheduler::Vector{A}
    action_map::Vector{A}
end

function Scheduler(mdp::MDP{S, A}, result::ModelCheckingResult) where {S,A}
    @assert result.result[:has_scheduler]
    py_scheduler = result.result[:scheduler]
    return Scheduler(mdp, py_scheduler)
end

function Scheduler(mdp::MDP{S, A}, py_scheduler::PyObject) where {S,A}
    action_map = ordered_actions(mdp)
    scheduler = Vector{A}(undef, n_states(mdp))
    for i=1:n_states(mdp)
        choice = py_scheduler[:get_choice](i-1)
        ai = choice[:get_deterministic_choice]() + 1
        scheduler[i] = action_map[ai]
    end
    return Scheduler(mdp, py_scheduler, scheduler, action_map)
end

function POMDPs.action(policy::Scheduler{S, A}, s::S) where {S,A}
    si = state_index(policy.mdp, s)
    return policy.scheduler[si]
end
