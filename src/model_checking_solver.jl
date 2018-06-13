@with_kw mutable struct ModelCheckingSolver <: Solver 
    property::String = "" 
    automata_file::String = "automata.hoa"
    solver::Solver = ValueIterationSolver() # can use any solver that returns a value function :o
end

mutable struct ModelCheckingPolicy{P <: Policy, M <: ProductMDP, Q} <: Policy
    policy::P
    mdp::M
    memory::Q
end

# NOTE: the returned value function will be 0. at the accepting states instead of 1, this is overriden by the implementation 
# of POMDPs.value below.
function POMDPs.solve(solver::ModelCheckingSolver, mdp::MDP{S, A}) where {S, A}
    # parse formula first 
    ltl2tgba(solver.property, solver.automata_file)
    autom_type = automata_type(solver.automata_file)
    automata = nothing
    if autom_type == "Buchi"
        automata = hoa2buchi(solver.automata_file)
    elseif autom_type == "Rabin"
        automata = hoa2rabin(solver.automata_file)
    end
    pmdp = ProductMDP(mdp, automata) # build product mdp x automata
    acc = accepting_states!(pmdp) # compute the maximal end component via a graph analysis
    policy = solve(solver.solver, pmdp) # solve using your favorite method
    return ModelCheckingPolicy(policy, pmdp, automata.initial_state)
end

function POMDPs.action(policy::ModelCheckingPolicy, s)
    a = action(policy.policy, ProductState(s, policy.memory))
    update_memory!(policy, s)
    return a
end

function POMDPs.action(policy::ModelCheckingPolicy, s::ProductState{S, Q}) where {S, Q}
    return action(policy.policy, s)
end

function POMDPs.value(policy::ModelCheckingPolicy, s::ProductState{S, Q}) where {S, Q}
    if s ∈ policy.mdp.accepting_states  # see comment in POMDPs.solve
        return 1.0 
    else
        return value(policy.policy, s)
    end
end

function value_vector(policy::ModelCheckingPolicy,  s::ProductState{S, Q}) where {S, Q}
    if s ∈ policy.mdp.accepting_states
        return ones(n_actions(policy.mdp))
    else
        return value(policy.policy, s)
    end
end

function value_vector(policy::ValueIterationPolicy,  s)
    si = state_index(policy.mdp, s)
    return policy.value_table[si, :]
end

function reset_memory!(policy::ModelCheckingPolicy)
    policy.memory = policy.mdp.automata.initial_state
end

function update_memory!(policy::ModelCheckingPolicy, s)
    l = labels(policy.mdp.mdp, s)
    if has_transition(policy.mdp.automata, policy.memory, l)
        policy.memory = transition(policy.mdp.automata, policy.memory, l)
    end
end

