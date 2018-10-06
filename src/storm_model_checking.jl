struct ModelCheckingResult{S}
    mdp::MDP{S}
    labels::Dict{S, Vector{String}}
    property::String
    result::PyObject
end

"""
Write the MDP model and its associated labels to a file and parse them using storm. It then runs the reachability analysis by computing for each state,
the probability of satisfying the desired property. To learn more about how to specify properties, look at the storm documentation.
This function returns a `ModelCheckingResult` object, from which the probability of satisfaction can be extracted as well as the scheduler maximizing the probability 
of success.
**Arguments:**
- `mdp::MDP`, the MDP models defined according to the POMDPs.jl interface 
- `labeling::Dict{S, Vector{String}}` , a dictionnary mapping the states of the MDP to their labels 
- `property::String`, a LTL property to verify. (follow storm property definition)
- `transition_file_name::String = "mdp.tra"` the file name to read from or write the MDP model 
- `labels_file_name::String = "mdp.lab"` the file name to read from or write the state labels 
- `overwrite::Bool = false` if set to true, it will remove the existing transition and labels file and write new ones. 

`model_checking{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String; transition_file_name::String = "mdp.tra", labels_file_name::String = "mdp.lab", overwrite::Bool = false)`
"""
function model_checking(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String;
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab", 
                        overwrite::Bool = false) where S
    model = parse_mdp_model(mdp, labeling, transition_file_name, labels_file_name, overwrite)
    properties = stormpy.parse_properties(property)
    result = stormpy.model_checking(model, properties[1],  only_initialstates=false, extract_scheduler=true)
    @assert result[:result_for_all_states]
    return ModelCheckingResult(mdp, labeling, property, result)    
end

"""
    parse an MDP model with Storm, if the specified transition and labels file do not exist it will write the files first
"""
function parse_mdp_model(mdp::MDP{S}, labeling::Dict{S, Vector{String}},
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab",
                        overwrite::Bool = false) where S
        if overwrite
            warn("overwriting potential existing files!")
            try 
                run(`rm $transition_file_name`)
                run(`rm $labels_file_name`)
            catch
            end
        end
        if !isfile(transition_file_name)
            write_mdp_transition(mdp, transition_file_name)
        end
        if !isfile(labels_file_name)
            write_mdp_labels(mdp, labeling, labels_file_name)
        end
        model = parse_mdp_model(transition_file_name, labels_file_name)
        return model
end

function parse_mdp_model(transition_file_name::String, labels_file_name::String)
    return stormpy.build_sparse_model_from_explicit(transition_file_name, labels_file_name)
end


struct StormPolicy{M<:MDP} <: Policy 
    mdp::M
    risk_vec::Vector{Float64}
    risk_mat::Array{Float64, 2}
end

function StormPolicy(mdp::MDP, result::ModelCheckingResult)
    risk_vec = get_proba(mdp, result)
    risk_mat = get_state_action_proba(mdp, risk_vec)
    return StormPolicy(mdp, risk_vec, risk_mat)
end

function value_vector(policy::StormPolicy, s)
    si = stateindex(policy.mdp, s)
    return policy.risk_mat[si, :]
end

function value(policy::StormPolicy, s)
    si = stateindex(policy.mdp, s)
    return policy.risk_vec[si]
end

function action(policy::StormPolicy, s)
    acts = actions(mdp)
    vals = value_vector(policy, s)
    return acts[argmax(vals)]
end

    
"""
extract a vector P of size |S| where P(s) is the probability of satisfying a property
when starting in state s 
`get_proba(mdp::MDP, result::ModelCheckingResult)`
"""
function get_proba(mdp::MDP, result::ModelCheckingResult)
    P = zeros(n_states(mdp))
    for (i, val) in enumerate(result.result[:get_values]())
        P[i] = val
    end
    return P
end

"""
Returns a matrix of dimension |S|x|A| where each element is the probability of satisfying an LTL formula for a given state action pair.
This algorithm is mathematically sound only for basic LTL property like "!a U b" !!! (should technically be over the product MDP)
Arguments: 
- `mdp::MDP` the MDP model
- `result::ModelCheckingResult` result from model checking
 `get_state_action_proba(mdp::MDP, P::Vector{Float64})`
"""
function get_state_action(mdp::MDP, result::ModelCheckingResult)
    P = get_proba(mdp, result)
    P_sa = get_state_action_proba(mdp, P)
    return P_sa
end
function get_state_action_proba(mdp::MDP, P::Vector{Float64})
    P_sa = zeros(n_states(mdp), n_actions(mdp))
    states = ordered_states(mdp)
    actions = ordered_actions(mdp)
    for (si, s) in enumerate(states)
        P[si] == 0. ? continue : nothing             
        for (ai, a) in enumerate(actions)
            dist = transition(mdp, s, a)
            for (sp, p) in  weighted_iterator(dist)
                p == 0.0 ? continue : nothing # skip if zero prob
                spi = stateindex(mdp, sp)
                P_sa[si, ai] += p * P[spi]
            end
        end
    end
    return P_sa
end