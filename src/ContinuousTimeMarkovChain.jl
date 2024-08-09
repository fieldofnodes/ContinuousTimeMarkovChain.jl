module ContinuousTimeMarkovChain   


    using Random
    using StatsBase
    using Base: length

export
    StateSpace,
    State_1,
    State_2,
    State_3,
    States,
    Rates,
    TimeSeries,
    Π,
    SimulationParameters,
    generic_state_update,
    update_single_state,
    get_state_int,
    diff_δ,
    get_rand_state,
    update_state,
    get_simulation, 
    get_simulation_time_series,
    get_simulation_time_to_state_1,
    get_expected_time_to_state_1,
    get_simulation_time,
    all_states,
    all_rates,
    state_distribution


    abstract type StateSpace end
    struct State_1 <: StateSpace end
    struct State_2 <: StateSpace end
    struct State_3 <: StateSpace end
    struct States <: StateSpace 
        s₁ :: State_1
        s₂ :: State_2
        s₃ :: State_3
    end

    

    mutable struct Rates
        s_1_2 :: Union{Int,Float64}
        s_2_3 :: Union{Int,Float64}
        s_3_1 :: Union{Int,Float64}
    end


    

    mutable struct TimeSeries 
        end_time :: Union{Int,Float64}
        time_step :: Float64
    end
        

    mutable struct Π
        π̃::Vector{Float64}
    end

   

    mutable struct SimulationParameters
        time_series :: TimeSeries
        states :: States
        transition_rates :: Rates
        π̃ :: Π
    end



    # Time series functions
    function time_series(ts::TimeSeries)
        range(0,ts.end_time,step = ts.time_step)
    end

    function time_series(sp::SimulationParameters)
        time_series(sp.time_series)
    end
    
    function Δt(ts::TimeSeries)
        ts.time_step
    end

    function Δt(sp::SimulationParameters)
        Δt(sp.time_series)
    end
    
    function Base.length(ts::TimeSeries)
        time_series(ts) |> length
    end

    # States and rates functions
    all_states(s::States) = [s.s₁,s.s₂,s.s₃]
    all_states(sp::SimulationParameters) = all_states(sp.states)
    all_rates(r::Rates) = [r.s_1_2,r.s_2_3,r.s_3_1] 
    all_rates(sp::SimulationParameters) = all_rates(sp.transition_rates)

    # State distribution functions
    state_distribution(p::Π) = p.π̃
    state_distribution(sp::SimulationParameters) = state_distribution(sp.π̃)

    # State update functions
    function generic_state_update(stay_current,transition,rate)
        Random.rand() >= rate ? stay_current : transition
    end

    function update_single_state(::State_1,rate::Rates,ts::TimeSeries)::StateSpace
        generic_state_update(State_1(),State_2(),rate.s_1_2*ts.time_step)
    end

    function update_single_state(::State_2,rate::Rates,ts::TimeSeries)::StateSpace
        generic_state_update(State_2(),State_3(),rate.s_2_3*ts.time_step)
    end

    function update_single_state(::State_3,rate::Rates,ts::TimeSeries)::StateSpace
        generic_state_update(State_3(),State_1(),rate.s_3_1*ts.time_step)
    end

    function get_state_int(state::StateSpace)
        state_string = string(state)
        has_digit = contains(state_string,r"\d")
        has_digit ? parse(Int,match(r"\d",state_string).match) : error("State does not contain a digit")
    end

    function get_rand_state(state::States)
        rand(all_states(state))
    end

    function get_state_vec(state::States)
        all_states(state)
    end

    function draw_weighted_rand(state::States,distribution)
        sample(get_state_vec(state), Weights(distribution))
    end

    diff_δ(x,y) = Int(!(x == y))

    function get_prob_per_state(sp::SimulationParameters)
        πd = state_distribution(sp)
        rates = all_rates(sp)
        π_per_rate = πd ./ rates
        total_π_per_rate = sum(π_per_rate)
        π_per_rate ./ total_π_per_rate
    end

    function get_simulation_time_series(sp::SimulationParameters)
        ts = sp.time_series
        s₁ = sp.states.s₁
        tr = sp.transition_rates
        T = range(0,ts.end_time,step=ts.time_step)
        s = s₁
        states = Int[]
        push!(states,get_state_int(s))
        for t in T
            s = update_single_state(s,tr,ts)
            push!(states,get_state_int(s))
        end
        (T,states[1:end-1])
    end
    


    function get_expected_time_to_state_1(sp::SimulationParameters)
        rates = all_rates(sp)
        prop_per_state = get_prob_per_state(sp)
        starting_s1_time = sum(1 ./ rates)
        starting_s2_time = sum(1 ./ rates[2:3])
        starting_s3_time = sum(1 ./ rates[3])
        rates_times = [starting_s1_time,starting_s2_time,starting_s3_time]
        sum(prop_per_state .* rates_times)
    end




    # Simulation functions
    function get_simulation_time_to_state_1(sp::SimulationParameters)
        # Point is to get to state 1 with no regard to end time 
        end_time = 10_000
        ts = sp.time_series
        dist =  get_prob_per_state(sp)
        s = draw_weighted_rand(sp.states,dist)
        int_s = get_state_int(s)
        state_counter = int_s
        tr = sp.transition_rates
        T = range(0,end_time,step=ts.time_step)
        return_index = []
        states = Int[]
        for i in eachindex(T)
            s = update_single_state(s,tr,ts)
            int_s = get_state_int(s)
            push!(states,int_s)
            state_counter += diff_δ(state_counter,int_s)
            if state_counter == 4 
                push!(return_index,i)
                break
            end
        end
        states_length = length(states)-1
        states_length = states_length == 0 ? 1 : states_length
        (time = T[1:states_length],states = states[1:states_length])
    end







    function update_state(current_state,Δt,transition_rates)
        s_1_2_rate,s_2_3_rate,s_3_4_rate = transition_rates
        r = Random.rand()
        if current_state == 1
            current_state = r < s_1_2_rate*Δt ? 2 : 1
        elseif current_state == 2
            current_state = r < s_2_3_rate*Δt ? 3 : 2
        elseif current_state == 3
            current_state = r < s_3_4_rate*Δt ? 4 : 3
        end
        current_state
    end



    function get_simulation(transition_rates)
        # Single run
        Δt = 0.001
        T = range(0,10_000,step=Δt)
        s =1
        states = Int[]
        for t in T
            s = update_state(s,Δt,transition_rates)
            push!(states,s)
            s == 4 && break
        end
        length_series = length(states)-1
        (T[1:length_series],states[1:length_series])
    end


    function get_simulation_time(simulation)
        simulation[1][end]
    end


end


