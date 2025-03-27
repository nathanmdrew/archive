### step 1: estimate a LN mean and SD from individual data
### step 2: estimate a LN mean and SD from a histogram and generated data
### step 3: estimate a LN mean and SD from the Sayes et al. 2010 curves



#goal:  10 < x < 200

ln.x <- rnorm(n=1000, mean=log(37), sd=log(1.6))  #could also use rlnorm()
#hist(ln.x)
x <- exp(ln.x)
hist(x)
summary(x) #a little too wide





geometricMean <- function (x) {
  exp(mean(log(x)))
}

geometricSD <- function (x) {
  exp(sqrt(var(log(x))))
}

x <- c(4, 8, 9, 9, 12, 14, 17)

geometricMean(x) #9.579479
geometricSD(x)   #1.600359

# see how well a single estimate of a LogNormal mean and sd goes
set.seed(45226)
ln.x <- rnorm(n=1000, mean=log(37), sd=log(1.6))
x <- exp(ln.x)
hist(ln.x)
hist(x)

geometricMean(x) #36.45908, close to 37
geometricSD(x)   #1.595998, close to 1.6
### so if we have the actual data, we can get close. bootstrapping would probably get closer

all.gmean <- vector(mode="list", length=10000)
all.gsd   <- vector(mode="list", length=10000)

for (ii in 1:10000){
  ln.x <- rnorm(n=1000, mean=log(37), sd=log(1.6))
  x <- exp(ln.x)
  all.gmean[[ii]] <- geometricMean(x)
  all.gsd[[ii]] <- geometricSD(x)
}

gmeans <- unlist(all.gmean)
hist(gmeans)
mean(gmeans) #37.00388
summary(gmeans)

gsds <- unlist(all.gsd)
hist(gsds)
mean(gsds) #1.599941

### so yep, bootstrap is within rounding distance





