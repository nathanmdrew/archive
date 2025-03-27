# fit some bmds models
library(dplyr)

d <- read.delim(file="C:/Users/vom8/OneDrive - CDC/BMDS/continuous2.txt",
                header=F)

d <- d %>% rename(dose=V1, response=V2)

plot(d$dose, d$response)


# looks like steps are to write the likelihood fxn
# optimize
# use

# Power model
# response = g + b*dose^power + e   where e~N(0, sigma)

# generate fake data from a power model
parameters <- c(10, 0.2, 1.7, 2) # g, b, power, sigma
doses <- unique(d$dose)
ex <- data.frame(dose=rep(doses, 5)) %>% arrange(dose)
ex$response <- parameters[1] + parameters[2]*ex$dose^parameters[3] + rnorm(nrow(ex), mean=0, sd=parameters[4])
plot(ex$dose, ex$response)


likelihood.Power <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose^parameters[3],
          parameters[4],
          log=T)
  )
}

likelihood.Power(c(10, 0.2, 1.7, 2),ex$dose, ex$response) #true parameters, 65.18919
likelihood.Power(c(10, 0.3, 1.7, 2),ex$dose, ex$response) # slope off by 0.1, 3946.376
likelihood.Power(c(10, 0.25, 1.7, 2),ex$dose, ex$response) # slope off by 0.05, 1055.853
likelihood.Power(c(as.numeric(bgmean), 0.002, 0, as.numeric(bgsd)),ex$dose, ex$response) # slope off by 0.05, 1055.853

#optimize parameters
bgmean <- ex %>% filter(dose==0) %>% summarize(mean(response))
bgsd <- ex %>% filter(dose==0) %>% summarize(sqrt(var(response)))
opt = optim(
  c(as.numeric(bgmean), 0.002, 1, as.numeric(bgsd)),
  likelihood.Power,
  method="L-BFGS-B", #allows bounded parameters
  lower=c(-9999, -9999, 0, 0),
  upper=c(max(ex$response)*10, max(ex$dose), 18, sd(ex$response)*3),
  dose=ex$dose,
  response=ex$response
  
)

opt # pretty damn close


# try on the BMDS data
bgmean <- d %>% filter(dose==0) %>% summarize(mean(response))
bgsd <- d %>% filter(dose==0) %>% summarize(sqrt(var(response)))

opt = optim(
  c(as.numeric(bgmean), 0.002, 1, as.numeric(bgsd)),
  likelihood.Power,
  method="L-BFGS-B", #allows bounded parameters
  lower=c(-9999, -9999, 0, 0),
  upper=c(max(d$response)*10, max(d$dose), 18, sd(d$response)*3),
  dose=d$dose,
  response=d$response
  
)
opt #pretty close to BMDS
-2*-38.169632 #lower LL here vs BMDS, but this is a slightly different model




#parameters(g, b, power, alpha, rho)
likelihood.Power.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose^parameters[3],
          parameters[4] * (parameters[1] + parameters[2]*dose^parameters[3])^parameters[5],
          log=T)
  )
}

likelihood.Power.NCV(c(10, 0.25, 1.7, 2, 0),ex$dose, ex$response)
likelihood.Power.NCV(c(as.numeric(bgmean), 0.002, 1, as.numeric(bgsd), 0),ex$dose, ex$response)


#optimize parameters
bgmean <- ex %>% filter(dose==0) %>% summarize(mean(response))
bgsd <- ex %>% filter(dose==0) %>% summarize(sqrt(var(response)))

#parameters(g, b, power, alpha, rho)
opt = optim(
  c(as.numeric(bgmean), 0.02, 1, as.numeric(bgsd), 0.1),  #STARTING VALUES MATTER
  likelihood.Power.NCV,
  method="L-BFGS-B", #allows bounded parameters
  lower=c(0, 0, 0, 0, -Inf),
  upper=c(max(ex$response)*10, max(ex$dose), 18, sd(ex$response)*3, Inf),
  control = list(trace=T),
  dose=ex$dose,
  response=ex$response
)

opt # pretty damn close

sd <- 1.51407019*doses^0.08282007
sd
mean(sd)
mean(sd[2:6])





# try on the BMDS data with NCV
bgmean <- d %>% filter(dose==0) %>% summarize(mean(response))
bgsd <- d %>% filter(dose==0) %>% summarize(sqrt(var(response)))

opt = optim(
  c(as.numeric(bgmean), 0.02, 1, as.numeric(bgsd), 0.1),
  likelihood.Power.NCV,
  method="L-BFGS-B", #allows bounded parameters
  lower=c(0, 0, 0, 0, -Inf),
  upper=c(max(d$response)*10, max(d$dose), 18, sd(d$response)*3, Inf),
  control = list(trace=T),
  dose=d$dose,
  response=d$response
)
opt
