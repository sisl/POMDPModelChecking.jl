using Pkg
packages = keys(Pkg.installed())
if !in("Spot", packages)
    Pkg.add(PackageSpec(url="https://github.com/sisl/Spot.jl.git"))
end