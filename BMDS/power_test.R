# generate fake data from a NCV power model
parameters <- c(10, 0.2, 1.7, 1.5, 0.1) # g, b, power, alpha, rho
doses <- c(0, 18, 20, 30, 35, 40)
ex <- data.frame(dose=rep(doses, 5)) %>% arrange(dose)
ex$response <- parameters[1] + parameters[2]*ex$dose^parameters[3] + 
  rnorm(nrow(ex), 
        mean=0, 
        sd=parameters[4]*(parameters[1] + parameters[2]*ex$dose^parameters[3])^parameters[5])
plot(ex$dose, ex$response)


#parameters(g, b, power, alpha, rho)
likelihood.Power.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose^parameters[3],
          parameters[4] * (parameters[1] + parameters[2]*dose^parameters[3])^parameters[5],
          log=T)
  )
}


#parameters(g, b, power, alpha, rho)
bgmean <- ex %>% filter(dose==0) %>% summarize(mean(response))
bgsd <- ex %>% filter(dose==0) %>% summarize(sqrt(var(response)))

opt = optim(
  c(as.numeric(bgmean), 0.02, 1, as.numeric(bgsd), 0.1),  #STARTING VALUES MATTER!
  likelihood.Power.NCV,
  method="L-BFGS-B", #allows bounded parameters
  lower=c(0, 0, 0, 0, -Inf),
  upper=c(max(ex$response)*10, max(ex$dose), 18, sd(ex$response)*3, Inf),
  control = list(trace=T),
  dose=ex$dose,
  response=ex$response
)

opt # pretty damn close
# true: 10          0.2        1.7        1.5        0.1  
# est:  11.1647414  0.1396032  1.7947137  0.8131689  0.2804709

estparam <- c(11.1647414,  0.1396032,  1.7947137,  0.8131689,  0.2804709)
ex$pred <- estparam[1] + estparam[2]*ex$dose^estparam[3] + 
  rnorm(nrow(ex), 
        mean=0, 
        sd=estparam[4]*(estparam[1] + estparam[2]*ex$dose^estparam[3])^estparam[5])

plot(ex$dose, ex$pred, pch=3)
plot(ex$response, ex$pred, pch=3)
abline(0,1)
ex$resid <- ex$response - ex$pred
plot(ex$response, ex$resid, pch=3)
