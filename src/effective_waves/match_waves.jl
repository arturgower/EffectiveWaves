"returns (L, E, im*k^2*w_vec/w), which connect the effective and average wave through α = L*A + im*k^2*w^{-1}*w_vec."
function overlap_arrays(ω::T, wave_effs::Vector{EffectiveWave{T}}, X_match::T, X::AbstractVector{T}, medium::Medium{T}, species::Vector{Specie{T}}; θin::T = 0.0) where T<:Number

    k = ω/medium.c
    hos = union(w.hankel_order for w in wave_effs)
    if length(hos) > 1
        warn("Expected all effective waves to have the same hankel order!")
    end
    ho = minimum(hos)
    S = length(species)

    Z = OffsetArray{Complex{Float64}}(-ho:ho, 1:S);
    for m = 0:ho, l = 1:S
        Z[m,l] = Zn(ω,species[l],medium,m)
        Z[-m,l] = Z[m,l]
    end

    ind_match = findmin(abs.(X .- X_match))[2]
    σ = integration_scheme(X[1:ind_match]; scheme=:trapezoidal) # integration scheme: trapezoidal

    w_vec = (T(2)*k) .*
        [
            sum(
                exp(im*m*(θin - w.θ_eff) + im*X[ind_match]*(w.k_eff*cos(w.θ_eff) - k*cos(θin))/k) *
                species[l].num_density * Z[m,l] *  w.amplitudes[m+ho+1,l]
            for m = -ho:ho, l = 1:S) / (cos(θin)*(w.k_eff*cos(w.θ_eff) - k*cos(θin)))
        for w in wave_effs]

    q_arr = [
        T(2) * (-im)^T(m-1) * species[l].num_density * exp(im*m*θin - im*X[j]*cos(θin)) * Z[m,l] * σ[j] / cos(θin)
    for j = 1:ind_match, m = -ho:ho, l = 1:S]

    return (w_vec, q_arr)
end
