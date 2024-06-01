using Statistics

function sim(pomdp::POMDP, policy::ModelCheckingPolicy, i::Int64)
    up = DiscreteUpdater(pomdp)
    b0 = initialize_belief(up, initialstate(pomdp))
    hr = HistoryRecorder(max_steps=50, rng=MersenneTwister(i))
    hist = simulate(hr, pomdp, policy, up, b0)
    return hist
end

function many_sims(pomdp::POMDP, policy::ModelCheckingPolicy, n_sims::Int64 = 100)
    successes = zeros(Int64, n_sims)
    mu = zeros(n_sims - 1)
    sig = zeros(n_sims - 1)
    successes = @showprogress pmap(1:n_sims) do x 
                            hist = sim(pomdp, policy, x)
                            return undiscounted_reward(hist) > 0.
                end
                        
    # @showprogress for i=1:n_sims
    #     hist = sim(pomdp, policy)
    #     successes[i] = undiscounted_reward(hist) > 0.
    #     if i > 1
    #         mu[i-1], sig[i-1] = leave_one_out_mean_estimate(successes[1:i])
    #         println("mean: ", mu[i-1], " sig ", sig[i-1])
    #     end
    # end
    mu, sig = running_stats(successes)
    return successes, mu, sig
end

function running_stats(vec)
    mu = zeros(length(vec) - 1)
    sig = zeros(length(vec) - 1)
    for i=2:length(vec)
        mu[i-1], sig[i-1] = leave_one_out_mean_estimate(vec[1:i])
    end
    return mu, sig
end

function leave_one_out_mean_estimate(vec)
    means = zeros(length(vec))
    for i=1:length(vec)
        means[i] = mean(vec[j] for j=1:length(vec) if j != i)
    end
    return mean(means), std(means)/sqrt(length(vec))
end
