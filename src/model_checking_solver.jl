@with_kw mutable struct ModelCheckingSolver <: Solver 
    property::String = "" 
    automata_file::String = "automata.hoa"
    solver::Solver = ValueIterationSolver() # can use any solver that returns a value function :o
    verbose::Bool = false
end

mutable struct ModelCheckingPolicy{P <: Policy, M <:Union{ProductMDP, ProductPOMDP}, Q} <: Policy
    policy::P
    mdp::M
    memory::Q
end

# NOTE: the returned value function will be 0. at the accepting states instead of 1, this is overriden by the implementation 
# of POMDPs.value below.
function POMDPs.solve(solver::ModelCheckingSolver, problem::M) where M<:Union{MDP,POMDP}
    verbose = solver.verbose
    # parse formula first 
    ltl2tgba(solver.property, solver.automata_file)
    autom_type = automata_type(solver.automata_file)
    automata = nothing
    if autom_type == "Buchi"
        automata = hoa2buchi(solver.automata_file)
    elseif autom_type == "Rabin"
        automata = hoa2rabin(solver.automata_file)
    end
    pmdp = nothing
    sink_state = ProductState(first(states(problem)), -1)
    if isa(problem, POMDP)
        pmdp = ProductPOMDP(problem, automata, sink_state)
    else
        pmdp = ProductMDP(problem, automata) # build product mdp x automata
    end
    if isempty(pmdp.accepting_states)
        accepting_states!(pmdp, verbose=verbose) # compute the maximal end components via a graph analysis
    end
    policy = solve(solver.solver, pmdp) # solve using your favorite method
    return ModelCheckingPolicy(policy, pmdp, automata.initialstate)
end

function POMDPs.action(policy::ModelCheckingPolicy, s)
    a = action(policy.policy, ProductState(s, policy.memory))
    update_memory!(policy, s, a)
    return a
end

function POMDPs.action(policy::ModelCheckingPolicy, s::ProductState{S, Q}) where {S, Q}
    return action(policy.policy, s)
end

function POMDPs.value(policy::ModelCheckingPolicy, s)
    return value(policy, ProductState(s, policy.memory))
end

function POMDPs.value(policy::ModelCheckingPolicy, s::ProductState{S, Q}) where {S, Q}
    if s ∈ policy.mdp.accepting_states  # see comment in POMDPs.solve
        return 1.0 
    else
        return value(policy.policy, s)
    end
end

function POMDPPolicies.actionvalues(policy::ModelCheckingPolicy,  s)
    if s ∈ policy.mdp.accepting_states
        return ones(n_actions(policy.mdp))
    else
        return actionvalues(policy.policy, s)
    end
end

function reset_memory!(policy::ModelCheckingPolicy)
    policy.memory = policy.mdp.automata.initialstate
end

function update_memory!(policy::ModelCheckingPolicy, s, a)
    l = labels(policy.mdp.mdp, s, a)
    if has_transition(policy.mdp.automata, policy.memory, l)
        policy.memory = transition(policy.mdp.automata, policy.memory, l)
    end
end

