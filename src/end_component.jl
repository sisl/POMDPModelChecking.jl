# find the maximal end component in an MDP 

# find the maximal accepting end components 
# algorithm 47 from "Principle of model checking"
# an end component is defined as a set of states 

function maximal_end_components(mdp::M; verbose=false) where {M <: Union{MDP, POMDP}}
    verbose ? println("Building graph from mdp ... \n") : nothing
    mdpg = mdp_to_graph(mdp)
    state_space = states(mdp)
    MEC = Vector{Vector{Int64}}(undef, 0) 
    MECnew = Vector{Vector{Int64}}(undef, 0)
    push!(MECnew, 1:length(state_space))# initialize
    DEBUG_STEP = 1 #XXX
    DEBUG_MAX_STEPS = 100 # XXX
    verbose ? println("Computing Maximal End Components ... \n") : nothing
    while MEC != MECnew
        MEC = deepcopy(MECnew)
        MECnew = Vector{Vector{Int64}}(undef, 0)
        for sub_state_space in MEC
            # build subgraph that corresponds to sub_state_space, subgraph of mdpgraph, where all actions moving outside of ss are removed 
            sub_g = sub_mdp(mdp, sub_state_space, state_space)
            scc = strongly_connected_components(sub_g)
            for component in scc                  
                # map bag to state indices
                stateindex_component = sub_state_space[component]
                # check that component is not trivial (is at least a cycle)
                if length(component) == 1 && !has_edge(sub_g, component[1], component[1])
                    continue # skip trivial components
                end
                push!(MECnew, stateindex_component)
            end
        end
        verbose ? println("finished $DEBUG_STEP step, old MEC $(length(MEC)) -> new MEC $(length(MECnew))") : nothing
        DEBUG_STEP += 1
    end
    verbose ? println("MECs length: ", length.(MEC)) : nothing
    verbose ? println("MECs computed. \n") : nothing
    return MEC
end

# convert MDP to graph 
function mdp_to_graph(mdp::M) where {M <: Union{MDP, POMDP}}
    g = DiGraph(length(states(mdp)))
    for (i, s) in enumerate(ordered_states(mdp))
        si = stateindex(mdp, s)
        if isterminal(mdp, s)
            add_edge!(g, si, si)
        end
        for a in actions(mdp, s)
            d = transition(mdp, s, a)
            for (sp, p) in weighted_iterator(d)
                if !(p ≈ 0.)
                   spi = stateindex(mdp, sp)
                   add_edge!(g, si, spi)
                end
            end
        end
    end
    return g 
end

# return a graph of the subMDP defined by ss
function sub_mdp(mdp::M, state_indices::Vector{Int64}, state_space) where {M<:Union{MDP,POMDP}}
    g = DiGraph(length(state_indices))
    for (i, si) in enumerate(state_indices)
        s = state_space[si]
        if isterminal(mdp, s)
            add_edge!(g, i, i)            
        end
        for a in actions(mdp, s)
            d = transition(mdp, s, a)
            is_action_valid = true
            for (sp, p) in weighted_iterator(d)
                if !(p ≈ 0.)
                    spi = stateindex(mdp, sp)
                    if !in(spi, state_indices)
                        is_action_valid = false
                    end
                end
            end
            if is_action_valid
                for (sp, p) in weighted_iterator(d)
                    if !(p≈0.)
                        spi = stateindex(mdp, sp)
                        j = findfirst(x->x==spi, state_indices)
                        add_edge!(g, i, j)
                    end
                end
            end
        end
    end
    return g
end
