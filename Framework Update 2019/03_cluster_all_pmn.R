######################################
###  Cluster
###  
###
###  
###  
###  

library(xlsx)
library(readxl)
library(dplyr)

set.seed(51118) #sully

pod.all <- read.csv(file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\all_pmn_BMDs.csv", header=T)

# HClust - Complete
pod.all <- arrange(pod.all, BMD)
pod.dist <- dist(pod.all$BMD) #Euclidean Distance
pod.clust <- hclust(pod.dist) #complete linkage
pod.cut <- cutree(pod.clust, 4)
plot(pod.clust)
rect.hclust(pod.clust, k=4, border=2:6)
pod.all$cluster.Complete <- pod.cut

pod.cut <- cutree(pod.clust, 5)
plot(pod.clust)
rect.hclust(pod.clust, k=5, border=2:6)

# HClust - Ward
# could use method=ward if pod.dist^2
pod.clust <- hclust(pod.dist, method="ward.D2") #Ward
pod.cut <- cutree(pod.clust, 4)
plot(pod.clust)
rect.hclust(pod.clust, k=4, border=2:6)
pod.all$cluster.Ward <- pod.cut

pod.cut <- cutree(pod.clust, 5)
plot(pod.clust)
rect.hclust(pod.clust, k=5, border=2:6)


d1 <- read_excel(path="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_INPUT\\all_a_b_c.xlsx",
                 sheet=1)

d2 <- left_join(d1, pod.all, by="index")

d3 <- d2 %>% select(-X.y, -X.x, -BMD.y, -BMDL.y) %>%
             rename(BMD=BMD.x) %>%
             rename(BMDL=BMDL.x)

d4 <- filter(d3, !is.na(cluster.Ward))

saveRDS(d4, file="Z:\\ENM Categories\\Framework Update 2019\\03_cluster_all_pmn_OUTPUT\\final_data.rds")






#qc
d4 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\03_cluster_all_pmn_OUTPUT\\final_data.rds")

old <- d4[1:18,]

old <- arrange(old, BMD)
old.dist <- dist(old$BMD) #Euclidean Distance
old.clust <- hclust(old.dist) #complete linkage
old.cut <- cutree(old.clust, 4)
plot(old.clust)
rect.hclust(old.clust, k=4, border=2:6)

old.cut <- cutree(old.clust, 5)
plot(old.clust)
rect.hclust(old.clust, k=5, border=2:6)
