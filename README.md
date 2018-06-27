# MDPModelChecking.jl (branch product)

[![Build Status](https://travis-ci.org/MaximeBouton/MDPModelChecking.jl.svg?branch=master)](https://travis-ci.org/MaximeBouton/MDPModelChecking.jl)

[![Coverage Status](https://coveralls.io/repos/MaximeBouton/MDPModelChecking.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/MaximeBouton/MDPModelChecking.jl?branch=master)

[![codecov.io](http://codecov.io/github/MaximeBouton/MDPModelChecking.jl/coverage.svg?branch=master)](http://codecov.io/github/MaximeBouton/MDPModelChecking.jl?branch=master)

This package provide an interface between [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) and [Storm](http://www.stormchecker.org/) model checking library. It allows to analyze MDP model using logical specifications.

**Note:** This is mostly a julia wrapper around the python library [stormpy](https://moves-rwth.github.io/stormpy/).

It also contains tools to build safety masks if the property to verify are safety properties like `G !a` or `!a U b`. This safety mask can be used to derive policies. These tools are preliminary for now and should be extended to handle more general class of LTL properties.

## Usage

To install the package run
```julia
Pkg.clone("https://github.com/MaximeBouton/MDPModelChecking.jl")
```

It assumes that the Storm library and stormpy are already installed.

```julia
using MDPModelChecking, POMDPModels

mdp = GridWorld()

# return a dictionary mapping states to label
# must be implemented by the user
# the positive reward states are labeled as good 
# the negative reward states are labeled as bad
function label_grid_world(mdp::GridWorld)
    good_states = mdp.reward_states[mdp.reward_values .> 0.]
    bad_states = mdp.reward_states[mdp.reward_values .< 0.]
    labeling = Dict{state_type(mdp), String}()
    for s in good_states
        labeling[s] = ["good"]
    end
    for s in bad_states
        labeling[s] = ["bad"]
    end
    labeling[GridWorldState(0, 0, true)] = ["good", "term"]
    return labeling
end

labeling = label_grid_world(mdp)
property = "Pmax=? [ (!\"bad\") U \"good\"]"  # follow stormpy syntax
result = model_checking(mdp, labeling, property) # run model checker
policy = Scheduler(mdp, result) # create a policy from the output of the model checker

a = action(policy, GridWorldState(1,1))

```

## Notes on the supported models

Only discrete state and action MDP are supported by the model checking library. 

To express logical properties on trajectories of the MDP one must defines labels associated to the states and define the property in function of the labels.

The labels are represented by a dictionary of type `Dict{S, Vector{String}}` where `S` is a custom state type. The atomic proposition representing the state labels are strings. It is up to the user to implement a function that will fill the labels dictionary to be passed to the model checker.

So far, storm only supports simple path formulas like `F a`, `phi1 U phi2` or `G a`. 

## Documentation

- Model checking: `model_checking{S}(mdp::MDP{S}, labeling::Dict{S, Vector{String}}, property::String; transition_file_name::String = "mdp.tra", labels_file_name::String = "mdp.lab", overwrite::Bool = false)`
Write the MDP model and its associated labels to a file and parse them using storm. It then runs the reachability analysis by computing for each state,
the probability of satisfying the desired property. To learn more about how to specify properties, look at the storm documentation.
This function returns a `ModelCheckingResult` object, from which the probability of satisfaction can be extracted as well as the scheduler maximizing the probability of success.
  **Arguments:**
  - `mdp::MDP`, the MDP models defined according to the POMDPs.jl interface 
  - `labeling::Dict{S, Vector{String}}` , a dictionnary mapping the states of the MDP to their labels 
  - `property::String`, a LTL property to verify. (follow storm property definition)
  - `transition_file_name::String = "mdp.tra"` the file name to read from or write the MDP model 
  - `labels_file_name::String = "mdp.lab"` the file name to read from or write the state labels 
  - `overwrite::Bool = false` if set to true, it will remove the existing transition and labels file and write new ones. 

- Build a safety mask: a `SafetyMask` object contains infromation on the "safety" of each state action pair of the MDP. Safety is measure as the probability of satisfying the desired LTL formula. It takes as input the mdp model, the result from model checking and a threshold on the probability of success. State action pairs for which the probability of success is below the threshold are considered as unsafe. 
`SafetyMask{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult, threshold::Float64)`
A safety mask is accompanied with the function `safe_actions{M, A, S}(mask::SafetyMask{M,A}, s::S)` which returns a vector of safe actions to execute in state s.
Two different policies can be derived from a safety mask: `MaskedEpsGreedyPolicy` and `MaskedValuePolicy`. They are similar to their analogous in POMDPToolbox but the returned action is always in the set of safe actions given by the mask. 

```julia 
# example of how to initialize and use a safety mask
threshold = 0.99 # desired risk threshold
safety_mask = SafetyMask(mdp, result, threshold) # compute the probability of success for each state action pair, can take a while for large MDPs
acts = safe_actions(safety_mask, s) # return a vector of safe actions to take in state s

```

- Extract a policy: for some formulas, storm will be able to extract a scheduler, to directly use the scheduler given by storm build a `Scheduler` object which can be use as a policy. If storm only returns a probability vector, a scheduler can be converted to a `VectorPolicy` object from POMDPToolbox (this conversion is only reliable for basic safety LTL properties for now).
`POMDPToolbox.VectorPolicy{S, A}(mdp::MDP{S, A}, result::ModelCheckingResult{S})`
