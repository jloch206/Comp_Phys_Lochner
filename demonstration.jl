using Lux, DiffEqFlux, DifferentialEquations, Optimization, OptimizationOptimJL, Random, Plots, ComponentArrays

rng = Random.default_rng()
u0 = Float32[2.0; 0.0]
datasize = 30
tspan = (0.0f0, 1.5f0)
tsteps = range(tspan[1], tspan[2], length = datasize)

function trueODEfunc(du, u, p, t)
    true_A = [-.1 2.0; -2.0 -0.1]
    du .= ((u.^3)'true_A)'
end
#
prob_trueode = ODEProblem(trueODEfunc, u0, tspan)
ode_data = Array(solve(prob_trueode, Tsit5(), saveat = tsteps))
scatter(ode_data[1,:])
scatter!(ode_data[2,:])
dudt2 = Lux.Chain(x -> x.^3,
                  Lux.Dense(2, 50, relu),
                  Lux.Dense(50, 2))
p, st = Lux.setup(rng, dudt2)
prob_neuralode = NeuralODE(dudt2, tspan, Tsit5(), saveat = tsteps)
#
function predict_neuralode(p)
    Array(prob_neuralode(u0, p, st)[1])
  end
  
  function loss_neuralode(p)
      pred = predict_neuralode(p)
      loss = sum(abs2, ode_data .- pred)
      return loss, pred
  end
  # Callback function to observe training
callback = function (p, l, pred; doplot = true)
    println(l)
    # plot current prediction against data
    if doplot
      plt = scatter(tsteps, ode_data[1,:], label = "X Data")
      scatter!(plt, tsteps, pred[1,:], label = "predicted X data")
      plt2 = scatter(tsteps, ode_data[2,:], label = "Y Data")
      p2=scatter!(plt2,tsteps,pred[2,:],label = "Predicted Y data")
      display(plot(plt, p2, layout=(1,2), legend=true))
    end
    return false
  end
  pinit = ComponentArray(p)
  callback(pinit, loss_neuralode(pinit)...; doplot=true)
  # Train using the ADAM optimizer
adtype = Optimization.AutoZygote()

optf = Optimization.OptimizationFunction((x, p) -> loss_neuralode(x), adtype)
optprob = Optimization.OptimizationProblem(optf, pinit)

result_neuralode = Optimization.solve(optprob,ADAM(0.05),callback = callback,maxiters = 300)
# Retrain using the LBFGS optimizer
optprob2 = remake(optprob,u0 = result_neuralode.u)

result_neuralode2 = Optimization.solve(optprob2,
 Optim.BFGS(initial_stepnorm=0.01),
 callback = callback,allow_f_increases = false)
callback(result_neuralode2.u, loss_neuralode(result_neuralode2.u)...; doplot=true)
