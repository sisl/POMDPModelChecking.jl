"""
Write mdp transitions in a ".tra" file to give as an input to storm.
The transition probabilities are written according to storm explicit format as follows: 
```
mdp
0 0 1 0.3
0 0 4 0.7
0 1 0 0.5
0 1 1 0.5
1 0 1 1.0
...
```
In our usual MDP formulation a row is: s, a, s', T(s,a,s')

    write_mdp_transition(mdp::MDP, filename::String="mdp.tra")
"""
function write_mdp_transition(mdp::MDP, filename::String="mdp.tra")
    states = ordered_states(mdp)
    actions = ordered_actions(mdp)
    open(filename, "w") do f
        write(f, "mdp \n")
        for s in states
            si = stateindex(mdp, s)
            si -= 1 # 0-indexed
            for a in actions
                ai = actionindex(mdp, a) - 1
                d = transition(mdp, s, a)
                for (sp, p) in weighted_iterator(d)
                    spi = stateindex(mdp, sp) - 1
                    p == 0.0 ? continue : nothing
                    line = string(si, " ", ai, " ", spi, " ", p, "\n")
                    write(f, line)
                end
            end
        end
    end
end

"""
Write state labels in a ".lab" file to give as input to storm

File format:
Define labels and write the mapping from states to labels in a file using the following syntax: 
```
#DECLARATION
label1, label2, label3
#END
0 label1 label2
15 label2
23 label3
```

All the possible labels must be declared first. A state can have several labels. In the file the states must be ordered.

    write_mdp_labels{S, A}(mdp::MDP{S, A}, labeling::Dict{S, Vector{String}}, filename::String="mdp.lab")
"""
function write_mdp_labels{S, A}(mdp::MDP{S, A}, labeling::Dict{S, Vector{String}}, filename::String="mdp.lab")
    labels = Set{String}()
    for labv in Set(values(labeling))
        for lab in labv
            push!(labels, lab)
        end
    end
    open(filename, "w") do f
        write(f, "#DECLARATION\n")
        for label in labels            
            write(f, "$label ")
        end
        write(f, "\n")
        write(f, "#END\n")
        # states must be sorted by index
        for (i, s) in enumerate(ordered_states(mdp))
            if haskey(labeling, s)
                si = stateindex(mdp, s) - 1 #0 indexed
                write(f, string(si, " "))
                for lab in labeling[s]
                    write(f, lab, " ")
                end
                write(f, "\n")
            end
        end
    end
end

