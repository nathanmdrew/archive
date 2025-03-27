#############################################
###   Explore different linkage methods
###   for the expanded acute inflammation data
###

library(xlsx)
library(readxl)
library(dplyr)
library(cluster) #kmeans
library(FSA) #Dunn post-hoc for KruskalWallis
library(ggplot2)

set.seed(473366) #king gizzard and the lizard wizard

#Theresa/Alyssa BMDs
# mg/g lung

pod.a1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\TEB Finalized BMDs\\Finalized_BMDs.xlsx",
                    sheet=3)

pod.a1$BMD <- pod.a1$BMD.est. * 1000
pod.a1$index <- seq(1:58)

#Previous Framework BMDs
# ug/g lung
pod.b1 <- read.csv(file="Z:\\ENM Categories\\_Final_Kriging_BMDs_BMR4_12oct2016.csv", header=T)

pod.b1$index <- seq(1:18) + 58


pod.a2 <- select(pod.a1, index, BMD)
pod.b2 <- select(pod.b1, index, BMD)


pod.all <- rbind(pod.a2,pod.b2)

# EDA
eda.summ <- summary(pod.all$BMD)


# Hierarchical Cluster
# 4 groups, default distance, default linkage
pod.all <- arrange(pod.all, BMD)

pod.dist <- dist(pod.all$BMD) #Euclidean, Maximum, Manhattan, Canberra, Binary, Minkowski

pod.clust <- hclust(pod.dist) #complete linkage
pod.cut <- cutree(pod.clust, 4)

plot(pod.clust)
rect.hclust(pod.clust, k=4, border=2:6)

pod.all$cluster <- pod.cut

#write.csv(pod.all, file="Z:\\ENM Categories\\Framework Update 2019\\clusters_2019_10_22.csv")


# What do 5 clusters look like?
pod.cut2 <- cutree(pod.clust, 5) #complete linkage
pod.all$cluster2 <- pod.cut2

# Test other methods, examine results
pod.clust <- hclust(pod.dist, method="ward.D") #Ward
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Ward <- pod.cut

pod.clust <- hclust(pod.dist^2, method="ward.D2") #Ward2
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Ward2 <- pod.cut

pod.clust <- hclust(pod.dist, method="single") #Single
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Single <- pod.cut

pod.clust <- hclust(pod.dist^2, method="centroid") #Centroid
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Centroid <- pod.cut

pod.clust <- hclust(pod.dist, method="average") #Average
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Average <- pod.cut

pod.clust <- hclust(pod.dist, method="median") #Median
pod.cut <- cutree(pod.clust, 4)
pod.all$cluster.Median <- pod.cut

km1 <- kmeans(pod.all$BMD, 4, nstart=25)
pod.all$kmeans4 <- km1$cluster


# exercise - elbow chart for kmeans clusters
# a priori we think 4, what does k means say?
# pros-cons of kmeans for identifying # of clusters?

# try 1-10 clusters
c1 <- kmeans(pod.all$BMD, 1, nstart=25)
c2 <- kmeans(pod.all$BMD, 2, nstart=25)
c3 <- kmeans(pod.all$BMD, 3, nstart=25)
c4 <- kmeans(pod.all$BMD, 4, nstart=25)
c5 <- kmeans(pod.all$BMD, 5, nstart=25)
c6 <- kmeans(pod.all$BMD, 6, nstart=25)
c7 <- kmeans(pod.all$BMD, 7, nstart=25)
c8 <- kmeans(pod.all$BMD, 8, nstart=25)
c9 <- kmeans(pod.all$BMD, 9, nstart=25)
c10 <- kmeans(pod.all$BMD, 10, nstart=25)

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

plot(wss_values$k, wss_values$V1,
     type="b", pch = 19, frame = FALSE, 
     xlab="Number of clusters K",
     ylab="Total within-clusters sum of squares")
# 7 is lowest, but 4 is pretty good



# compare cluster results across methods
# pros/cons
# final suggestion? 

#TODO cluster id keeps changing?
#recode kmeans clusters
# 4 to 1; 1 to 4
pod.all$kmeans4[pod.all$kmeans4==1] <- 14
pod.all$kmeans4[pod.all$kmeans4==4] <- 11

pod.all$kmeans4[pod.all$kmeans4==14] <- 4
pod.all$kmeans4[pod.all$kmeans4==11] <- 1



# bring in metadata
pod.all2a <- merge(pod.all, pod.a1, "index")
pod.all2b <- merge(pod.all, pod.b1, "index")

pod.all2b <- rename(pod.all2b, Author_Year=Reference)
pod.all2b <- rename(pod.all2b, Study_ID=Study)
pod.all2b <- rename(pod.all2b, Material_Group=Material)
pod.all2b <- rename(pod.all2b, Material_Label=Material.Type)
pod.all2b <- rename(pod.all2b, PE_days=Post.Exp)
pod.all2b <- rename(pod.all2b, ROE=Route)

