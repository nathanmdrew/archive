library(dplyr)
library(cluster) #kmeans


d1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")



# try 1-10 clusters
c1 <- kmeans(d1$BMD, 1, nstart=25)
c2 <- kmeans(d1$BMD, 2, nstart=25)
c3 <- kmeans(d1$BMD, 3, nstart=25)
c4 <- kmeans(d1$BMD, 4, nstart=25)
c5 <- kmeans(d1$BMD, 5, nstart=25)
c6 <- kmeans(d1$BMD, 6, nstart=25)
c7 <- kmeans(d1$BMD, 7, nstart=25)
c8 <- kmeans(d1$BMD, 8, nstart=25)
c9 <- kmeans(d1$BMD, 9, nstart=25)
c10 <- kmeans(d1$BMD, 10, nstart=25)

rm(wss_values)
wss_values <- c1$tot.withinss
wss_values <- rbind(wss_values, c2$tot.withinss)
wss_values <- rbind(wss_values, c3$tot.withinss)
wss_values <- rbind(wss_values, c4$tot.withinss)
wss_values <- rbind(wss_values, c5$tot.withinss)
wss_values <- rbind(wss_values, c6$tot.withinss)
wss_values <- rbind(wss_values, c7$tot.withinss)
wss_values <- rbind(wss_values, c8$tot.withinss)
wss_values <- rbind(wss_values, c9$tot.withinss)
wss_values <- rbind(wss_values, c10$tot.withinss)
wss_values <- as.data.frame(wss_values)
wss_values$k <- seq(1:10)

#saveRDS(wss_values, file="Z:\\ENM Categories\\Framework Update 2019\\08_kmeans_exploration_OUTPUT\\wss_values.rds")
#wss_values <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\08_kmeans_exploration_OUTPUT\\wss_values.rds")

plot(wss_values$k, wss_values$V1,
     type="b", pch = 19, frame = FALSE, 
     xlab="Number of clusters K",
     ylab="Total within-clusters sum of squares")
# 7 is lowest, but 4 is pretty good



# compare KMEANS4 to the Hierarchical Cluster results (Complete and Ward)
d1$kmean4 <- as.factor(c4$cluster)

#saveRDS(d1, file="Z:\\ENM Categories\\Framework Update 2019\\08_kmeans_exploration_OUTPUT\\d1.rds")
#d1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\08_kmeans_exploration_OUTPUT\\d1.rds")

summary(d1$kmean4)

# KMEANS1 = 1
# KMEANS4 = 2
# KMEANS3 = 3
# KMEANS2 = 4

d1$cluster.KMEAN4 <- as.factor(case_when(d1$kmean4==1 ~ 1,
                               d1$kmean4==4 ~ 2,
                               d1$kmean4==3 ~ 3,
                               d1$kmean4==2 ~4))

compare_complete_kmean <- table(d1$cluster.Complete, d1$cluster.KMEAN4)
compare_complete_kmean

compare_ward_kmean <- table(d1$cluster.Ward, d1$cluster.KMEAN4)
compare_ward_kmean
