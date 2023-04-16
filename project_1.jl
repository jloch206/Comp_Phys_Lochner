using Plots, Optim
australia_tourist = [42.20566, 24.64917, 32.66734, 37.25735, 45.24246, 29.35048, 36.34421, 41.78208, 49.27660, 31.27540, 37.85063, 38.83704, 51.23690, 31.83855, 41.32342, 42.79900, 55.70836, 33.40714, 42.31664, 45.15712, 59.57608, 34.83733, 44.84168, 46.97125, 60.01903, 38.37118, 46.97586, 50.73380, 61.64687, 39.29957, 52.67121, 54.33232, 66.83436, 40.87119, 51.82854, 57.49191, 65.25147, 43.06121, 54.76076, 59.83447, 73.25703, 47.69662, 61.09777, 66.05576]

time = collect(2005:0.25:2015.75)
plot(time, australia_tourist, xlabel="Year", ylabel="""Nigth visitors (millions)""", legend=false)

function HW_Seasonal(time_serie, α, β, γ, l0, b0, s0, m)
    N = length(time_serie)
    l_t = 0
    b_t = 0
    l_t_ = 0 #Variable to save l(t-1)
    b_t_ = 0 #Variable to save b(t-1)
    s_ = 0
    s = s0
    
    pred = []

    for i in 0:(N - 1)
        if i == 0
            l_t = l0
            b_t = b0
        else
            l_t = (time_serie[i] - s_) * α + (l_t_ + b_t_) * (1 - α) 
            b_t = β * (l_t - l_t_) + (1 - β) * b_t_
        end
        l_t_ = l_t
        b_t_ = b_t
        s_ = s[i%m + 1]
        
        y_pred = l_t + b_t + s[i%m + 1]
        
        push!(pred, y_pred)
        
        s[i%m + 1] = γ * (time_serie[i + 1] - l_t_ - b_t_) + (1 - γ) * s[i%m + 1]   
    end
    
    return pred
end


function HW_loss(time_serie, α, β, γ, b0, l0, s01,s02,s03,s04)
    s0=[s01,s02,s03,s04]
    m=4
    N = length(time_serie)
    l_t = 0
    b_t = 0
    l_t_ = 0 #Variable to save l(t-1)
    b_t_ = 0 #Variable to save b(t-1)
    s_ = 0
    s = s0
    loss=0
    y_pred=0

    for i in 0:(N - 1)
        if i == 0
            l_t = l0
            b_t = b0
        else
            l_t = (time_serie[i] - s_) * α + (l_t_ + b_t_) * (1 - α) 
            b_t = β * (l_t - l_t_) + (1 - β) * b_t_
        end
        l_t_ = l_t
        b_t_ = b_t
        s_ = s[i%m + 1]
        y_pred = l_t + b_t + s[i%m + 1]
        loss += (time_serie[i+1] - y_pred)^2
        s[i%m + 1] = γ * (time_serie[i + 1] - l_t_ - b_t_) + (1 - γ) * s[i%m + 1]
    end
  return loss
end

  function HW_loss_(params, time_serie=australia_tourist)
    return HW_loss(time_serie, params[1], params[2], params[3],params[4],params[5],params[6],params[7],params[8],params[9])
  end
  

 
lower_ = [0,0,0,0,20,-10,-10,-10,-10]
upper_ = [1,1,1,4,45,10,10,10,10]
initial_x_ = [.1,.5,.5,2,32,0,0,0,0]
    
res2 = optimize(HW_loss_, lower_, upper_, initial_x_)


res1=Optim.minimizer(res2)
prediction=HW_Seasonal(australia_tourist,res1[1],res1[2],res1[3],res1[5],res1[4],res1[6:end],4)

  ###
function HW_Seasonal_forecast(time_serie, α, β, γ, l0, b0, s0, m, n_pred)
    N = length(time_serie)
    l_t = 0
    b_t = 0
    l_t_ = 0 #Variable to save l(t-1)
    b_t_ = 0 #Variable to save b(t-1)
    s_ = 0
    s = s0
    
    pred = []

    for i in 0:(N - 1)
        if i == 0
            l_t = l0
            b_t = b0
        else
            l_t = (time_serie[i] - s_) * α + (l_t_ + b_t_) * (1 - α) 
            b_t = β * (l_t - l_t_) + (1 - β) * b_t_
        end
        l_t_ = l_t
        b_t_ = b_t
        s_ = s[i%m + 1]
        
        y_pred = l_t + b_t + s[i%m + 1]
        
        push!(pred, y_pred)
        
        s[i%m + 1] = γ * (time_serie[i + 1] - l_t_ - b_t_) + (1 - γ) * s[i%m + 1]   
    end
    
    l_t = (time_serie[end] - s_) * α + (l_t + b_t) * (1 - α)
    b_t = β * (l_t - l_t_) + (1 - β) * b_t_
    
    for i in N:(N+n_pred - 1) #sino hace una pred de mas
        y_pred = l_t + b_t*(i-N+1) + s[i%m + 1] 
        #The trend has to be added as many times as periods we want to forecast.
        push!(pred, y_pred)
    end 
    
    return pred
end
season_forecast = HW_Seasonal_forecast(australia_tourist,res1[1],res1[2],res1[3],res1[5],res1[4],res1[6:end], 4, 8)
plot(time, australia_tourist, label="Data", legend=:topleft)
plot!(time, season_forecast[1:44], label="Fitted")
plot!(time[end]:0.25:time[end]+2, season_forecast[44:end], label="Forecast")