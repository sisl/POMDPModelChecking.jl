# POMDPModelChecking.jl

[![Build Status](https://travis-ci.org/sisl/POMDPModelChecking.jl.svg?branch=master)](https://travis-ci.org/sisl/POMDPModelChecking.jl) [![Coverage Status](https://coveralls.io/repos/sisl/POMDPModelChecking.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/sisl/POMDPModelChecking.jl?branch=master)

This package provides support for performing verification and policy synthesis in POMDPs from LTL formulas. It relies on [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) for expressing the model and [Spot.jl](https://github.com/sisl/Spot.jl) for manipulating LTL formulas. 

If this package is useful to you, consider citing: M. Bouton, J. Tumova, and M. J. Kochenderfer, "Point-Based Methods for Model Checking in Partially Observable Markov Decision Processes," in *AAAI Conference on Artificial Intelligence (AAAI)*, 2020.

## Installation 

This package is supported by JuliaPOMDP, it is recommended that you install the JuliaPOMDP registry first and then add the package as follows:
```julia
using Pkg
Pkg.add("POMDPs")
using POMDPs
POMDPs.add_registry()
Pkg.add("POMDPModelChecking")
```

## Documentation 

This package exports two solvers: `ReachabilitySolver` and `ModelCheckingSolver`. Those solvers are intended to be used on models implemented with `POMDPs.jl`, please refer to the `POMDPs.jl` documentation to learn how to implement a POMDP or MDP model using the correct interface.

### Reachability Solver 

The `ReachabilitySolver`  solves reachability and constrained reachability problems in MDPs and POMDPs. It returns the policy that maximizes the probability of reaching a given set of states. It takes as input the set of states to reach and the set of states to avoid, as well as the underlying solver. Any solver from POMDPs.jl are supported.

**Options of the Reachability solver**

- `reach::Set{S}` the set of states to reach, `S` is the state type of your problem.
- `avoid::Set{S}` a set of states to avoid.
- `solver::Solver` the underlying planning algorithm used by the reachability solver. It defaults to `ValueIterationSolver`, you can choose any solver from POMDPs.jl

**Example**

```julia
using POMDPs
using POMDPModelChecking
using POMDPModels
using DiscreteValueIteration

mdp = SimpleGridWorld(size=(10,10), terminate_from=Set([GWPos(9,3)]), tprob=0.7)

solver = ReachabilitySolver(reach=Set([GWPos(10,1)]),
                            avoid = Set([GWPos(9, 3)]), 
                            solver = ValueIterationSolver())

policy = solve(solver, mdp)
```

### Model Checker

The `ModelCheckingSolver` provides a probabilistic model checker for MDPs and POMDPs with LTL specification. The solver takes as input an LTL formula and the underlying MDP/POMDP planning algorithm used to perform the model checking. It supports any solver from `POMDPs.jl`. Internally, this solver requires a discrete state and discrete actions model.

**Labeling function:** A problem dependent labeling function must be implemented by the problem writer. This labelling functions maps states of the MDPs/POMDPs to atomic propositions of the LTL formula that you want to verify. One must implement the function `POMDPModelChecking.labels(problem::M, s::S, a::A)` where `M` is the problem type, `S` the state type of the problem, and `A` the action type. This function must return a tuple of symbols. Each symbol corresponds to the atomic propositions that hold true in this state.

**Example**

```julia
using POMDPs
using Spot # for easy LTL manipulation
using POMDPModelChecking
using SARSOP # a POMDP solver from POMDPs.jl
using RockSample # pomdp model from https://github.com/JuliaPOMDP/RockSample.jl

# Init problem
pomdp = RockSamplePOMDP{3}(map_size=(5,5),
                            rocks_positions=[(2,3), (4,4), (4,2)])


## Probability of getting at least one good rock 

# Implement the labeling function for your problem
# For the rock sample problem, good_rock holds true if the robot is on a good rock location 
# and take the action `sample` (a=5)
# similarly, bad_rock holds true if the robot samples a bad rock
# The exit proposition is true if the robot reached a terminal state
function POMDPModelChecking.labels(pomdp::RockSamplePOMDP, s::RSState, a::Int64)
    if a == 5 && in(s.pos, pomdp.rocks_positions) # sample rock
        rock_ind = findfirst(isequal(s.pos), pomdp.rocks_positions)
        if s.rocks[rock_ind]
            return (:good_rock,)
        else 
            return (:bad_rock,)
        end
    end

    if isterminal(pomdp, s)
        return (:exit,)
    end
    return ()
end

# the property to statisfy, the robot must pick up a good rock, never pick up a bad rock, 
# and leave the environment
prop = ltl"F good_rock & F exit & G !bad_rock"

solver = ModelCheckingSolver(property = prop, 
                      solver=SARSOPSolver(precision=1e-3), verbose=true)

policy = solve(solver, pomdp)
```


**Interface with [Storm](http://www.stormchecker.org/) :**

A writer is already written to convert MDP to the good format, a solver interface has been prototyped, relying on the python library  [stormpy](https://moves-rwth.github.io/stormpy/). The files are in the `legacy/` folder but are only experimental for now.

## Disclaimer

This is still work in progress and could be improved a lot, please submit issues if you encounter. Contributions and PR welcome!
