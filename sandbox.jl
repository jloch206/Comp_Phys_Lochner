using Plots, Optim
import XLSX
# read data from Excel file
dtable = XLSX.readtable("30_temp.xlsx","30_temp",)
m = hcat(dtable.data...)
data=m[1:end,2]
time = collect(2009:1/12:2022+11/12)
scatter(time[1:48], data[1:48], xlabel="Year", ylabel="Average Monthly Temperature", legend=false)
# New weather data (will be hidden from the function)
real_new_data=[61.08,	63.96,	67.63,	71.41]
# Loss function

function HW_loss(time_serie, α, β, γ, b0, l0, s01,s02,s03,s04,s05,s06,s07,s08,s09,s10,s11,s12)
    s0=[s01,s02,s03,s04,s05,s06,s07,s08,s09,s10,s11,s12]
    m=12
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

  function HW_loss_(params, time_serie=data)
    return HW_loss(time_serie, params[1], params[2], params[3],params[4],params[5],params[6],params[7],params[8],params[9],params[10],params[11],params[12],params[13],params[14],params[15],params[16],params[17])
  end
  

 # Starting parameters and bounds
lower_ = [0,0,0,0,60,-100,-100,-100,-100,-100,-100,-100,-100,-100,-100,-100,-100]
upper_ = [1,1,1,10,80,100,100,100,100,100, 100, 100, 100, 100, 100, 100, 100]
initial_x_ = [.5,.5,.5,2,65,0,0,0,0,0,0,0,0,0,0,0,0]
    # optimizes the loss function
res2 = optimize(HW_loss_, lower_, upper_, initial_x_)
# minimizes parameters
res1=Optim.minimizer(res2)
print(res1)
## Generates forecast

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
n_pred=24
season_forecast = HW_Seasonal_forecast(data,res1[1],res1[2],res1[3],res1[5],res1[4],res1[6:end], 12, n_pred)
# Plot Forecast
pt1=scatter(time[100:end], data[100:end], label="Data", legend=:bottomright)
plot!(pt1,time[100:end], season_forecast[100:length(data)], label="Fitted")
plot!(pt1,time[end]:1/12:time[end]+ n_pred/12, season_forecast[length(data):end], label="Forecast",title="Weather Forecast (monthly)")
## zooming in...
t2=16
pt2=scatter(time[end-t2:end], data[end-t2:end], label="Data", legend=:topright)
plot!(pt2,time[end-t2]:1/12:2023+ 4/12, season_forecast[length(data)-t2:length(data)+5], label="Fitted")
scatter!(pt2,time[end-t2]:1/12:2023+ 4/12, season_forecast[length(data)-t2:length(data)+5], label="Fitted")
scatter!(pt2,2023+1/12:1/12:2023+ 4/12, real_new_data, label="Hidden (actual) data")
display(pt1)