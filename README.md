# POMDPStorm

[![Build Status](https://travis-ci.org/MaximeBouton/POMDPStorm.jl.svg?branch=master)](https://travis-ci.org/MaximeBouton/POMDPStorm.jl)

[![Coverage Status](https://coveralls.io/repos/MaximeBouton/POMDPStorm.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/MaximeBouton/POMDPStorm.jl?branch=master)

[![codecov.io](http://codecov.io/github/MaximeBouton/POMDPStorm.jl/coverage.svg?branch=master)](http://codecov.io/github/MaximeBouton/POMDPStorm.jl?branch=master)

This package provide an interface between [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) and [Storm](http://www.stormchecker.org/) model checking library. It allows to analyze MDP model using logical specifications.

**Note:** This is mostly a julia wrapper around the python library [stormpy](https://moves-rwth.github.io/stormpy/).

## Usage

To install the package run
```julia
Pkg.clone("https://github.com/MaximeBouton/POMDPStorm.jl")
```

It assumes that the Storm library and stormpy are already installed.

```julia
using POMDPStorm, POMDPModels

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