library(tidyverse)
library(nlme)
library(nlstools)
library(minpack.lm)


#############################################
###   Learn about Stacking
###     Goal: Compare stacked D-R models to MA
###        (1) Fit BMDS models in R
###        (2) See how W&B tested MA (sim. models)
###        (3) Stack

#TiO2 surface area data from W&B2007 Table 1
data1 <- data.frame(dose=c(rep(0,473),
                           rep(0.02,100),
                           rep(0.03,71),
                           rep(0.07,75),
                           rep(0.18,75),
                           rep(0.28,74),
                           rep(1.16,74),
                           rep(1.2,77),
                           rep(1.31,100)), 
                    tumor=c(rep(1,6),rep(0,467),
                            rep(1,2),rep(0,98),
                            rep(1,2),rep(0,69),
                            rep(1,1),rep(0,74),
                            rep(1,1),rep(0,74),
                            rep(1,0),rep(0,74),
                            rep(1,13),rep(0,61),
                            rep(1,12),rep(0,65),
                            rep(1,19),rep(0,81)))

qc <- data1 %>% group_by(dose,tumor) %>% summarize(total=n())


#logistic
logistic <- glm(data=data1, formula=tumor~dose,family="binomial")
summary(logistic) #AIC/param estimates matches BMDS2.7

ggplot(data=data1, aes(x=data1$dose, y=data1$tumor))+
  geom_jitter(height=0.1) +
  geom_smooth(method="glm", method.args=list(family="binomial")) #plot is similar to BMDS2.7


data1$logistic_pred <- predict(logistic,newdata=data1,type="response")


flogistic <- function(int,slope,dose){
  num=1
  den=int+(slope*dose)
  den2=1+exp(-den)
  y=num/den2
  return(y)
}

#flogistic(-4.35335, 2.2577,0)

logistic2 <- nlme(
                  model = tumor ~ flogistic(int,slope,dose),
                  data = data1,
                  fixed = list(int~1, slope~1),
                  random = list(int~1, slope~1),
                  start = list(fixed=c(int=-4.16, slope=2.06)),
                  method = "ML",
                  verbose = TRUE
) #doesn't work

# Sarah suggests nls and nlstools
formulaLogit <- as.formula(tumor ~ 1/(1+exp(-1*(a+b*dose))))
preview(formulaLogit, data = data1, start = list(a=-4, b=2))
logistic3 <- nls(formulaLogit, 
                 start = list(a=-4, b=2),
                 data=data1)
overview(logistic3)
plotfit(logistic3, smooth=TRUE)



#probit
probit <- glm(data=data1, formula=tumor~dose, family="binomial"(link="probit"))
summary(probit) #AIC/param estimates matches BMDS2.7

ggplot(data=data1, aes(x=data1$dose, y=data1$tumor))+
  geom_jitter(height=0.1) +
  geom_smooth(method="glm", method.args=list(family="binomial"(link="probit"))) 
  #plot is similar to BMDS2.7

data1$probit_pred <- predict(probit,newdata=data1,type="response")


#log-logistic
data1$newdose <- data1$dose+1
loglogistic <- glm(data=data1, formula=tumor~log(newdose),family="binomial") #!!! ln(0) - how is it handled?
summary(loglogistic) #AIC/param estimates dont match BMDS2.7


formulaLogLogit <- as.formula(tumor ~ g*(dose>=0) + (dose>0)*(1-g)/(1+exp(-1*(a+b*log(dose)))))
preview(formulaLogLogit, data = data1, start = list(g=0, a=-4, b=2))
loglogistic1 <- nls(formulaLogLogit, 
                 start = list(g=0.1, a=-4, b=3),
                 data=data1,
                 algorithm="port",
                 lower = list(g=0, a=-Inf, b=1),
                 upper = list(g=0.9999999999, a=Inf, b=Inf)
                 )
overview(loglogistic1)
plotfit(loglogistic1, smooth=TRUE)
summary(loglogistic1)

data1$loglogistic_pred <- predict(loglogistic1,newdata=data1,type="response")


#quantal-linear
formulaQuantLin <- as.formula(tumor ~ g + (1-g)*(1-exp(-b*dose)))
preview(formulaQuantLin, data = data1, start = list(g=0, b=0.2))
quantLin1 <- nls(formulaQuantLin, 
                    start = list(g=0, b=0.2),
                    data=data1,
                    algorithm="port",
                    lower = list(g=0, b=-Inf),
                    upper = list(g=0.9999999999, b=Inf)
)
overview(quantLin1)
plotfit(quantLin1, smooth=TRUE)
summary(quantLin1)

data1$quantLin_pred <- predict(quantLin1, newdata=data1, type="response")


