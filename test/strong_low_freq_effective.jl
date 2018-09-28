# This case is numerically challenging, because wavenumber() has many roots close together. Make sure spacing in ωs is small to help the optimisation method
@testset "strong scatterers and low frequency" begin
    medium = Medium(1.0,1.0+0.0im)
    species = [
        Specie(ρ=5.,r=0.004, c=0.002, volfrac=0.2),
        Specie(ρ=0.3, r=0.002, c=0.01, volfrac=0.1)
    ]
    tol=1e-7
    # ωs = [0.001,0.003]
    ωs = [0.001]
    eff_medium = effective_medium(medium, species)
    k_eff_lows = ωs./eff_medium.c

    k_eff_φs = wavenumber_low_volfrac(ωs, medium, species)
    # small mesh_size keeps all solutions close to the initial guess
    wavenumbers_path(ω, medium, species; tol = tol, num_wavenumbers=1)

    k_effs_arr = [
        wavenumbers(ω, medium, species; tol=tol, num_wavenumbers=1)
    for ω in ωs]

    inds = [indmin(abs.(k)) for k in (k_effs_arr .- k_eff_φs)]
    k_effs2 = [k_effs_arr[i][inds[i]] for i in eachindex(inds)]
    # k_effs = wavenumber(ωs, medium, species)

    @test norm(k_effs2 - k_eff_lows)/norm(k_effs2) < 5e-7
    @test norm(k_effs2[1] - k_eff_lows[1])/norm(k_eff_lows[1]) < 5e-7
    @test norm(k_effs2 - k_eff_φs)/norm(k_effs2) < 0.01
end
