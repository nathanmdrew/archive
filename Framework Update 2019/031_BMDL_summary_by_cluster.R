library(dplyr)
library(xlsx)
library(readxl)

#Updated Acute Inflammation

d1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\03_cluster_all_pmn_OUTPUT\\final_data.rds")

d1$cluster.Complete <- as.factor(d1$cluster.Complete)
d1$cluster.Ward <- as.factor(d1$cluster.Ward)

d1$BMD <- as.numeric(d1$BMD)
d1$BMDL <- as.numeric(d1$BMDL)

str(d1$BMD)

summary.comp1 <- d1 %>% group_by(cluster.Complete) %>%
                        summarize(n_BMDL=n(),
                                  min_BMDL=min(BMDL),
                                  percentile_5_BMDL=quantile(BMDL,probs = 0.05),
                                  median_BMDL=quantile(BMDL, probs=0.50),
                                  max_BMDL=max(BMDL))


summary.ward1 <- d1 %>% group_by(cluster.Ward) %>%
  summarize(n_BMDL=n(),
            min_BMDL=min(BMDL),
            percentile_5_BMDL=quantile(BMDL,probs = 0.05),
            median_BMDL=quantile(BMDL, probs=0.50),
            max_BMDL=max(BMDL))


out <- bind_rows(summary.comp1, summary.ward1)

#write.csv(out, file="Z:\\ENM Categories\\Framework Update 2019\\031_BMDL_summary_by_cluster_OUTPUT\\summary_BMDL.csv")



# NTP Inflammation

ntp.infl <- read_excel(path="C:\\Users\\vom8\\Desktop\\WFH\\NTP\\_bmd_summary_05sep2018.xlsx", sheet=1)

ntp.fib <-  read.csv(file="C:\\Users\\vom8\\Desktop\\WFH\\NTP\\_bmd_summary_FIBROSIS_12_mar_2020.csv", header=T)

ntp.neo <-  read_excel(path="C:\\Users\\vom8\\Desktop\\WFH\\NTP\\_bmd_summary_05sep2018.xlsx", sheet=3)



ntp.fib$BMDL[is.na(ntp.fib$BMDL)] <- 0

summary.fib <- ntp.fib %>% group_by(HCluster) %>%
  summarize(n_BMDL=n(),
            min_BMDL=min(BMDL),
            percentile_5_BMDL=quantile(BMDL,probs = 0.05),
            median_BMDL=quantile(BMDL, probs=0.50),
            max_BMDL=max(BMDL))

summary.fib$HCluster2[summary.fib$HCluster==1] <- 1
summary.fib$HCluster2[summary.fib$HCluster==2] <- -99
summary.fib$HCluster2[summary.fib$HCluster==3] <- 3
summary.fib$HCluster2[summary.fib$HCluster==4] <- 2
summary.fib$HCluster2[summary.fib$HCluster==5] <- 4

summary.fib <- summary.fib %>% select(-HCluster) %>% rename(HCluster=HCluster2)
summary.fib$Endpoint <- "NTP Fibrosis"

#post hoc - remove anything less than subchronic (4/29/2020)
#2 studies(Cobalt) - indeces 69 and 70
ntp.fib2 <- filter(ntp.fib, index != c(69,70))
summary.fib2 <- ntp.fib2 %>% group_by(HCluster) %>%
  summarize(n_BMDL=n(),
            min_BMDL=min(BMDL),
            percentile_5_BMDL=quantile(BMDL,probs = 0.05),
            median_BMDL=quantile(BMDL, probs=0.50),
            max_BMDL=max(BMDL))

summary.fib2$HCluster2[summary.fib2$HCluster==1] <- 1
summary.fib2$HCluster2[summary.fib2$HCluster==2] <- -99
summary.fib2$HCluster2[summary.fib2$HCluster==3] <- 3
summary.fib2$HCluster2[summary.fib2$HCluster==4] <- 2
summary.fib2$HCluster2[summary.fib2$HCluster==5] <- 4

summary.fib2 <- summary.fib2 %>% select(-HCluster) %>% rename(HCluster=HCluster2)
summary.fib2$Endpoint <- "NTP Fibrosis"


ntp.infl$BMDL[is.na(ntp.infl$BMDL)] <- 0
ntp.infl$BMD <- as.numeric(ntp.infl$BMD)
ntp.infl$BMDL <- as.numeric(ntp.infl$BMDL)
ntp.infl$BMDL[is.na(ntp.infl$BMDL)] <- -99

summary.infl <- ntp.infl %>% group_by(HCluster) %>%
  summarize(n_BMDL=n(),
            min_BMDL=min(BMDL),
            percentile_5_BMDL=quantile(BMDL,probs = 0.05),
            median_BMDL=quantile(BMDL, probs=0.50),
            max_BMDL=max(BMDL))

summary.infl$HCluster[summary.infl$HCluster==5] <- -99

summary.infl$Endpoint <- "NTP Inflammation"



ntp.neo$BMD <- as.numeric(ntp.neo$BMD)
ntp.neo$BMDL <- as.numeric(ntp.neo$BMDL)
ntp.neo$BMDL[is.na(ntp.neo$BMDL)] <- -99

summary.neo <- ntp.neo %>% group_by(HCluster) %>%
  summarize(n_BMDL=n(),
            min_BMDL=min(BMDL),
            percentile_5_BMDL=quantile(BMDL,probs = 0.05),
            median_BMDL=quantile(BMDL, probs=0.50),
            max_BMDL=max(BMDL))

summary.neo$HCluster2[summary.neo$HCluster==1] <- 1
summary.neo$HCluster2[summary.neo$HCluster==2] <- -99
summary.neo$HCluster2[summary.neo$HCluster==3] <- 2
summary.neo$HCluster2[summary.neo$HCluster==4] <- 3
summary.neo$HCluster2[summary.neo$HCluster==5] <- 4
  
summary.neo <- summary.neo %>% select(-HCluster) %>% rename(HCluster=HCluster2)

summary.neo$Endpoint <- "NTP Lung Cell Neoplasia"

out1 <- bind_rows(summary.infl, summary.fib)
out2 <- bind_rows(out1, summary.neo)

out2 <- out2 %>% arrange(Endpoint, HCluster)

#write.csv(out2, file="Z:\\ENM Categories\\Framework Update 2019\\031_BMDL_summary_by_cluster_OUTPUT\\summary_NTP_BMDL.csv")
