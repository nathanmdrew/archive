################################################################################
###     BMDS Continuous Function Likelihoods
###     Nonconstant Variance
################################################################################

# Power
# 𝑚(dose)=𝑔+𝛽×(dose)^𝛿
#parameters(g, b, power, alpha, rho)
likelihood.Power.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose^parameters[3],
          parameters[4] * (parameters[1] + parameters[2]*dose^parameters[3])^parameters[5],
          log=T)
  )
}


# Linear
# 𝑚(dose)=𝑔 + 𝛽 ×dose
#parameters(g, b, alpha, rho)
likelihood.Linear.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose,
          parameters[3] * (parameters[1] + parameters[2]*dose)^parameters[4],
          log=T)
  )
}


# Poly2
# 𝑚(dose)=𝑔 + 𝛽 ×dose +𝛽2×dose^2
#parameters(g, b, b2, alpha, rho)
likelihood.Poly2.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose + parameters[3]*dose^2,
          parameters[4] * (parameters[1] + parameters[2]*dose + parameters[3]*dose^2)^parameters[5],
          log=T)
  )
}


# Poly3
# 𝑚(dose)=𝑔 + 𝛽 ×dose +𝛽2×dose^2+𝛽3×dose^3
#parameters(g, b, b2, b3, alpha, rho)
likelihood.Poly3.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + parameters[2]*dose + parameters[3]*dose^2 + parameters[4]*dose^3,
          parameters[5] * (parameters[1] + parameters[2]*dose + parameters[3]*dose^2 + parameters[4]*dose^3)^parameters[6],
          log=T)
  )
}



# Hill
# 𝑚(dose) = g + [ (v*dose^n) / (k^n + dose^n) ]
#parameters(g, v, n, k, alpha, rho)
likelihood.Hill.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] + ( (parameters[2]*dose^parameters[3]) / (parameters[4]^parameters[3] + dose^parameters[3]) ),
          parameters[5] * (parameters[1] + ( (parameters[2]*dose^parameters[3]) / (parameters[4]^parameters[3] + dose^parameters[3]) ))^parameters[6],
          log=T)
  )
}



# Exponential2
# 𝑚(dose)= a * exp(b*dose)
#parameters(a, b, alpha, rho)
likelihood.Exp2.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] * exp(parameters[2]*dose),
          parameters[3] * (parameters[1] * exp(parameters[2]*dose))^parameters[4],
          log=T)
  )
}


# Exponential3
# 𝑚(dose)= a * exp((b*dose)^d)
#parameters(a, b, d, alpha, rho)
likelihood.Exp3.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] * exp((parameters[2]*dose)^parameters[3]),
          parameters[4] * (parameters[1] * exp((parameters[2]*dose)^parameters[3]))^parameters[5],
          log=T)
  )
}



# Exponential4
# 𝑚(dose)= a * (c-(c-1)*exp(-b*dose))
#parameters(a, b, c, alpha, rho)
likelihood.Exp4.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] * (parameters[3] - (parameters[3]-1) * exp((-1)*parameters[2]*dose)),
          parameters[4] * (parameters[1] * (parameters[3] - (parameters[3]-1) * exp((-1)*parameters[2]*dose)))^parameters[5],
          log=T)
  )
}



# Exponential5
# 𝑚(dose)= a * (c-(c-1)*exp(-b*dose)^d)
#parameters(a, b, c, d, alpha, rho)
likelihood.Exp5.NCV <- function (parameters, dose, response) {
  -sum(
    dnorm(response,
          parameters[1] * (parameters[3] - (parameters[3]-1) * exp((-1)*(parameters[2]*dose)^parameters[4])),
          parameters[5] * (parameters[1] * (parameters[3] - (parameters[3]-1) * exp((-1)*(parameters[2]*dose)^parameters[4])))^parameters[6],
          log=T)
  )
}
