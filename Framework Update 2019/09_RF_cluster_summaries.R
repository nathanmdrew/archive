library(dplyr)
library(ggplot2)
library(randomForest)

set.seed(51118) #sully

########################
###   Distribution of pchem variables by cluster across the 3 models (Complete, Ward, OoM)
###   Partial dependence plots

# Load random forests and main dataset
rf.complete <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_complete2.rds")
rf.ward <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_ward2.rds")
rf.oom <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\rf_oom1.rds")

d <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")

d2 <- d

d2$cluster.OOM <- as.factor(case_when(d2$BMDL < 0.01 ~ "< 0.01 ug/g lung",
                                       d2$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
                                       d2$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
                                       d2$BMDL < 10 ~ "1 - 10 ug/g lung",
                                       d2$BMDL < 100 ~ "10 - 100 ug/g lung",
                                       d2$BMDL < 1000 ~ "100 - 1000 ug/g lung",
                                       d2$BMDL < 10000 ~ "1000 - 10000 ug/g lung"))
names(d2)


summ.all <- summary(d2, maxsum=100)
write.csv(summ.all, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_all.csv")


# Summary of pchem by cluster for Complete
summ1 <- d2 %>% filter(cluster.Complete=="1")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_complete_1.csv")

summ1 <- d2 %>% filter(cluster.Complete=="2")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_complete_2.csv")

summ1 <- d2 %>% filter(cluster.Complete=="3")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_complete_3.csv")

summ1 <- d2 %>% filter(cluster.Complete=="4")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_complete_4.csv")


# Summary of pchem by cluster for Ward
summ1 <- d2 %>% filter(cluster.Ward=="1")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_ward_1.csv")

summ1 <- d2 %>% filter(cluster.Ward=="2")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_ward_2.csv")

summ1 <- d2 %>% filter(cluster.Ward=="3")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_ward_3.csv")

summ1 <- d2 %>% filter(cluster.Ward=="4")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_ward_4.csv")


# Summary of pchem by cluster for OoM
summ1 <- d2 %>% filter(cluster.OOM=="< 0.01 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_1.csv")

summ1 <- d2 %>% filter(cluster.OOM=="0.01 - 0.1 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_2.csv")

summ1 <- d2 %>% filter(cluster.OOM=="0.1 - 1.0 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_3.csv")

summ1 <- d2 %>% filter(cluster.OOM=="1 - 10 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_4.csv")

summ1 <- d2 %>% filter(cluster.OOM=="10 - 100 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_5.csv")

summ1 <- d2 %>% filter(cluster.OOM=="100 - 1000 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_6.csv")

summ1 <- d2 %>% filter(cluster.OOM=="1000 - 10000 ug/g lung")
temp <- summary(summ1, maxsum=100)
write.csv(temp, file="Z:\\ENM Categories\\Framework Update 2019\\08_RF_cluster_summaries_OUTPUT\\summary_oom_7.csv")

