library(tidyverse)
library(nlme)

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

#f.logistic(-4.35335, 2.2577,0)

logistic2 <- nlme(
                  tumor ~ flogistic(a,b,dose),
                  data=data1,
                  fixed=list(a~1, b~1),
                  start=list(fixed=c(a=-4.16, b=2.06)),
                  method="ML",
                  verbose=TRUE
)

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
