# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.14.4
#   kernelspec:
#     display_name: Julia (6 threads) 1.8.2
#     language: julia
#     name: julia-_6-threads_-1.8
# ---

# ### Set up the geometry

@everywhere function MicroKuboSetup(vertices, edges, therm_runtime, T, 𝒽, isRandom)
    
    if isRandom # initialise entire system in random state
        for edge in edges
            edge.σ = rand(Bool)
        end
    else # initialise entire system in ground state
        GroundState!(vertices, edges)
    end
    
    E = zeros(therm_runtime+1) # just set initial energy to zero since we only need the variance
    
    # thermalise entire system
    for t in 1:therm_runtime
        E[t+1] = E[t]
        for _ in edges
            β = rand(eachindex(edges))
            ΔE = ΔE_flip(vertices, edges, β, 𝒽)

            if ΔE <= 0 || rand(Uniform(0,1)) < exp(-ΔE/T)
                edges[β].σ = !edges[β].σ
                E[t+1] += ΔE
            end
        end
    end
    
    return E[2:end] # cut out initial energy for consistency with other observables
end

# ### Set up the geometry - with magnetisation-conserving stage

@everywhere function MicroKuboSetup_2flip(vertices, edges, therm_runtime, T, 𝒽, isRandom)
    
    if isRandom # initialise entire system in random state
        for edge in edges
            edge.σ = rand(Bool)
        end
    else # initialise entire system in ground state
        GroundState!(vertices, edges)
    end

    
    # thermalise entire system
    E = zeros(therm_runtime+1) # just set initial energy to zero since we only need the variance
    
    for t in 1:therm_runtime
        E[t+1] = E[t]
        for _ in edges
            β = rand(eachindex(edges))
            ΔE = ΔE_flip(vertices, edges, β, 𝒽)

            if ΔE <= 0 || rand(Uniform(0,1)) < exp(-ΔE/T)
                edges[β].σ = !edges[β].σ
                E[t+1] += ΔE
            end
        end
    end
    
    
    # additional thermalisation step at FIXED MAGNETISATION!
    E = zeros(therm_runtime+1) # just set initial energy to zero since we only need the variance
    
    for t in 1:therm_runtime
        E[t+1] = E[t]
        for _ in vertices
            i = rand(eachindex(vertices)) # shared vertex
            𝜷 = sample(vertices[i].δ, 2; replace=true) # two nearest-neighbour spins to flip (in order)
            𝒊 = [edges[𝜷[n]].∂[findfirst(edges[𝜷[n]].∂ .!= i)] for n in 1:2] # outer vertices (but may still coincide)
            
            ΔE = ΔE_2flip(vertices, edges, 𝜷, 𝒊, i, 𝒽)

            if (ΔE <= 0 || rand(Uniform(0,1)) < exp(-ΔE/T)) && edges[𝜷[1]].σ!=edges[𝜷[2]].σ
                edges[𝜷[1]].σ = !edges[𝜷[1]].σ
                edges[𝜷[2]].σ = !edges[𝜷[2]].σ
                
                E[t+1] += ΔE
            end
        end
    end
    
    return E[2:end] # cut out initial energy for consistency with other observables
end

# ### Single spin-flip dynamics routine 

@everywhere function MicroKubo(vertices, edges, runtime, 𝒽)
    J = zeros(Float64, length(vertices[1].x), runtime)
    P = zeros(Float64, length(vertices[1].x), runtime)
    
    for t in 1:runtime
        for _ in edges
            β = rand(eachindex(edges))
            ΔE = ΔE_flip(vertices, edges, β, 𝒽)
            
            if ΔE == 0
                Δj_β = Δj_flip(vertices, edges, β)
                edges[β].σ = !edges[β].σ
            
                # update x-current
                r_β = vertices[edges[β].∂[1]].x - vertices[edges[β].∂[2]].x
                for d in 1:length(r_β) # if vector has any axis displacement > 1, normalise to handle PBCs
                    r_β[d] /= (abs(r_β[d])>1) ? -abs(r_β[d]) : 1
                end
                
                J[:,t] += r_β * Δj_β # note no factor of 1/2 b/c only sum each edge once
            end
        end
        
        
        ϵ0 = 0
        x0 = zeros(length(vertices[1].x))
        for vertex in vertices
            ϵ0 += ϵ(vertices, edges, vertex, 𝒽)
            x0 += vertex.x
        end
        ϵ0 /= length(vertices)
        x0 ./= length(vertices)
        
        for vertex in vertices
            P[:,t] += (vertex.x - x0) * (ϵ(vertices, edges, vertex, 𝒽) - ϵ0)
        end
        
    end
    
    return J, P
end

# ### Double spin-flip dynamics routine

