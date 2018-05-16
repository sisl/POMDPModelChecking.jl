struct Scheduler{S, A} <: Policy
    mdp::MDP{S, A}
    _scheduler::PyObject
    scheduler::Vector{A}
    action_map::Vector{A}
end

function Scheduler{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult)
    @assert result.result[:has_scheduler]
    py_scheduler = result.result[:scheduler]
    return Scheduler(mdp, py_scheduler)
end

function Scheduler{S, A}(mdp::MDP{S, A}, py_scheduler::PyObject)
    action_map = ordered_actions(mdp)
    scheduler = Vector{A}(n_states(mdp))
    for i=1:n_states(mdp)
        choice = py_scheduler[:get_choice](i-1)
        ai = choice[:get_deterministic_choice]() + 1
        scheduler[i] = action_map[ai]
    end
    return Scheduler(mdp, py_scheduler, scheduler, action_map)
end

function POMDPs.action{S, A}(policy::Scheduler{S, A}, s::S)
    si = state_index(policy.mdp, s)
    return policy.scheduler[si]
end
