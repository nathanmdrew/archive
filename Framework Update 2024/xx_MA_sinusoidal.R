library(ToxicR)

# does ToxicR "fit" sinusoidal data?

x <- seq(from=0, to=4*pi, by=pi/8)
x

# let Y be the sine of X, plus some random noise.  Shift up by 2 to make all values
# positive
y <- sin(x) + rnorm(n=33,mean=0, sd=0.25) + 2

plot(x,y) #the sine pattern is there

mafit <- ToxicR::ma_continuous_fit(D=x, Y=y)
summary(mafit)
plot(mafit)

# most models fit, 4 have non estimable BMDs.
# the weight of the model does not mean the model fits - logistic has a weight
# of 0.417, but this shape is definitely not logistic.

mafit.logistic <- ToxicR::single_continuous_fit(D=x, Y=y, model_type="logistic-aerts",
                                                distribution="normal")

# constant variance is assumed in the MA fits
# 