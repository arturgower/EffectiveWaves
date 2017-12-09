# Multi-species effective waves

A Julia library for calculating, processing and plotting effective waves travelling in inhomogeneous materials.

At present, the library focuses on effective wavenumbers and wave reflection from random particulate materials, see ?? for details on the mathematics.

## Get started
This package is tested and works for Julia 0.6 and 0.5.
To get started, download and include the library
```julia
Pkg.clone("https://github.com/arturgower/EffectiveWaves.jl.git")
using EffectiveWaves
```

## Simple example, complete code in [examples/demo.jl](examples/demo.jl)
### Run: calculate effective wavenumbers for two species randomly (uniformly) distributed in Glycerol. List of possible materials given in [src/materials.jl](src/materials.jl).
```julia
#where: ρ = density, r = radius, c = wavespeed, and volfrac = volume fraction
WaterDistilled= Medium(ρ=0.998*1000,  c = 1496.0)
Glycerol      = Medium(ρ=1.26*1000 ,  c = 1904.0)

species = [
    Specie(ρ=WaterDistilled.ρ,r=30.e-6, c=WaterDistilled.c, volfrac=0.1),
    Specie(ρ=Inf, r=100.0e-6, c=2.0, volfrac=0.2)
]
# background medium
background = Glycerol
```

### Calculate effective wavenumbers
```julia

# angular frequencies
ωs = linspace(0.01,1.0,60)*30.0e6
wavenumbers = multispecies_wavenumber(ωs, background, species)

speeds = ωs./real(wavenumbers)
attenuations = imag(wavenumbers)
```

## More examples
For more examples and details go to [examples/](examples/).

## Acknowledgements and contributing
This library was originally written by Artur L Gower.
Please contribute, if nothing else, criticism is welcome, as I am relatively new to Julia.
