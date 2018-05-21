struct ModelCheckingResult{S}
    mdp::MDP{S}
    labels::Dict{S, Vector{String}}
    property::String
    result::PyObject
end

"""
model_checking{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String;
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab")
"""
function model_checking{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String;
                        transition_file_name::String = "mdp.tra",
                        labels_file_name::String = "mdp.lab")
    model = parse_mdp_model(mdp, labeling, transition_file_name, labels_file_name)
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
                        labels_file_name::String = "mdp.lab")
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