@everywhere function MicroKubo_2flip(vertices, edges, runtime, 𝒽)
    J = zeros(Float64, (length(vertices[1].x), runtime))
    P = zeros(Float64, length(vertices[1].x), runtime)
    
    for t in 1:runtime
        for _ in vertices
            
            # propose flips
            i = rand(eachindex(vertices)) # shared vertex
            𝜷 = sample(vertices[i].δ, 2; replace=true) # two nearest-neighbour spins to flip (in order)
            
            𝒊 = [edges[𝜷[n]].∂[findfirst(edges[𝜷[n]].∂ .!= i)] for n in 1:2] # outer vertices (but may still coincide)
            
            ΣA = 0.5*(1-A(edges, vertices[i])) + 0.5*(1-A(edges, vertices[𝒊[1]])) + 0.5*(1-A(edges, vertices[𝒊[2]]))
            
            # calculate overall energy change and current density between the two unshared vertices
            ΔE = ΔE_2flip(vertices, edges, 𝜷, 𝒊, i, 𝒽)
            Δj = Δj_2flip(vertices, edges, 𝜷, 𝒊, 𝒽)
            
            # decide whether to accept and perform the move
            if ΔE == 0 && edges[𝜷[1]].σ!=edges[𝜷[2]].σ # energy AND magnetisation conserved
                
                edges[𝜷[1]].σ = !edges[𝜷[1]].σ
                edges[𝜷[2]].σ = !edges[𝜷[2]].σ
                
                # get path of current flow
                r_β1 = vertices[i].x - vertices[𝒊[1]].x
                for d in 1:length(r_β1) # if vector has any axis displacement > 1, normalise to handle PBCs
                    r_β1[d] /= (abs(r_β1[d])>1) ? -abs(r_β1[d]) : 1
                end
                
                r_β2 = vertices[𝒊[2]].x - vertices[i].x
                for d in 1:length(r_β2) # if vector has any axis displacement > 1, normalise to handle PBCs
                    r_β2[d] /= (abs(r_β2[d])>1) ? -abs(r_β2[d]) : 1
                end
                
                J[:,t] += (r_β1 + r_β2) * Δj # note no factor of 1/2 b/c only sum each pair of sites once
            end
        end
        
        
        ϵ0 = 0
        x0 = zeros(length(vertices[1].x))
        for vertex in vertices
            ϵ0 += ϵ(vertices, edges, vertex, 𝒽)
            x0 += vertex.x
        end
        ϵ0 /= length(vertices)
        x0 ./= length(vertices)
        
        for vertex in vertices
            P[:,t] += (vertex.x - x0) * (ϵ(vertices, edges, vertex, 𝒽) - ϵ0)
        end
        
    end
    
    return J, P
end

# ### Single Simulation Run

@everywhere function MKuboSingle(vertices, edges, scale, runtime, therm_runtime, t_therm, t_autocorr, N_blocks, t_cutoff, T, 𝒽, allComponents)
    
    Cfun = (E) -> var(E) / T^2 / length(edges)
    κfun = (S) -> mean(S) / T^2 / length(edges)
    Dfun = (E,S) -> κfun(S) / Cfun(E)
    
    tmax = runtime-t_therm
    
    # -- 0. Run Simulation --
    #if twoFlip
    #    E = MicroKuboSetup_2flip(vertices, edges, therm_runtime, T, 𝒽, false)
    #else
    E = MicroKuboSetup(vertices, edges, therm_runtime, T, 𝒽, false)
    #end
        
    M = 0
    for edge in edges
        M += (-1)^edge.σ
    end
    M /= length(edges)
    
    bondNumber = 0
    maxBondNumber = 0
    for vertex in vertices
        z = length(vertex.δ)
        z₋ = 0
        for α in vertex.δ
            z₋ += edges[α].σ ? 1 : 0
        end
        z₊ = z - z₋
        
        bondNumber += z₊*z₋/2
        maxBondNumber += z*(z-1)/2
    end
    ℙ = 1 - bondNumber/maxBondNumber
    
    if twoFlip
        J, P = MicroKubo_2flip(vertices, edges, runtime, 𝒽)
    else
        J, P = MicroKubo(vertices, edges, runtime, 𝒽)
    end
    
    # cut out thermalisation time
    J = J[:,t_therm+1:end]
    P = P[:,t_therm+1:end]
    E = E[t_therm+1:end]
    
    # -- 1. Heat Capacity --
    C_μ, C_s = Estimator(Bootstrap, [E], Cfun, t_autocorr, N_blocks)
    
    # -- 2. Thermal Conductivity and Diffusivity--
    dim = allComponents ? length(vertices[1].x) : 1
    result = zeros(dim, dim, 2, 5)
    
    if allComponents
        statistic = zeros(Float64, tmax, dim, dim)
        for i in 1:dim
            for j in 1:dim
                for t in 1:tmax
                    for τ in 0:min(tmax-t, t_cutoff)
                        # symmetric part: statistic[t,i,j] += (τ==0 ? 0.5 : 1.0) * 0.5 * (J[i,t+τ] * J[j,t] + J[j,t+τ] * J[i,t]) * tmax/(tmax-τ)
                        statistic[t,i,j] += 0.5 * J[i,t+τ] * J[j,t] * tmax/(tmax-τ)
                    end
                    statistic[t,i,j] += 0.5 * J[j,t] * P[i,t]
                end
            end
        end
        #statistic .*= prod(scale) # rescaling to correct for scaling of unit cells

        κ_μ = zeros(dim, dim)
        κ_s = zeros(dim, dim)
        D_μ = zeros(dim, dim)
        D_s = zeros(dim, dim)  
        for i in 1:dim
            for j in 1:dim
                κ_μ[i,j], κ_s[i,j] = Estimator(Bootstrap, [statistic[:,i,j]], κfun, t_autocorr, N_blocks)
                D_μ[i,j], D_s[i,j] = Estimator(Bootstrap, [E, statistic[:,i,j]], Dfun, t_autocorr, N_blocks)
            end
        end
    else
        statistic = zeros(Float64, tmax)
        for t in 1:tmax
            for τ in 0:min(tmax-t, t_cutoff)
                statistic[t] += (τ==0 ? 0.5 : 1.0) * J[1,t+τ] * J[1,t] * tmax/(tmax-τ)
            end
        end
        #statistic .*= prod(scale) # rescaling to correct for scaling of unit cells
        
        κ_μ, κ_s = Estimator(Bootstrap, [statistic], κfun, t_autocorr, N_blocks) # note rescaling b/c propto V
        D_μ, D_s = Estimator(Bootstrap, [E, statistic], Dfun, t_autocorr, N_blocks)
    end
    
    result[:,:,1,1] .= κ_μ
    result[:,:,2,1] .= κ_s.^2
    result[:,:,1,2] .= C_μ
    result[:,:,2,2] .= C_s.^2
    result[:,:,1,3] .= D_μ
    result[:,:,2,3] .= D_s.^2
    result[:,:,1,4] .= abs.(M)
    result[:,:,1,5] .= ℙ
    
    return result
