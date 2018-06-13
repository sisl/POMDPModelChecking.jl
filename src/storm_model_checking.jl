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
function model_checking{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String;
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab", 
                        overwrite::Bool = false)
    model = parse_mdp_model(mdp, labeling, transition_file_name, labels_file_name, overwrite)
    properties = stormpy.parse_properties(property)
    result = stormpy.model_checking(model, properties[1],  only_initial_states=false, extract_scheduler=true)
    @assert result[:result_for_all_states]
    return ModelCheckingResult(mdp, labeling, property, result)    
end

"""
    parse an MDP model with Storm, if the specified transition and labels file do not exist it will write the files first
"""
function parse_mdp_model{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}},
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab",
                        overwrite::Bool = false)
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
