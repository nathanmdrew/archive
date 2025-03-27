library(dplyr)
library(ToxicR)
library(ggplot2)

# response = mean %PMN
data35nm <- data.frame(dose=c(0, 2.4, 3.7, 12.1),
                       response=c(1.04,4.16,16.63,43.04),
                       n=c(4,6,6,6),
                       stdev=c(0.88,1.25,4.7,5.79))

Y35nm <- data35nm[,2:4] #ToxicR with summary data expects Mean, N, SD

data250nm <- data.frame(dose=c(0, 7.2, 11.5, 45.2),
                        response=c(0.95,17.68,38.55,56.56),
                        n=c(4,6,6,6),
                        stdev=c(0.98,1.83,1.66,6.37))

Y250nm <- data250nm[,2:4] #ToxicR with summary data expects Mean, N, SD


# Model Average for the 35nm ZnO
ma35nm <- ToxicR::ma_continuous_fit(data35nm$dose,
                                    Y35nm,
                                    BMR_TYPE="abs",
                                    BMR=4)
summary(ma35nm)
#plot(ma35nm, main="Continuous MA Fitting")
#ggplot(data=ma35nm)


# Model Average for the 250nm ZnO
ma250nm <- ToxicR::ma_continuous_fit(data250nm$dose,
                                 Y250nm,
                                 BMR_TYPE="abs",
                                 BMR=4)
summary(ma250nm)
plot(ma250nm)



# Create a combined dataset; the summary stats for the control group
# need to be pooled appropriately
combinedMeans <- function(n, m, mean1, mean2) {
  #n = size of sample 1
  #m = size of sample 2
  #mean1 = mean of sample 1
  #mean2 = mean of sample 2
  
  (n*mean1 + m*mean2) / (n+m)
}

combinedSampleVariance <- function (n, m, var1, var2, mean1, mean2) {
  #n = size of sample 1
  #m = size of sample 2
  #var1 = variance of sample 1
  #var2 = variance of sample 2
  #mean1 = mean of sample 1
  #mean2 = mean of sample 2
  
  (((n-1)*var1 + (m-1)*var2) / (n+m-1)) + ( (n*m*(mean1-mean2)^2)/((n+m)*(n+m-1)) ) 
}

ctrlMean <- combinedMeans(data35nm[1,3], data250nm[1,3], data35nm[1,2], data250nm[1,2])
ctrlVar <- combinedSampleVariance(data35nm[1,3], data250nm[1,3], 
                                  data35nm[1,4]^2, data250nm[1,4]^2,
                                  data35nm[1,2], data250nm[1,2])
ctrlSD <- sqrt(ctrlVar)

dataCombined <- data.frame(dose=c(0, 2.4, 3.7, 7.2, 11.5, 12.1, 45.2),
                           response=c(ctrlMean,4.16,16.63,17.68,38.55,43.04,56.56),
                           n=c(8,6,6,6,6,6,6),
                           stdev=c(ctrlSD,1.25, 4.7,1.83,1.66,5.79,6.37))
YCombined <- dataCombined[,2:4]

# Model Average for the combined ZnO
maCombined <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                     YCombined,
                                     BMR_TYPE="abs",
                                     BMR=4)
summary(maCombined)
plot(maCombined)




maCombinedMLE <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="mle",
                                        BMR_TYPE="abs",
                                        BMR=4)
summary(maCombinedMLE)

p <- plot(maCombinedMLE)
p$labels$title <- "Continuous MA Fitting"
plot(p)


summary(maCombinedMLE$Individual_Model_1)

singCombinedMLE_expAerts <- ToxicR::single_continuous_fit(dataCombined$dose,
                                                          YCombined,
                                                          model_type="exp-aerts",
                                                          fit_type="laplace",
                                                          BMR_TYPE="abs",
                                                          BMR=4,
                                                          distribution="normal")
AIC_exp5 = -singCombinedMLE_expAerts$maximum + 2*summary(singCombinedMLE_expAerts)$GOF[1,2]
AIC_exp5
temp <- summary(singCombinedMLE_expAerts)
temp$GOF

1/0.048198

ToxicR::single_dichotomous_fit()





# compare fit types
maCombinedMLE <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                           YCombined,
                                           fit_type="mle",
                                           BMR_TYPE="abs",
                                           BMR=4)
maCombined <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="laplace",
                                        BMR_TYPE="abs",
                                        BMR=4,
                                        alpha=0.025)
maCombinedMCMC <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="mcmc",
                                        BMR_TYPE="abs",
                                        BMR=4)
summary(maCombinedMLE) #2.28 (1.60, 3.24) 90.0% CI
summary(maCombined)    #2.28 (1.60, 3.24) 90.0% CI
summary(maCombinedMCMC)#2.28 (1.80, 2.78) 90.0% CI  -  narrower interval
# all BMD estimates the same

ToxicR::single_continuous_fit

maCombined <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="laplace",
                                        BMR_TYPE="abs",
                                        BMR=4,
                                        alpha=0.05)
plot(maCombined)
maCombined <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="laplace",
                                        BMR_TYPE="abs",
                                        BMR=4,
                                        alpha=0.025)
plot(maCombined)
maCombined <- ToxicR::ma_continuous_fit(dataCombined$dose,
                                        YCombined,
                                        fit_type="laplace",
                                        BMR_TYPE="abs",
                                        BMR=4,
                                        alpha=0.005)
plot(maCombined)

# the Summary function only reports 90% intervals, but the lists/plots show the
# specified confidence levels.