#str(pod.all2a)
#str(pod.all2b)
pod.all2a$PE_days <- as.integer(pod.all2a$PE_days)

pod.all2 <- bind_rows(pod.all2a, pod.all2b)
pod.all2 <- arrange(pod.all2, BMD.x)
pod.all2$potency_rank <- seq(1:76)
pod.all2 <- arrange(pod.all2, index)

#write.xlsx(pod.all2, file="Z:\\ENM Categories\\Framework Update 2019\\pod_all2.xlsx")

# Kruskal-Wallis
#str(pod.all2)
kruskal.test(potency_rank ~ as.factor(Material_Group), data=pod.all2)
#p-value = 0.0001332

posthoc <- dunnTest(potency_rank ~ as.factor(Material_Group), data=pod.all2)
posthoc
#write.csv(posthoc$res, file="Z:\\ENM Categories\\Framework Update 2019\\posthoc.csv")

plot(as.factor(pod.all2$Material_Group), pod.all2$potency_rank,
     type="p", pch = 19, frame = FALSE, 
     xlab="Material Group",
     ylab="Potency Rank")

eda.summ.ranks <- pod.all2 %>% group_by(Material_Group) %>% summarize(mean.rank=mean(potency_rank),
                                                                      min.rank=min(potency_rank),
                                                                      max.rank=max(potency_rank),
                                                                      sd.rank=sqrt(var(potency_rank)))


# divisive hclust
dclust <- diana(pod.dist)
plot(dclust)


dclust.cut <- cutree(dclust, k=4)
pod.all2$dclust <- dclust.cut


# cluster linkage comparisons
pod.all2$compare.ward <- pod.all2$cluster - pod.all2$cluster.Ward
pod.all2$compare.ward2 <- pod.all2$cluster - pod.all2$cluster.Ward2
pod.all2$compare.single <- pod.all2$cluster - pod.all2$cluster.Single
pod.all2$compare.centroid <- pod.all2$cluster - pod.all2$cluster.Centroid
pod.all2$compare.average <- pod.all2$cluster - pod.all2$cluster.Average
pod.all2$compare.median <- pod.all2$cluster - pod.all2$cluster.Median

# !!! Requires correct coding for cluster # - changes every run
pod.all2$compare.kmeans4 <- pod.all2$cluster - pod.all2$cluster.kmeans4


ggplot(data=pod.all2, aes(x=potency_rank, y=potency_rank, fill=compare.ward)) +
  geom_tile() +
  labs(title="Complete vs. Ward")

ggplot(data=pod.all2, aes(x=potency_rank, y=potency_rank, fill=compare.single)) +
  geom_tile() +
  labs(title="Complete vs. Single")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Complete Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Ward) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Ward's Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Ward2) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Ward's 2 Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Single) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Single Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Centroid) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Centroid Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Average) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Average Linkage")

ggplot(data=pod.all2, aes(x=BMD.x, y=potency_rank)) +
  geom_point(color=pod.all2$cluster.Median) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="All Potencies - Median Linkage")


#########
## Compare linkages on Framework
pod.b1.sort <- arrange(pod.b1, BMD)
fw.dist <- dist(pod.b1.sort$BMD)

fw.clust <- hclust(fw.dist, method="complete") #Complete
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Complete <- fw.cut

fw.clust <- hclust(fw.dist, method="ward.D") #Ward
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Ward <- fw.cut

fw.clust <- hclust(fw.dist^2, method="ward.D2") #Ward2
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Ward2 <- fw.cut

fw.clust <- hclust(fw.dist, method="single") #Single
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Single <- fw.cut

fw.clust <- hclust(fw.dist^2, method="centroid") #Centroid
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Centroid <- fw.cut

fw.clust <- hclust(fw.dist, method="average") #Average
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Average <- fw.cut

fw.clust <- hclust(fw.dist, method="median") #Median
fw.cut <- cutree(fw.clust, 4)
pod.b1.sort$cluster.Median <- fw.cut

fw.km1 <- kmeans(pod.b1.sort$BMD, 4, nstart=25)
pod.b1.sort$kmeans4 <- fw.km1$cluster

pod.b1.sort$potency_rank <- seq(1:18)

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Complete) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Complete Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Ward) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Ward's Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Ward2) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Ward's 2 Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Single) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Single Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Centroid) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Centroid Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Average) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Average Linkage")

ggplot(data=pod.b1.sort, aes(x=BMD, y=potency_rank)) +
  geom_point(color=pod.b1.sort$cluster.Median) +
  labs(x="BMD (ug/g lung)", y="Potency Rank", title="Framework Potencies - Median Linkage")
