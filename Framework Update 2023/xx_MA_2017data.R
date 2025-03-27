library(ToxicR)
library(dplyr)
library(readxl)

d.2017 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Kriging/Data Correction/NIOSHdosedata_postexp_0_3_v3.xlsx",
                     col_names=T,
                     sheet=1)

all_ma_fits <- vector(mode="list", length=max(d.2017$CaseNumber))

for (ii in 1:max(d.2017$CaseNumber)){
  temp_currentData <- filter(d.2017, CaseNumber==ii)
  
  all_ma_fits[[ii]] <- ToxicR::ma_continuous_fit(D=temp_currentData$dep_dose_amount2,
                                                 Y=temp_currentData$SampPMNPer,
                                                 fit_type="MLE",
                                                 BMR_TYPE="abs",
                                                 BMR=0.04)
  
}

summary(all_ma_fits[[32]])
plot(all_ma_fits[[32]]) #current single model BMD, BMDL = 440.3, 365.33

summary(d.2017$SampPMNPer)


trySumm <- d.2017 %>% filter(CaseNumber==32) %>% group_by(dep_dose_amount2) %>%
                      summarize(meanResp=mean(SampPMNPer),
                                nResp=n(),
                                sdResp=sd(SampPMNPer))

tempFit <- ToxicR::ma_continuous_fit(D=trySumm$dep_dose_amount2,
                                     Y=trySumm[,2:4],
                                     fit_type="MLE",
                                     BMR_TYPE="abs",
                                     BMR=0.04)
summary(tempFit)
plot(tempFit)


tempFit2 <- ToxicR::ma_continuous_fit(D=trySumm[1:3,1],
                                     Y=trySumm[1:3,2:4],
                                     fit_type="MLE",
                                     BMR_TYPE="abs",
                                     BMR=0.04)
summary(tempFit2)
plot(tempFit2)