#quantal-quad
formulaQuantQuad <- as.formula(tumor ~ g + (1-g)*(1-exp(-b*(dose*dose))))
preview(formulaQuantQuad, data = data1, start = list(g=0, b=0.2))
quantQuad1 <- nls(formulaQuantQuad, 
                 start = list(g=0, b=0.2),
                 data=data1,
                 algorithm="port",
                 lower = list(g=0, b=-Inf),
                 upper = list(g=0.9999999999, b=Inf)
)
overview(quantQuad1)
plotfit(quantQuad1, smooth=TRUE)
summary(quantQuad1)

data1$quantQuad_pred <- predict(quantQuad1, newdata=data1, type="response")



#Weibull
formulaWeib <- as.formula(tumor ~ g + (1-g)*(1-exp(-b*(dose^a))))
preview(formulaWeib, data = data1, start = list(g=0, a=1, b=0.2))
quantWeib1 <- nls(formulaWeib, 
                  start = list(g=0, a=1, b=0.2),
                  data=data1,
                  algorithm="port",
                  lower = list(g=0, a=0.5, b=0),
                  upper = list(g=0.9999999999, a=Inf, b=Inf)
)
overview(quantWeib1)
plotfit(quantWeib1, smooth=TRUE)
summary(quantWeib1)

data1$Weib_pred <- predict(quantWeib1, newdata=data1, type="response")



#MS2
formulaMS2 <- as.formula(tumor ~ g + (1-g)*(1-exp(-a*dose - b*dose*dose)))
preview(formulaMS2, data = data1, start = list(g=0, a=0.1, b=0.1))
MS2 <- nls(formulaMS2, 
                  start = list(g=0, a=0.1, b=0.1),
                  data=data1,
                  algorithm="port",
                  lower = list(g=0, a=0, b=0),
                  upper = list(g=0.9999999999, a=Inf, b=Inf)
)
overview(MS2)
plotfit(MS2, smooth=TRUE)
summary(MS2)

data1$MS2_pred <- predict(MS2, newdata=data1, type="response")


#MS3
formulaMS3 <- as.formula(tumor ~ g + (1-g)*(1-exp(-a*dose - b*dose*dose - c*dose*dose*dose)))
preview(formulaMS3, data = data1, start = list(g=0, a=0.1, b=0.1, c=0.1))
MS3 <- nls(formulaMS3, 
           start = list(g=0, a=0.1, b=0.1, c=0.1),
           data=data1,
           algorithm="port",
           lower = list(g=0, a=0, b=0, c=0),
           upper = list(g=0.9999999999, a=Inf, b=Inf, c=Inf)
)
overview(MS3)
plotfit(MS3, smooth=TRUE)
summary(MS3)

data1$MS3_pred <- predict(MS3, newdata=data1, type="response")




#Gamma
formulaGamma <- as.formula(tumor ~ g + (1-g)*(pgamma(b*dose, a)))
preview(formulaGamma, data = data1, start = list(g=0, a=1.5, b=0.1))
gamma1 <- nls(formulaGamma, 
           start = list(g=0, a=1.5, b=0.1),
           data=data1,
           algorithm="port",
           lower = list(g=0, a=1, b=0),
           upper = list(g=0.9999999999, a=Inf, b=Inf)
)
overview(gamma1)
plotfit(gamma1, smooth=TRUE)
summary(gamma1)

data1$gamma1_pred <- predict(gamma1, newdata=data1, type="response")


#Probit
formulaProbit <- as.formula(tumor ~ pnorm(a + b*dose, mean=0, sd=1))
preview(formulaProbit, data = data1, start = list(a=-4, b=2))
probit1 <- nls(formulaProbit, 
              start = list(a=-4, b=2),
              data=data1
)
overview(probit1)
plotfit(probit1, smooth=TRUE)
summary(probit1)

data1$probit1_pred <- predict(probit1, newdata=data1, type="response")

#LogProbit
formulaLogProbit <- as.formula(tumor ~ g*(dose>=0) + (dose>0)*(1-g)*pnorm(a + b*log(dose), mean=0, sd=1))
preview(formulaLogProbit, data = data1, start = list(g=.01, a=-4, b=7))
logprobit1 <- nls(formulaLogProbit, 
               start = list(g=.01, a=-4, b=7),
               data=data1,
               algorithm="port",
               lower = list(g=0, a=-Inf, b=0.5),
               upper = list(g=0.9999999999, a=Inf, b=Inf)
)
overview(logprobit1)
plotfit(logprobit1, smooth=TRUE)
summary(logprobit1)

data1$logprobit1_pred <- predict(logprobit1, newdata=data1, type="response")





#####################
###   Estimate BMDs

# Added Risk
# BMR = f(BMD) - f(0)
# f(BMD) = BMR + f(0)

# Extra Risk
# BMR = f(BMD) - f(0) / 1 - f(0)
#

stats::logLik
AIC(logprobit1, k=2)
AIC(probit1, k=2)
AIC(gamma1, k=2)
AIC(MS2, k=2)
AIC(MS3, k=2)
AIC(quantWeib1, k=2)
AIC(quantQuad1, k=2)
AIC(quantLin1, k=2)
AIC(loglogistic1, k=2)
