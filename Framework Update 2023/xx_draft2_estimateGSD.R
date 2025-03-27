library(ggplot2)
library(dplyr)

fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a_avg2.csv",
                  header=F)

fig2a$V2[fig2a$V2 < 0] <- 0
fig2a <- arrange(fig2a, V1)

plot(fig2a$V1, fig2a$V2)
str(fig2a)

fig2a$shift <- fig2a$V1 - min(fig2a$V1)
a <- dnorm(x=fig2a$V1, mean=log(37), sd=log(1.6))
fig2a$ln1 <- log(a)
plot(fig2a$V1, fig2a$ln1, type="l")


x <- seq(from=-4, to=4, by=0.1)
y <- dnorm(x=x, mean=0, sd=1)
plot(x, y, type="l")

m <- 37
s <- 20
x <- seq(from=0, to=250, by=0.1)
y <- dlnorm(x, meanlog=log(m^2 / sqrt(s^2 + m^2)), sdlog=sqrt(log(1 + (s^2 / m^2))))
plot(x, y, type="l")


fig2a$cumulative <- cumsum(fig2a$V2)
plot(x=fig2a$V1, y=fig2a$cumulative)

fig2a$cumulative <- cumsum(fig2a$V2)
plot(x=fig2a$V1, y=fig2a$cumulative) #lognormal CDF?
plot(x=log(fig2a$V1), y=fig2a$cumulative) #normal CDF?


foo <- function(parms, x, y) {
  sum((pnorm(x, mean = parms[1], sd = parms[2]) - y)^2)
}

fit <- optim(c(10, 5), 
             fn = foo, 
             x = log(fig2a$V1), 
             y = fig2a$cumulative)

fit
#3.6109179 0.4700036

estmean <- exp(fit$par[1])
estsd <- exp(fit$par[2])

xx <- seq(min(log(fig2a$V1)), max(log(fig2a$V1)), length.out = 73)
fitted <- pnorm(xx, fit$par[1], fit$par[2])

dat2 <- data.frame(a = xx, prop = fitted)

theme_set(theme_bw())
ggplot(data = fig2a, aes(x = log(fig2a$V1), y = fig2a$cumulative)) + geom_point(size = 3) +
  geom_line(data = dat2, size = 1, colour = "steelblue")

d<-density(fig2a$V2)
plot(d)

fig2a$V3 <- round((fig2a$V2 / sum(fig2a$V2)), 4)

genrand <- vector(mode="list", length=nrow(fig2a)-1)
for (ii in 2:nrow(fig2a)){
  genrand[[ii-1]] <- runif(n=fig2a[ii,3]*10000, min=fig2a[ii-1,1], max=fig2a[ii,1])
}
genrand2 <- unlist(genrand)
hist(genrand2)

geometricMean <- function (x) {
  exp(mean(log(x)))
}

geometricSD <- function (x) {
  exp(sqrt(var(log(x))))
}

geometricMean(genrand2)
geometricSD(genrand2)



allRand <- vector(mode="list", length=10000)
allGMean <- vector(mode="list", length=10000)
allGSD <- vector(mode="list", length=10000)

for (jj in 1:10000) {
  
  genrand <- vector(mode="list", length=nrow(fig2a)-1)
  for (ii in 2:nrow(fig2a)){
    genrand[[ii-1]] <- runif(n=fig2a[ii,3]*10000, min=fig2a[ii-1,1], max=fig2a[ii,1])
  }
  genrand2 <- unlist(genrand)
  
  
  
  allRand[[jj]] <- genrand2
  allGMean[[jj]] <- geometricMean(genrand2)
  allGSD[[jj]] <- geometricSD(genrand2)
}

temp <- unlist(allGMean)
hist(temp)
mean(temp) #40.14204
summary(temp)

temp2 <- unlist(allGSD)
hist(temp2)
mean(temp2) #1.696957
summary(temp2)



x <- rnorm(n=10000, mean=log(mean(temp)), sd=log(mean(temp2)))
hist(x)
ln.x <- log(x)
hist(ln.x)


#old

fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a.csv",
                  header=T)
plot(fig2a)
plot(x=log10(fig2a$x), y=fig2a$y)

fig2a.2 <- fig2a
fig2a.2$y[fig2a.2$y < 0] <- 0

summary(fig2a$y)
summary(fig2a.2$y)

plot(fig2a.2)
l <- loess(y~x, fig2a.2)
plot(l)

fig2a.2$pred <- predict(l, fig2a.2$x)
plot(x=fig2a.2$x, y=fig2a.2$pred)



l <- loess(y~x, fig2a.2, degree=3)
fig2a.2$pred <- predict(l, fig2a.2$x)
plot(x=fig2a.2$x, y=fig2a.2$pred)


fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a_avg.csv",
                  header=F)
plot(x=fig2a$V1, y=fig2a$V2, type="b")

s <- sum(fig2a$V2)
fig2a$y2 <- fig2a$V2/s
fig2a$y3 <- round(fig2a$y2, digits=3)

test1 <- runif(n=fig2a[2,4]*1000, min=fig2a[1,1], max=fig2a[2,1])
rm(test1)

genrand <- vector(mode="list", length=nrow(fig2a)-1)
for (ii in 2:nrow(fig2a)){
  genrand[[ii-1]] <- runif(n=fig2a[ii,4]*1000, min=fig2a[ii-1,1], max=fig2a[ii,1])
}
genrand2 <- as.data.frame(x=unlist(genrand))
hist(genrand2)

genrand3 <- log(genrand2)
hist(genrand3)
exp(mean(genrand3))
exp(sqrt(var(genrand3)))

ggplot(data=genrand2, aes(x=log10(`unlist(genrand)`))) +
  geom_histogram()





fig2a <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Sayes2010_Fig2a_autodetectGreen.csv",
                  header=F)
plot(x=fig2a$V1, y=fig2a$V2, type="p")
fig2a$V2[fig2a$V2 < 0] <- 0

s <- sum(fig2a$V2)
fig2a$y2 <- fig2a$V2/s
fig2a$y3 <- round(fig2a$y2, digits=4)

plot(x=fig2a$V1, y=fig2a$y3, type="p")

genrand <- vector(mode="list", length=nrow(fig2a)-1)
for (ii in 2:nrow(fig2a)){
  genrand[[ii-1]] <- runif(n=fig2a[ii,4]*10000, min=fig2a[ii-1,1], max=fig2a[ii,1])
}
genrand2 <- as.data.frame(x=unlist(genrand))
names(genrand2) <- c("x")
genrand2$x <- as.numeric(genrand2$x)
hist(genrand2$x)
summary(genrand2$x)
ggplot(data=genrand2, aes(x=x)) +
  geom_histogram(na.rm=T)

genrand3 <- log(genrand2$x)
hist(genrand3)
exp(mean(genrand3), na.rm=T)
exp(sqrt(var(genrand3)), na.rm=T)

