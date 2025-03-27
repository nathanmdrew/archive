# generate log normal data
# estimate parameters

ln.x <- rnorm(n=1000, mean=37, sd=log(5))
hist(ln.x)
x <- exp(ln.x)
hist(x)
median(x)
plot(x)
summary(x)
exp(mean(log(ln.x)))
exp(mean(log(x)))

gam.x <- rgamma(n=1000, shape=6, scale=37/6) #mean = scale*shape, var=shape*scale^2
hist(gam.x)
summary(gam.x)
median(gam.x)
mean(gam.x)


hist(log10(x))

ln.x2 <- log(x)
hist(ln.x2)

est.mean <- mean(ln.x) #0.03
est.mean2 <- mean(x)
est.mean3 <- median(x) #almost 1; ln(1)=0

est.sd <- sqrt(var(ln.x)) #1.003
est.sd2 <- sqrt(var(x)) #1.8387
log(1.8387)

h <- hist(x)

### estimate from density?

gen <- function(start, stop, num) {
  runif(n=num, min=start, max=stop)
}




first <- gen(0, 1, 467)
h$counts[1] #467


maxbreak <- max(h$breaks) #14

#put random values generated for each histogram bar into a list
randx <- vector(mode="list", length=maxbreak)
for (ii in 1:maxbreak){
  randx[[ii]] <- gen(ii-1, ii, h$counts[ii])  
}

randx2 <- unlist(randx)
hist(randx2)

ln.randx2 <- log(randx2)
hist(ln.randx2)
mean(ln.randx2)      #-0.06   - close to 0
sqrt(var(ln.randx2)) #1.27    - kinda close to 1


d <- density(ln.x)
d
plot(d)
mean(d$x)
sqrt(var(d$x))

d <- density(gam.x)
plot(d)
