library(brms)

#https://paulbuerkner.com/brms/articles/brms_nonlinear.html

b <- c(2, 0.75)
x <- rnorm(100)
y <- rnorm(100, mean = b[1] * exp(b[2] * x))
dat1 <- data.frame(x, y)

prior1 <- prior(normal(1, 2), nlpar = "b1") +
  prior(normal(0, 2), nlpar = "b2")
fit1 <- brm(bf(y ~ b1 * exp(b2 * x), b1 + b2 ~ 1, nl = TRUE),
            data = dat1, prior = prior1)

summary(fit1)

plot(fit1)

plot(conditional_effects(fit1), points = TRUE)

# compare against linear model
fit2 <- brm(y ~ x, data = dat1)
summary(fit2)

pp_check(fit1)
pp_check(fit2)

loo(fit1, fit2) #smaller LOOIC better --> fit 1 best






# ToxicR example

# cont_data           <- matrix(0,nrow=5,ncol=4)
# colnames(cont_data) <- c("Dose","Mean","N","SD")
# cont_data[,1] <- c(0,50,100,200,400)
# cont_data[,2] <- c(5.26,5.76,6.13,8.24,9.23)
# cont_data[,3] <- c(20,20,20,20,20)
# cont_data[,4]<-  c(2.23,1.47,2.47,2.24,1.56)
# Y <- cont_data[,2:4]

y0 <- data.frame(y=rnorm(20, mean=5.26, sd=2.23), x=rep.int(0,20))
y50 <- data.frame(y=rnorm(20, mean=5.76, sd=1.47), x=rep.int(50,20))
y100 <- data.frame(y=rnorm(20, mean=6.13, sd=2.47), x=rep.int(100,20))
y200 <- data.frame(y=rnorm(20, mean=8.24, sd=2.24), x=rep.int(200,20))
y400 <- data.frame(y=rnorm(20, mean=9.23, sd=1.56), x=rep.int(400,20))

d <- rbind(y0,y50,y100,y200,y400)
d

plot(d$x, d$y)

#power prior: https://github.com/NIEHS/ToxicR/blob/main/R/prior_classes.R
# lines 350-357
prior1 <- prior(normal(0, 1), nlpar = "a") +
  prior(normal(0, 1), nlpar = "b") +
  prior(normal(0, 1), nlpar = "g")

# power   a + b*dose^g
fit1 <- brm(bf(y ~ a + b*x^g, a + b + g ~ 1, nl = TRUE),
            data = d, prior = prior1)

summary(fit1)

plot(fit1)

plot(conditional_effects(fit1), points = TRUE)

#other continuous model forms
#https://github.com/NIEHS/ToxicR/blob/main/R/continuous_wrappers.R

#from the ToxicR wiki, logistic fit best
#{"logistic-aerts"}:    \eqn{f(x) = \frac{c}{1 + \exp(-a - b\times x^d)}
