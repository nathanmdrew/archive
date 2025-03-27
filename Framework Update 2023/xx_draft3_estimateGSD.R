
###### generate points on a standard normal PDF and CDF
x <- seq(from=-5, to=5, by=0.1)
y <- dnorm(x) #true mean=0, true sd=1
plot(x, y) #standard normal PDF
cumy <- cumsum(y)
summary(cumy)
plot(x, cumy) #standard normal CDF


##### fit the PDF, estimate the mean and sd

foo <- function(parms, x, y) {
  sum((y - dnorm(x, mean = parms[1], sd = parms[2]))^2)
}

fit <- optim(c(3, 2), 
             fn = foo, 
             x = x, 
             y = y)

fit
#$par
#[1] 2.082008e-05 9.999269e-01
# close to (0, 1)

xx <- seq(min(x), max(x), length.out = 101)
fitted <- dnorm(xx, fit$par[1], fit$par[2])

dat2 <- data.frame(a = xx, prop = fitted)

dat <- data.frame(x=x, y=y)

theme_set(theme_bw())
ggplot(data = dat, aes(x = x, y = y)) + geom_point(size = 3) +
  geom_line(data = dat2, size = 1, colour = "steelblue")








####### try the Sayes data
fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a_avg2.csv",
                  header=F)

fig2a$V2[fig2a$V2 < 0] <- 0
fig2a <- arrange(fig2a, V1)
names(fig2a) <- c("x", "y")
plot(log(fig2a$x), fig2a$y)

fig2a$cumy <- cumsum(fig2a$y)
fig2a$cumy_rescale <- fig2a$cumy / max(fig2a$cumy)
fig2a$y_rescale <- fig2a$y / max(fig2a$y)

plot(log(fig2a$x), fig2a$cumy_rescale)

foo <- function(parms, x, y) {
  sum((y - pnorm(x, mean = parms[1], sd = parms[2]))^2)
}


pnorm(0)
x <- seq(from=2, to=6, by=0.1)
y <- pnorm(x, mean=3.7, sd=0.6)
plot(x,y)


#m <- 37
#s <- 1.6
#meanlog=log(m^2 / sqrt(s^2 + m^2))
#sdlog=sqrt(log(1 + (s^2 / m^2)))

fit <- optim(c(3, 2), 
             fn = foo, 
             x = log(fig2a$x), 
             y = fig2a$cumy_rescale)

fit
exp(fit$par[1])
exp(fit$par[2])

#xx <- seq(min(log(fig2a$x)), max(log(fig2a$x)), length.out = 73)
fig2a$fitted <- pnorm(log(fig2a$x), fit$par[1], fit$par[2])
plot(log(fig2a$x), fig2a$fitted)

dat2 <- data.frame(x = xx, y = fitted)

theme_set(theme_bw())
ggplot(data = fig2a, aes(x = log(x), y = fig2a$cumy_rescale)) + geom_point(size = 3) +
  geom_line(data = fig2a, aes(x=log(x), y=fitted), size = 1, colour = "steelblue")



qc <- rnorm(1000, mean=fit$par[1], sd=fit$par[2])
plot(exp(qc), pnorm(qc))
plot(fig2a$x, fig2a$y)