end

# +
#κ_μ = 0
#κ_s = 0
#D_μ = 0
#D_s = 0
#for τ in 0:t_cutoff
#    statistic = (τ==0 ? 0.5 : 1.0) .* J[1,:] .* circshift(J[1,:], -τ)
#    statistic /= length(statistic)
#    
#    tmp1, tmp2 = Estimator(Bootstrap, [statistic[1:end-τ]], κfun, t_autocorr, N_blocks)
#    κ_μ += tmp1
#    κ_s += tmp2
#    
#    tmp1, tmp2 = Estimator(Bootstrap, [E[1:end-τ], statistic[1:end-τ]], Dfun, t_autocorr, N_blocks)
#    D_μ += tmp1
#    D_s += tmp2
#end
# -

# ### Overall simulation routine

function MKuboSimulation(L, PBC, Basis, num_histories, runtime, therm_runtime, t_therm, t_autocorr, N_blocks, t_cutoff, T, 𝒽, allComponents)
    
    vertices, edges, scale = LatticeGrid(L, PBC, Basis)
    
    ks = range(1,length(T)*length(𝒽)*num_histories)
    args = [[deepcopy(vertices), deepcopy(edges), scale, runtime, therm_runtime, t_therm, t_autocorr, N_blocks, t_cutoff, T[div(div(k-1,num_histories),length(𝒽))+1], 𝒽[rem(div(k-1,num_histories),length(𝒽))+1], allComponents] for k=ks]
    
    function hfun(args)
        return MKuboSingle(args...)
    end
    
    
    if multiProcess
        results = pmap(hfun, args)
    else
        results = Array{Any}(undef, length(ks))
        Threads.@threads for k in ks
            results[k] = hfun(args[k])
        end
    end 
    
    dim = allComponents ? length(vertices[1].x) : 1
    tmp = zeros(dim, dim, 2, 5, length(T), length(𝒽), num_histories) # rows for mean and stdv of κ,C
    for k in ks
        ni,h = divrem(k-1,num_histories) .+ (1,1)
        n,i = divrem(ni-1,length(𝒽)) .+ (1,1)
        
        tmp[:,:,:,:,n,i,h] = results[k]
    end
    
    # average over observables for all histories - okay b/c iid random variables
    tmp = sum(tmp, dims=7)
    tmp[:,:,2,:,:,:] = sqrt.(tmp[:,:,2,:,:,:])
    tmp ./= num_histories
        
    return tmp[:,:,1,1,:,:], tmp[1,1,1,2,:,:], tmp[:,:,1,3,:,:], tmp[1,1,1,4,:,:], tmp[1,1,1,5,:,:], tmp[:,:,2,1,:,:], tmp[1,1,2,2,:,:], tmp[:,:,2,3,:,:], tmp[1,1,2,4,:,:], tmp[1,1,2,5,:,:]
end
