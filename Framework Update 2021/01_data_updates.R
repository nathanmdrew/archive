library(dplyr)
library(ggplot2)
library(randomForest)
library(readxl)

data2 <- readRDS(file="C:\\Users\\vom8\\OneDrive - CDC\\+My_Documents\\MyLargeWorkspace Backup\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")

all <- data2
max(all$index) #154



#read in unformatted new stuff from Theresa
prelim1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\nanoAOP update BMDs\\Finalized BMDs_nanoAOP update only - NMD edits.xlsx",
                      sheet=3)
prelim1$index <- seq(155:(154+nrow(prelim1))) + 154 

prelim1$BMD <- prelim1$BMD.est.ug.glung



# new clust
pt1 <- all %>% select(index, BMD)
pt2 <- prelim1 %>% select(index, BMD)

#str(pt1)
#str(pt2)

pt3 <- rbind(pt1, pt2)

pod.all <- arrange(pt3, BMD)
pod.dist <- dist(pod.all$BMD) #Euclidean Distance
# HClust - Ward
pod.clust <- hclust(pod.dist, method="ward.D2") #Ward
pod.cut <- cutree(pod.clust, 4)
plot(pod.clust)
rect.hclust(pod.clust, k=4, border=2:6)
pod.all$cluster.Ward <- pod.cut

temp1 <- pod.all %>% filter(index >= 155)

prelim2 <- merge(prelim1, temp1, by="index")

plot(prelim2$Specific_surface_area, prelim2$cluster.Ward)
plot(prelim2$Diameter_mean_nm, prelim2$cluster.Ward)
plot(prelim2$Specific_surface_area, prelim2$Diameter_mean_nm)


#remove dupes
pt4 <- pt3 %>% filter(index<114 | index>121)
pod.all <- arrange(pt4, BMD)
pod.dist <- dist(pod.all$BMD) #Euclidean Distance
# HClust - Ward
pod.clust <- hclust(pod.dist, method="ward.D2") #Ward
pod.cut <- cutree(pod.clust, 4)
plot(pod.clust)
rect.hclust(pod.clust, k=4, border=2:6)
pod.all$cluster.Ward <- pod.cut

temp2 <- pod.all %>% filter(index >= 155)


######## To do's
# remove dupes - NanoGo [3 tio2, 3 mwcnt]
#    how do they compare (kriging vs. bmds)
# reformat TBs data to match existing
#    fill in other pchems
# recluster with Ward
# split into train and test
# RF model
#
# tio2 - explain variability
#   var imp?  scale, shape, etc.

nanogo <- c(114:121, 37,
            38,
            39,
            44,
            45,
            46,
            47,
            48,
            50,
            51,
            52,
            53,
            56,
            57,
            59,
            61,
            62,
            63,
            64,
            65,
            66,
            67,
            70,
            71
)
# TBs nanogo: indeces 114-121
# NMD nanogo: 37
# 38
# 39
# 44
# 45
# 46
# 47
# 48
# 50
# 51
# 52
# 53
# 56
# 57
# 59
# 61
# 62
# 63
# 64
# 65
# 66
# 67
# 70
# 71

qc1 <- all %>% filter(index %in% nanogo)

