using MDPModelChecking
using POMDPModels
using POMDPs
# discrete MDP 1 
ns = 4
na = 6
R = zeros(ns, na)
T = zeros(ns, na, ns) # sp, a, s


# from state 1
T[2,1, 1] = 1.0  # if go, move to 2
T[1,2:na,1] .= 1.0 # else stay

# from state 2
T[1,2,2] = 0.7 # if (s2, safe) end up in 1
T[3,2,2] = 0.3 # if (s2, safe) end up in 3

T[3,3,2] = 0.5
T[4,3,2] = 0.5
T[2,1,2] = 1.
T[2,4:end,2] .= 1.

# from state 3
T[3,:,3] .= 1

# from state 4 
T[4,:,4] .= 1.
T[:,4,4] .= 0.
T[1,4,4] = 1.

mdp = TabularMDP(T, R, 0.95)


# product mdp

property = "F G succ & (G!fail)"
ltl2tgba(property, "discrete.hoa") # should translate to DRA
automata = hoa2rabin("discrete.hoa")

pmdp = ProductMDP(mdp, automata)

b0 = initialstate_distribution(pmdp)


# state_space = states(pmdp)
# action_space = actions(pmdp)
# γ = discount(pmdp)
# n_states(pmdp) == length(state_space)
# n_actions(pmdp) == length(action_space)
# statetype(pmdp) == ProductState{Int64, Int64}
# actiontype(pmdp) == Int64

# test_stateindexing(pmdp)
# test_transition(pmdp)

for s in states(pmdp)
    for a in actions(pmdp, s)
        d = transition(pmdp, s, a)
        tsum = 0. 
        for (sp, p) in weighted_iterator(d)
            tsum += p
        end
        if !(tsum ≈ 1.0)
            println("error for s ", s, " a ", a, " sums to ", tsum, " next states ", d.vals)
        end
    end
end


s = ProductState(2, 1)
a = 3
d = transition(pmdp, s, a)
for (sp, p) in weighted_iterator(d)
    println((sp.s, sp.q), " ", p)
end
l = labels(mdp, s.s)



d = transition(pmdp.mdp, s.s, a)
for (sp, p) in weighted_iterator(d)
    println(sp, " ", p)
end

MEC = maximal_end_components(pmdp)
state_space = states(pmdp);
MEC = Set(state_space[i] for i in MEC)
us = accepting_states(pmdp)
