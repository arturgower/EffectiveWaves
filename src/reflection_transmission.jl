"The average reflection coefficient, can return a vector or just one"
function reflection_coefficient(ωs::Union{T,AbstractVector{T}}, medium::Medium{T}, species::Vector{Specie{T}}; kws...) where T<:Number

    k_effs = wavenumber(ωs, medium, species; kws...)
    return reflection_coefficient(ωs, k_effs, medium, species; kws...)
end

"The average reflection coefficients"
reflection_coefficient(ωs::AbstractVector{T}, k_effs::Vector{Complex{T}}, medium::Medium{T}, species::Vector{Specie{T}}; kws...) where T<:Number =
[ reflection_coefficient(ωs[i], k_effs[i], medium, species; kws...) for i in eachindex(ωs)]

"The average reflection coefficient"
function reflection_coefficient(ω::T, k_eff::Complex{T}, medium::Medium{T}, species::Vector{Specie{T}};
        θin::T = 0.0, tol = 1e-8, kws...) where T<:Number

    k = ω/medium.c
    θ_eff = transmission_angle(k, k_eff, θin; tol = tol)
    As = reduced_amplitudes_effective(ω, k_eff, medium, species; tol = tol, θin = θin, kws...)

    θ_ref = pi - θ_eff - θin
    S = length(species)
    ho = Int((size(As,1)-1)/2) # largest hankel order

    R = 2.0im/(k*cos(θin)*(k*cos(θin) + k_eff*cos(θ_eff)))
    R = R*sum(
        exp(im*n*θ_ref)*species[l].num_density*As[n+ho+1,l]*Zn(ω,species[l],medium,n)
    for n=-ho:ho, l=1:S)

    return R
end

"returns a function As, where As(k x) is a an array of the ensemble average scattering amplitudes at depth x inside a halfspace.
Note xs are assumed non-dimensional (just as the rest of the package).
As(k x)[m + M + 1,s] is the m-th hankel order and s-th species average scattering coefficient."
function scattering_amplitudes_effective(ω::T, xs::AbstractVector{T}, medium::Medium{T}, species::Vector{Specie{T}};
        tol = 1e-8,
        k_eff::Complex{Float64} = wavenumber_low_volfrac(ω, medium, species; tol=tol),
        θin=0.0, kws...) where T<:Number

    As_eff = reduced_amplitudes_effective(ω, k_eff, medium, species;
            θin=θin, tol=tol, kws...)

    k = ω/medium.c
    ho = Int(round(size(As_eff,1)/2-1/2))
    S = length(species)
    θ_eff = transmission_angle(k, k_eff, θin; tol=tol)
    As = [
        im^Float64(m)*exp(-im*m*θ_eff)*As_eff[m+ho+1,s]*exp(im*k_eff*cos(θ_eff)*x)
    for x in xs, m=-ho:ho, s=1:S]

    return Scattering_Amplitudes(ho,xs,As)
end

"The average effective transmitted scattering amplitudes for a given effective wavenumber k_eff. Assumes there exists only one k_eff.
The function returns an array A, where
AA(x,y,m,s) = im^m*exp(-im*m*θ_eff)*A[m + max_hankel_order +1,s]*exp(im*k_eff*(cos(θ_eff)*x + sin(θin)*y))
where (x,y) are coordinates in the halfspace, m-th hankel order, s-th species,  and AA is the ensemble average scattering coefficient."
function reduced_amplitudes_effective(ω::T, k_eff::Complex{T}, medium::Medium{T}, species::Vector{Specie{T}};
            tol = 1e-5,
            radius_multiplier = 1.005,
            hankel_order = maximum_hankel_order(ω, medium, species; tol=tol),
            kws...) where T<:Number

        k = ω/medium.c
        S = length(species)
        ho = hankel_order

        as = radius_multiplier*[(s1.r + s2.r) for s1 in species, s2 in species]
        function MM(keff,j,l,m,n)
            (n==m ? 1.0:0.0)*(j==l ? 1.0:0.0) + 2.0pi*species[l].num_density*Zn(ω,species[l],medium,n)*
                Nn(n-m,k*as[j,l],keff*as[j,l])/(k^2.0-keff^2.0)
        end

        # calculate effective amplitudes
        MM_svd = svd(
            reshape(
                [MM(k_eff,j,l,m,n) for m in -ho:ho, j in 1:S, n in -ho:ho, l in 1:S]
            , ((2ho+1)*S, (2ho+1)*S))
        )
        if MM_svd[2][end] > T(10)*tol
            warn("The effective wavenumber gave an eigenvalue $(MM_svd[2][end]), which is larger than the tol = $( T(10)*tol). Note the secular equation is determined by the chosen medium and species.")
        end

        A_null = MM_svd[3][:,end] # eignvector of smallest eigenvalue
        A_null = reshape(A_null, (2*ho+1,S)) # A_null[:,j] = [A[-ho,j],A[-ho+1,j],...,A[ho,j]]

        return A_null.*scale_amplitudes_effective(ω, k_eff, A_null, medium, species; tol = tol, kws...)
end

"returns a number a, such that a*As_eff will cancel an incident wave plane wave with incident angle θin."
function scale_amplitudes_effective(ω::T, k_eff::Complex{T}, As_eff::Array{Complex{T}},
        medium::Medium{T}, species::Vector{Specie{T}};
        hankel_order = Int(size(As_eff,1)/2-1/2),
        θin::T = 0.0, tol = 1e-8) where T<:Number

    k = ω/medium.c
    θ_eff = transmission_angle(k, k_eff, θin; tol = tol)
    ho = hankel_order
    S = length(species)

    sumAs = T(2)*sum(
            exp(im*n*(θin - θ_eff))*Zn(ω,species[l],medium,n)*species[l].num_density*As_eff[n+ho+1,l]
    for n = -ho:ho, l = 1:S)
    a = im*k*cos(θin)*(k_eff*cos(θ_eff) - k*cos(θin))/sumAs

    return a
end