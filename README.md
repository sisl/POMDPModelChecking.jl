# MDPModelChecking.jl

[![Build Status](https://travis-ci.org/MaximeBouton/MDPModelChecking.jl.svg?branch=master)](https://travis-ci.org/MaximeBouton/MDPModelChecking.jl)

[![Coverage Status](https://coveralls.io/repos/MaximeBouton/MDPModelChecking.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/MaximeBouton/MDPModelChecking.jl?branch=master)

[![codecov.io](http://codecov.io/github/MaximeBouton/MDPModelChecking.jl/coverage.svg?branch=master)](http://codecov.io/github/MaximeBouton/MDPModelChecking.jl?branch=master)

This package provides support for performing verification and policy synthesis in POMDP from LTL formulas. It relies on [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) for expressing the model and [Spot.jl](https://github.com/sisl/Spot.jl) for manipulating LTL formulas. 


## Installation 

```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/MaximeBouton/MDPModelChecking.jl"))
```

To install `spot` see https://github.com/sisl/Spot.jl and https://spot.lrde.epita.fr/install.html.

## TODOs

- [ ] Interface with [Storm](http://www.stormchecker.org/) : A writer is already written to convert MDP to the good format, a solver interface has been prototyped, relying on the python library  [stormpy](https://moves-rwth.github.io/stormpy/)
- [ ] Fix terminal state issues: some POMDP solver will set the value at the terminal state to 0 by default, this is not suitable for reachability analysis. This could be handled by adding a sink state.

## Documentation 

### Reachability Solver 


### Model Checker