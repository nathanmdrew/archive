#Explore how to combine summary statistics for a dose group from two studies

set.seed(90210)

# generate some data to explore
# Normal distribution just for fun
# means and sds are just the  stats from the dataset, any values could be used
set1 <- data.frame(x=rnorm(n=4, mean=1.04, sd=0.88))
set2 <- data.frame(x=rnorm(n=4, mean=0.95, sd=0.98))

summary(set1) #mean=1.4350
summary(set2) #mean=0.7394

combined <- rbind(set1, set2)
summary(combined) #mean=1.0872

# Since these were independent experiments, the combined sample size
# will just be the sum of the two sample sizes
# 4+4 = 8


# the means can be combined just by taking the average of the means
# if the sample sizes were different, a weighted mean would be used
(mean(set1$x) + mean(set2$x))/2
mean(combined$x)
#these match, so the combined mean=1.0872

# a more general formula in case sample sizes are different
combinedMeans <- function(n, m, mean1, mean2) {
  #n = size of sample 1
  #m = size of sample 2
  #mean1 = mean of sample 1
  #mean2 = mean of sample 2
  
  (n*mean1 + m*mean2) / (n+m)
}

combinedMeans(n=4, m=4, mean1=mean(set1$x), mean2=mean(set2$x))
#1.087176, again matches the mean of the combined data set


#standard deviations are not as straightforward
#one CANNOT simply average the individual standard deviations
sqrt(var(set1$x)) #sd = 0.9538759
sqrt(var(set2$x)) #sd = 0.4285886
sqrt(var(combined$x)) #sd = 0.7790581

(sqrt(var(set1$x)) + sqrt(var(set2$x)))/2 #incorrect --- sd=0.6912323

#instead we need to deal with variances
#it's a complex combination
#https://math.stackexchange.com/questions/2971315/how-do-i-combine-standard-deviations-of-two-groups

combinedSampleVariance <- function (n, m, var1, var2, mean1, mean2) {
  #n = size of sample 1
  #m = size of sample 2
  #var1 = variance of sample 1
  #var2 = variance of sample 2
  #mean1 = mean of sample 1
  #mean2 = mean of sample 2
  
  (((n-1)*var1 + (m-1)*var2) / (n+m-1)) + ( (n*m*(mean1-mean2)^2)/((n+m)*(n+m-1)) ) 
}

var.combined <- combinedSampleVariance(4,4,var(set1$x),var(set2$x),mean(set1$x), mean(set2$x))
var.combined #0.6069

var(combined$x) #0.6069 - so we have a match

#however we do still want the combined standard deviation
sd.combined <- sqrt(var.combined) #0.7790581





ho.var <- combinedSampleVariance(4, 4, 0.88^2, 0.98^2, 1.04, 0.95)
sqrt(ho.var)
(1.04+0.95)/2
