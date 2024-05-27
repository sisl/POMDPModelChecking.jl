# POMDPModelChecking.jl

[![Build Status](https://github.com/sisl/POMDPModelChecking.jl/workflows/CI/badge.svg)](https://github.com/sisl/POMDPModelChecking.jl/actions)
[![CodeCov](https://codecov.io/gh/sisl/POMDPModelChecking.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sisl/POMDPModelChecking.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://sisl.github.io/POMDPModelChecking.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://sisl.github.io/POMDPModelChecking.jl/dev)


This package provides support for performing verification and policy synthesis in POMDPs from LTL formulas. It relies on [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) for expressing the model and [Spot.jl](https://github.com/sisl/Spot.jl) for manipulating LTL formulas. 

If this package is useful to you, consider citing: M. Bouton, J. Tumova, and M. J. Kochenderfer, "Point-Based Methods for Model Checking in Partially Observable Markov Decision Processes," in *AAAI Conference on Artificial Intelligence (AAAI)*, 2020.

## Installation 
```julia
using Pkg
Pkg.add("POMDPModelChecking")
```

## Notes

This package exports two solvers: `ReachabilitySolver` and `ModelCheckingSolver`. Those solvers are intended to be used on models implemented with `POMDPs.jl`, please refer to the `POMDPs.jl` documentation to learn how to implement a POMDP or MDP model using the correct interface.


**Interface with [Storm](http://www.stormchecker.org/) :**

A writer is already written to convert MDP to the good format, a solver interface has been prototyped, relying on the python library  [stormpy](https://moves-rwth.github.io/stormpy/). The files are in the `legacy/` folder but are only experimental for now.

## Disclaimer

This is still work in progress and could be improved a lot, please submit issues if you encounter. Contributions and PR welcome!
