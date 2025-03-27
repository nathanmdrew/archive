####
#### Combine control group info from Thomson et al 1986
#### Iteratively combining reference:
####  https://handbook-5-1.cochrane.org/chapter_7/7_7_3_8_combining_groups.htm
####


library(readxl)

profile <- Sys.getenv("USERNAME")

pathin  <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Thomson 1986 Control Group Pooling/")
pathout <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/04_output/")


d <- read_excel(path=paste0(pathin,"data.xlsx"),
                sheet=1,
                col_names=T)

d$rownum <- seq(1:nrow(d))


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


temp <- combinedSampleVariance(6,6,1,1,1,1)


al <- d[1:5,] #Aluminum dust control data
br <- d[11:15,] #Brass dust control data

#initialize Al combined mean
c <- combinedMeans(n=al[1,5],
                   m=al[2,5],
                   mean1=al[1,6],
                   mean2=al[2,6]) 

#initialize Al combined var
v <- combinedSampleVariance(n=al[1,5],
                            m=al[2,5],
                            var1=(al[1,7])^2,
                            var2=(al[2,7])^2,
                            mean1=al[1,6],
                            mean2=al[2,6]) 

#initialize Al combined sample size
n <- al[1,5] + al[2,5]



#loop to iteratively update the combined mean, var, sample size
for (ii in 3:nrow(al)){
  
  ii
  
  c <- combinedMeans(n=n,
                     m=al[ii,5],
                     mean1=c,
                     mean2=al[ii,6])
  c
  
  v <- combinedSampleVariance(n=n,
                              m=al[ii,5],
                              var1=v,
                              var2=(al[ii,7])^2,
                              mean1=c,
                              mean2=al[ii,6])
  v
  
  n <- n + al[ii,5]
  n
  
}

c; v; n;
sqrt(v)

temp <- al[1,]

temp$`Mean of PMN%` <- as.numeric(c)
temp$`SD of PMN%` <- as.numeric(sqrt(v))
temp$n <- as.numeric(n)
temp$Source <- "Table 5 - Pooled"
temp$rownum <- NA

d <- rbind(d, temp)






#initialize Br combined mean
c <- combinedMeans(n=br[1,5],
                   m=br[2,5],
                   mean1=br[1,6],
                   mean2=br[2,6]) 

#initialize Br combined var
v <- combinedSampleVariance(n=br[1,5],
                            m=br[2,5],
                            var1=(br[1,7])^2,
                            var2=(br[2,7])^2,
                            mean1=br[1,6],
                            mean2=br[2,6]) 

#initialize Al combined sample size
n <- br[1,5] + br[2,5]

c; v; n;

#loop to iteratively update the combined mean, var, sample size
for (ii in 3:nrow(br)){
  
  ii
  
  c <- combinedMeans(n=n,
                     m=br[ii,5],
                     mean1=c,
                     mean2=br[ii,6])
  c
  
  v <- combinedSampleVariance(n=n,
                              m=br[ii,5],
                              var1=v,
                              var2=(br[ii,7])^2,
                              mean1=c,
                              mean2=br[ii,6])
  v
  
  n <- n + br[ii,5]
  n
  
}

c; v; n;
sqrt(v)

temp <- br[1,]

temp$`Mean of PMN%` <- as.numeric(c)
temp$`SD of PMN%` <- as.numeric(sqrt(v))
temp$n <- as.numeric(n)
temp$Source <- "Table 4 - Pooled"
temp$rownum <- NA

d <- rbind(d, temp)

saveRDS(d, file=paste0(pathout,"data_out.RDS"))
write.csv(d, file=paste0(pathout, "data_out.csv"))





########
## qc

#generate random numbers using the summary stats from Aluminum
#get new summary stats
#verify loop matches actual overall summary
temp1 <- data.frame(x=rnorm(n=6, mean=1, sd=1))
temp2 <- data.frame(x=rnorm(n=6, mean=3, sd=4))
temp3 <- data.frame(x=rnorm(n=6, mean=2, sd=2))
temp4 <- data.frame(x=rnorm(n=6, mean=1, sd=1))
temp5 <- data.frame(x=rnorm(n=6, mean=1, sd=1))
tempAll <- rbind(temp1,temp2,temp3,temp4,temp5)

test <- data.frame(n=c(6,6,6,6,6), means=c(0,0,0,0,0), stdevs=c(0,0,0,0,0))

test[1,2] <- mean(temp1$x); test[1,3] <- sqrt(var(temp1$x));
test[2,2] <- mean(temp2$x); test[2,3] <- sqrt(var(temp2$x));
test[3,2] <- mean(temp3$x); test[3,3] <- sqrt(var(temp3$x));
test[4,2] <- mean(temp4$x); test[4,3] <- sqrt(var(temp4$x));
test[5,2] <- mean(temp5$x); test[5,3] <- sqrt(var(temp5$x));

testGrandMean <- mean(tempAll$x)
testGrandSD <- sqrt(var(tempAll$x))
testGrandN <- as.numeric(nrow(tempAll))



#initialize test combined mean
c <- combinedMeans(n=test[1,1],
                   m=test[2,1],
                   mean1=test[1,2],
                   mean2=test[2,2]) 

#initialize test combined var
v <- combinedSampleVariance(n=test[1,1],
                            m=test[2,1],
                            var1=(test[1,3])^2,
                            var2=(test[2,3])^2,
                            mean1=test[1,2],
                            mean2=test[2,2]) 
#sqrt(v)
#sqrt(var(tempAll[1:12,]))
#matches

#initialize Al combined sample size
n <- test[1,1] + test[2,1]

c; v; n;

#loop to iteratively update the combined mean, var, sample size
for (ii in 3:nrow(test)){
  
  ii
  
  c <- combinedMeans(n=n,
                     m=test[ii,1],
                     mean1=c,
                     mean2=test[ii,2])
  c
  
  v <- combinedSampleVariance(n=n,
                              m=test[ii,1],
                              var1=v,
                              var2=(test[ii,3])^2,
                              mean1=c,
                              mean2=test[ii,2])
  v
  
  n <- n + test[ii,1]
  n
  
}

c; sqrt(v); n; #PASS! - except std dev is off a bit






