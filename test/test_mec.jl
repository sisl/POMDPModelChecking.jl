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


MEC = maximal_end_components(mdp, verbose=true)
@test MEC == [[3], [4]]

gw = SimpleGridWorld(size=(20,20))
gw_mec = maximal_end_components(gw, verbose=false)

@test length(gw_mec) == 2*gw.size_y + 2*gw.size_x - 3