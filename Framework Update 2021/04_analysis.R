library(dplyr)
library(randomForest)
library(readxl)
library(Hmisc)     #describe
library(caret)   #loocv
library(cluster) #kmeans
library(ggplot2)
library(data.table)
library(cowplot)

# clear env
rm(list=ls())

# work directory
fpath <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2021/"

# save directory
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2021/04_analysis_OUTPUTS/"

#set seed for reproducibility
set.seed(51118)

#latest file of BMDs and pchem
d1 <- read_excel(path = paste0(fpath, "data3.xlsx"),
                 sheet = "data - no duplicates")

d1 <- arrange(d1, BMD)

# restructure types
# not all vars included; some okay, some not needed
d1$material <-             as.factor(d1$material)
d1$material_type <-        as.factor(d1$material_type)
d1$Material_Category <-    as.factor(d1$Material_Category)
d1$Scale <-                as.factor(d1$Scale)
d1$Agglomerated_ <-        as.factor(d1$Agglomerated_)
d1$Structural_Form <-      as.factor(d1$Structural_Form)
d1$Crystal_Structure_ <-   as.factor(d1$Crystal_Structure_)
d1$Crystal_Type <-         as.factor(d1$Crystal_Type)
d1$Diameter <-            as.numeric(d1$Diameter)
d1$Density <-             as.numeric(d1$Density)
d1$Solubility <-           as.factor(d1$Solubility)
d1$Modification <-         as.factor(d1$Modification)
d1$Purification_Type <-    as.factor(d1$Purification_Type)
d1$Functionalized_Type <-  as.factor(d1$Functionalized_Type)
d1$Contaminants_ <-        as.factor(d1$Contaminants_)
d1$Contaminant_Type <-     as.factor(d1$Contaminant_Type)
d1$Post.Exp <-            as.numeric(d1$Post.Exp)
d1$Route <-                 as.factor(d1$Route)
d1$PP_size_nm <-           as.numeric(d1$PP_size_nm)
d1$Structure <-             as.factor(d1$Structure)
d1$material_type_rev <-     as.factor(d1$material_type_rev)
d1$Scale_rev <-             as.factor(d1$Scale_rev)
d1$Structural_Form_rev <-   as.factor(d1$Structural_Form_rev)
d1$Length_rev <-           as.numeric(d1$Length_rev)
d1$Crystal_Type_rev <-      as.factor(d1$Crystal_Type_rev)
d1$Crystal_Structure_rev <- as.factor(d1$Crystal_Structure_rev)


# var distributions
dsumm <- describe(d1)
dsumm

vars <- as.data.frame(names(d1))

str(d1)

### Cluster scree plot
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

plot(wss_values$k, wss_values$V1,
     type="b", pch = 19, frame = FALSE, 
     xlab="Number of clusters K",
     ylab="Total within-clusters sum of squares")



#cluster by BMD - 4 groups
dmat <- dist(d1$BMD)
hc.ward <- hclust(dmat, method="ward.D2")
clus.ward <- cutree(hc.ward, k=4)
d1$cluster.Ward.rev <- as.factor(clus.ward)

temp <- d1 %>% group_by(cluster.Ward.rev) %>% dplyr::summarize(minbmd = min(BMD),
                                                        meanbmd = mean(BMD),
                                                        medbmd = quantile(BMD, .5),
                                                        maxbmd = max(BMD),
                                                        nbmd = n())
temp #108/124 in Cluster1, so a model should do better than 87.1%

# Ward rf - original method
# adds surface charge, only present for 2 materials
# 22 predictors
rf1 <- randomForest(cluster.Ward.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                      Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                      Contaminants_ + Contaminant_Type + Contaminant_Amount +
                      Functionalized_Type + Purification_Type + Modification +
                      Solubility + Zeta_Potential + Surface_Charge + Density + 
                      Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                      Agglomerated_ + Material_Category + material,
                    data=d1,
                    importance=T)

rf1
varImpPlot(rf1)
rf1$confusion
rf1.acc <- sum(diag(rf1$confusion))/nrow(d1)
oob <- 1-rf1.acc #matches rf1 output

# votes for each cluster by material
v1 <- d1 %>% 
  select(index, material, material_type, cluster.Ward.rev) %>% 
  bind_cols(rf1$votes)

# what happens if Aluminum is Metal Oxide instead?
d1.temp <- d1
d1.temp$Material_Category[d1.temp$material=="Aluminum"] <- "Metal Oxide"
rf1.temp <- randomForest(cluster.Ward.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                      Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                      Contaminants_ + Contaminant_Type + Contaminant_Amount +
                      Functionalized_Type + Purification_Type + Modification +
                      Solubility + Zeta_Potential + Surface_Charge + Density + 
                      Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                      Agglomerated_ + Material_Category + material,
                    data=d1.temp,
                    importance=T)
v1.temp <- d1.temp %>% 
  select(index, material, material_type, cluster.Ward.rev) %>% 
  bind_cols(rf1.temp$votes)
qc.temp <- bind_rows(v1, v1.temp) %>% filter(material=="Aluminum")
#Less confidence in C1 when Metal Oxide, but still majority vote is C1

# loo.rf1 <- train(cluster.Ward.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
#                    Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
#                    Contaminants_ + Contaminant_Type + Contaminant_Amount +
#                    Functionalized_Type + Purification_Type + Modification +
#                    Solubility + Zeta_Potential + Surface_Charge + Density + 
#                    Surface_Area + Median_Aerodynamic_Diameter + Diameter +
#                    Agglomerated_ + Material_Category + material,
#                        method="rf",
#                        data=d1,
#                        trControl=trainControl(method="LOOCV")
# )
# 
# loo.rf1
# 
# trellis.par.set(caretTheme())
# plot(loo.rf1) # doesn't seem right; how is mtry > 22?


#leave one out (124 fits)
#also track mtry (22)
#2728 fits?
#save.rf <- vector(mode="list", length=nrow(d1))
#save.pred <- vector(mode="list", length=nrow(d1))

# will not run when LOO is for ii=122, the only member of Cluster 3
# ignore, assume prediction would be misclassified, accuracy=0
# put the cluster 3 member last, run one fewer iterations
d1.resort <- d1 %>% 
  filter(cluster.Ward.rev != 3) 
d1.resort <- bind_rows(d1.resort, filter(d1, cluster.Ward.rev==3))
d1.resort$ii <- seq(from=1, to=nrow(d1.resort))

saveRDS(d1, file=paste0(pathout, "d1.RDS"))
saveRDS(d1.resort, file=paste0(pathout, "d1.resort.RDS"))

#############################
# run 04_analysis_loo_ward_2.R here
# about 31min

loo.preds1 <- unlist(save.pred1)
loo.preds2 <- unlist(save.pred2)
loo.preds3 <- unlist(save.pred3)
loo.preds4 <- unlist(save.pred4)
loo.preds5 <- unlist(save.pred5)
loo.preds6 <- unlist(save.pred6)
loo.preds7 <- unlist(save.pred7)
loo.preds8 <- unlist(save.pred8)
loo.preds9 <- unlist(save.pred9)
loo.preds10 <- unlist(save.pred10)
loo.preds11 <- unlist(save.pred11)
loo.preds12 <- unlist(save.pred12)
loo.preds13 <- unlist(save.pred13)
loo.preds14 <- unlist(save.pred14)
loo.preds15 <- unlist(save.pred15)
loo.preds16 <- unlist(save.pred16)
loo.preds17 <- unlist(save.pred17)
loo.preds18 <- unlist(save.pred18)
loo.preds19 <- unlist(save.pred19)
loo.preds20 <- unlist(save.pred20)
loo.preds21 <- unlist(save.pred21)
loo.preds22 <- unlist(save.pred22)

acc1 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds1)
acc2 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds2)
acc3 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds3)
acc4 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds4)
acc5 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds5)
acc6 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds6)
acc7 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds7)
acc8 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds8)
acc9 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds9)
acc10 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds10)
acc11 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds11)
acc12 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds12)
acc13 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds13)
acc14 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds14)
acc15 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds15)
acc16 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds16)
acc17 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds17)
acc18 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds18)
acc19 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds19)
acc20 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds20)
acc21 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds21)
acc22 <- bind_cols(select(d1.resort, cluster.Ward.rev), loo.preds22)

acc1$mtry <- 1
acc2$mtry <- 2
acc3$mtry <- 3
acc4$mtry <- 4
acc5$mtry <- 5
acc6$mtry <- 6
acc7$mtry <- 7
acc8$mtry <- 8
acc9$mtry <- 9
acc10$mtry <- 10
acc11$mtry <- 11
acc12$mtry <- 12
acc13$mtry <- 13
acc14$mtry <- 14
acc15$mtry <- 15
acc16$mtry <- 16
acc17$mtry <- 17
acc18$mtry <- 18
acc19$mtry <- 19
acc20$mtry <- 20
acc21$mtry <- 21
acc22$mtry <- 22

acc1$match <- if_else(acc1$cluster.Ward.rev == acc1$`...2`, 1, 0)
acc2$match <- if_else(acc2$cluster.Ward.rev == acc2$`...2`, 1, 0)
acc3$match <- if_else(acc3$cluster.Ward.rev == acc3$`...2`, 1, 0)
acc4$match <- if_else(acc4$cluster.Ward.rev == acc4$`...2`, 1, 0)
acc5$match <- if_else(acc5$cluster.Ward.rev == acc5$`...2`, 1, 0)
acc6$match <- if_else(acc6$cluster.Ward.rev == acc6$`...2`, 1, 0)
acc7$match <- if_else(acc7$cluster.Ward.rev == acc7$`...2`, 1, 0)
acc8$match <- if_else(acc8$cluster.Ward.rev == acc8$`...2`, 1, 0)
acc9$match <- if_else(acc9$cluster.Ward.rev == acc9$`...2`, 1, 0)
acc10$match <- if_else(acc10$cluster.Ward.rev == acc10$`...2`, 1, 0)
acc11$match <- if_else(acc11$cluster.Ward.rev == acc11$`...2`, 1, 0)
acc12$match <- if_else(acc12$cluster.Ward.rev == acc12$`...2`, 1, 0)
acc13$match <- if_else(acc13$cluster.Ward.rev == acc13$`...2`, 1, 0)
acc14$match <- if_else(acc14$cluster.Ward.rev == acc14$`...2`, 1, 0)
acc15$match <- if_else(acc15$cluster.Ward.rev == acc15$`...2`, 1, 0)
acc16$match <- if_else(acc16$cluster.Ward.rev == acc16$`...2`, 1, 0)
acc17$match <- if_else(acc17$cluster.Ward.rev == acc17$`...2`, 1, 0)
acc18$match <- if_else(acc18$cluster.Ward.rev == acc18$`...2`, 1, 0)
acc19$match <- if_else(acc19$cluster.Ward.rev == acc19$`...2`, 1, 0)
acc20$match <- if_else(acc20$cluster.Ward.rev == acc20$`...2`, 1, 0)
acc21$match <- if_else(acc21$cluster.Ward.rev == acc21$`...2`, 1, 0)
acc22$match <- if_else(acc22$cluster.Ward.rev == acc22$`...2`, 1, 0)

acc.ward <- vector(mode="numeric", length=22)

acc.ward[1] <- sum(acc1$match) / nrow(d1.resort)
acc.ward[2] <- sum(acc2$match) / nrow(d1.resort)
acc.ward[3] <- sum(acc3$match) / nrow(d1.resort)
acc.ward[4] <- sum(acc4$match) / nrow(d1.resort)
acc.ward[5] <- sum(acc5$match) / nrow(d1.resort)
acc.ward[6] <- sum(acc6$match) / nrow(d1.resort)
acc.ward[7] <- sum(acc7$match) / nrow(d1.resort)
acc.ward[8] <- sum(acc8$match) / nrow(d1.resort)
acc.ward[9] <- sum(acc9$match) / nrow(d1.resort)
acc.ward[10] <- sum(acc10$match) / nrow(d1.resort)
acc.ward[11] <- sum(acc11$match) / nrow(d1.resort)
acc.ward[12] <- sum(acc12$match) / nrow(d1.resort)
acc.ward[13] <- sum(acc13$match) / nrow(d1.resort)
acc.ward[14] <- sum(acc14$match) / nrow(d1.resort)
acc.ward[15] <- sum(acc15$match) / nrow(d1.resort)
acc.ward[16] <- sum(acc16$match) / nrow(d1.resort)
acc.ward[17] <- sum(acc17$match) / nrow(d1.resort)
acc.ward[18] <- sum(acc18$match) / nrow(d1.resort)
acc.ward[19] <- sum(acc19$match) / nrow(d1.resort)
acc.ward[20] <- sum(acc20$match) / nrow(d1.resort)
acc.ward[21] <- sum(acc21$match) / nrow(d1.resort)
acc.ward[22] <- sum(acc22$match) / nrow(d1.resort)

plot(acc.ward)
1-acc.ward
rf.oob

rf.oob <- vector(mode="numeric", length=22)

mtry_search <- function (mtryval) {
  randomForest(cluster.Ward.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                 Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                 Contaminants_ + Contaminant_Type + Contaminant_Amount +
                 Functionalized_Type + Purification_Type + Modification +
                 Solubility + Zeta_Potential + Surface_Charge + Density + 
                 Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                 Agglomerated_ + Material_Category + material,
               data=d1,
               mtry=mtryval,
               importance=T)
}

rf.oob2 <- vector(mode="list", length=22)
for (aa in 1:22){
  rf.oob2[[aa]] <- mtry_search(aa)
}

rf.oob[4]
rf.oob2[[4]]


plot(rf.oob) #

calc_acc <- function (mtryval) {
  sum(diag(rf.oob2[[mtryval]]$confusion))/nrow(d1)
}

oob.acc <- vector(mode="numeric", length=22)
for (bb in 1:22){
  oob.acc[bb] <- calc_acc(bb)
}
plot(oob.acc) #oob_ward_accuracy_across_mtry.jpg
rf.oob2[[5]]

saveRDS(acc.ward, file=paste0(pathout, "acc.ward.RDS"))
saveRDS(rf.oob, file=paste0(pathout, "rf.oob.RDS"))

# seems like mtry=5 is best
# https://stats.stackexchange.com/questions/429015/oob-vs-cv-for-random-forest
# oob vs. loo will converge, oob saves comp time and is good enough
rf.oob <- readRDS(file=paste0(pathout, "rf.oob.RDS"))
save.rf5 <- readRDS(file=paste0(pathout, "save.rf5.RDS"))

rf.ward <- rf.oob2[[5]]

varImpPlot(rf.ward) #wardImp_mtry5.jpg


#cluster by BMD - 4 groups
dmat <- dist(d1$BMD)
hc.complete <- hclust(dmat, method="complete")
clus.complete <- cutree(hc.complete, k=4)
d1$cluster.Complete.rev <- as.factor(clus.complete)

temp <- d1 %>% group_by(cluster.Complete.rev) %>% dplyr::summarize(minbmd = min(BMD),
                                                               meanbmd = mean(BMD),
                                                               medbmd = quantile(BMD, .5),
                                                               maxbmd = max(BMD),
                                                               nbmd = n())
temp
# exactly the same as Ward


#####################################
############   OOM
############
d1$cluster.OOM.rev <- as.factor(case_when(d1$BMDL < 0.01 ~ "< 0.01 ug/g lung",
                                       d1$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
                                       d1$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
                                       d1$BMDL < 10 ~ "1 - 10 ug/g lung",
                                       d1$BMDL < 100 ~ "10 - 100 ug/g lung",
                                       d1$BMDL < 1000 ~ "100 - 1000 ug/g lung",
                                       d1$BMDL < 10000 ~ "1000 - 10000 ug/g lung"))

temp <- d1 %>% group_by(cluster.OOM.rev) %>% dplyr::summarize(minbmd = min(BMD),
                                                                   meanbmd = mean(BMD),
                                                                   medbmd = quantile(BMD, .5),
                                                                   maxbmd = max(BMD),
                                                                   nbmd = n())
temp



rf.oom <- randomForest(cluster.OOM.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                          Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                          Contaminants_ + Contaminant_Type + Contaminant_Amount +
                          Functionalized_Type + Purification_Type + Modification +
                          Solubility + Zeta_Potential + Surface_Charge + Density + 
                          Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                          Agglomerated_ + Material_Category + material,
                        data=d1)
rf.oom

mtry_search_oom <- function (mtryval) {
  randomForest(cluster.OOM.rev ~ Crystal_Structure_rev + Crystal_Type_rev +
                 Length_rev + Structural_Form_rev + Scale_rev + PP_size_nm_rev +
                 Contaminants_ + Contaminant_Type + Contaminant_Amount +
                 Functionalized_Type + Purification_Type + Modification +
                 Solubility + Zeta_Potential + Surface_Charge + Density + 
                 Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                 Agglomerated_ + Material_Category + material,
               data=d1,
               mtry=mtryval,
               importance=T)
}

rf.oom2 <- vector(mode="list", length=22)
for (aa in 1:22){
  rf.oom2[[aa]] <- mtry_search_oom(mtryval=aa)
}

saveRDS(rf.oom2, file=paste0(pathout, "rf.oom2.RDS"))

d1$ii <- seq(from=1, to=nrow(d1))

# run 04_analysis_loo_oom.R here
# takes 1.78 hours


calc_acc_oom <- function (mtryval) {
  sum(diag(rf.oom2[[mtryval]]$confusion))/nrow(d1)
}

oob.acc.oom <- vector(mode="numeric", length=22)
for (bb in 1:22){
  oob.acc.oom[bb] <- calc_acc_oom(bb)
}
plot(oob.acc.oom) #oob_oom_accuracy_across_mtry.jpg

rf.oom2[[5]]

rf.oom <- rf.oom2[[5]] # mtry with highest accuracy
varImpPlot(rf.oom) #varImp_oom_mtry5.jpg


################
### LOO accuracy

#note Ward's used d1.resort
acc.ward2 <- vector(mode="numeric", length=22)

loo.acc.ward <- function (mtryval) {
  temp1 <- readRDS(paste0(pathout,"save.loo.pred.mtry", mtryval, ".RDS"))
  temp2 <- unlist(temp1)
  temp3 <- bind_cols(d1.resort$cluster.Ward.rev, temp2)
  temp3$match <- if_else(temp3$`...1` == temp3$`...2`, 1, 0)
  sum(temp3$match) / nrow(d1.resort)
}

for (dd in 1:22){
  acc.ward2[[dd]] <- loo.acc.ward(mtryval=dd)
}

rm(temp1); rm(temp2); rm(temp3)

plot(acc.ward2*100, pch=16, col="black", type="b", xlab="mtry Value",
     ylab="Accuracy (%)", lab=c(22,5,12)) #loo_ward_accuracy_across_mtry.jpg
# 850x444 shows the full x-axis

#order of magnitude, uses D1
acc.oom2 <- vector(mode="numeric", length=22)

loo.acc.oom <- function (mtryval) {
  temp1 <- readRDS(paste0(pathout,"save.loo.pred.oom.mtry", mtryval, ".RDS"))
  temp2 <- unlist(temp1)
  temp3 <- bind_cols(d1$cluster.OOM.rev, temp2)
  temp3$match <- if_else(temp3$`...1` == temp3$`...2`, 1, 0)
  sum(temp3$match) / nrow(d1)
}

for (dd in 1:22){
  acc.oom2[[dd]] <- loo.acc.oom(mtryval=dd)
}

rm(temp1); rm(temp2); rm(temp3)

plot(acc.oom2) #loo_oom_accuracy_across_mtry.jpg




################################################################################
##############################Plots/Summaries/Tables#####################################
################################################################################
temp <- d1 %>% 
  select(material, material_type, cluster.Ward.rev, Structural_Form)

qc <- filter(d1, material_type=="short")

# distinguish mwcnt from swcnt, amorphous silica from crystalline
temp$material2 <- as.character(temp$material)
temp$material2[temp$material_type=="short"] <- "SWCNT"
temp$material2[temp$material=="Silica"] <- "Crystalline"
temp$material2[temp$Structural_Form=="amorphous nanoparticle"] <- "Amorphous"
temp$material2 <- as.factor(temp$material2)

t <- temp %>% 
  dplyr::group_by(cluster.Ward.rev, material2) %>% 
  dplyr::summarize(freq=n())
write.csv(t, file=paste0(pathout,"material_ward_freq.csv"))





temp <- d1 %>% 
  select(material, material_type, cluster.OOM.rev, Structural_Form)
# distinguish mwcnt from swcnt, amorphous silica from crystalline
temp$material2 <- as.character(temp$material)
temp$material2[temp$material_type=="short"] <- "SWCNT"
temp$material2[temp$material=="Silica"] <- "Crystalline"
temp$material2[temp$Structural_Form=="amorphous nanoparticle"] <- "Amorphous"
temp$material2 <- as.factor(temp$material2)

t <- temp %>% 
  dplyr::group_by(material2, cluster.OOM.rev) %>% 
  dplyr::summarize(freq=n())
write.csv(t, file=paste0(pathout,"material_oom_freq2.csv"))




t <- d1 %>% dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(mindiam = min(Diameter),
            minssa = min(Surface_Area),
            meddiam = median(Diameter),
            medssa = median(Surface_Area),
            maxdiam = max(Diameter),
            maxssa = max(Surface_Area)
  )
t <- d1 %>% select(index, material, material_type, cluster.Ward.rev, cluster.OOM.rev,
                   Diameter, Surface_Area)
write.csv(t, file=paste0(pathout,"diam_ssa_by_cluster.csv"))




t <- d1 %>% dplyr::group_by(cluster.Ward.rev) %>% dplyr::summarize(efflvl=quantile(BMDL, 0.05))


d2 <- d1
d2$PP_size_nm_rev[d2$PP_size_nm_rev=="NA"] <- -99
describe(d2$PP_size_nm_rev)
write.csv(d2, file=paste0(pathout,"data_out.csv"))



bmd1 <- d2 %>% select(material, material_type_rev, BMD, BMDL, cluster.Ward.rev)
bmd2 <- arrange(bmd1, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

legend_title <- "Hierarchical Cluster"
plot.ward <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=cluster.Ward.rev)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) #bmd_bmdl_ward.jpg

plot.log10ward <- ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=cluster.Ward.rev)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Ward's Method Linkage", color=legend_title) +
  theme(legend.position=c(0.2,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

ggsave(filename="/bmd_bmdl_ward.pdf",
       plot=plot.ward,
       device="pdf",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/bmd_bmdl_ward.eps",
       plot=plot.ward,
       device="eps",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/log10bmd_bmdl_ward.pdf",
       plot=plot.log10ward,
       device="pdf",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/log10bmd_bmdl_ward.eps",
       plot=plot.log10ward,
       device="eps",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")

bmd1 <- d2 %>% select(material, material_type_rev, BMD, BMDL, cluster.OOM.rev)
bmd2 <- arrange(bmd1, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

plot.oom <- ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=cluster.OOM.rev)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Order of Magnitude", color=legend_title) +
  theme(legend.position=c(0.18,0.58),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) #bmd_bmdl_logOOM.jpg

plot.Linear.oom <- ggplot(data=all, aes(x=BMD, y=index2, group=index2, color=cluster.OOM.rev)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Order of Magnitude", color=legend_title) +
  theme(legend.position=c(0.8,0.45),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) 

ggsave(filename="/bmd_bmdl_oom.pdf",
       plot=plot.oom,
       device="pdf",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/bmd_bmdl_oom.eps",
       plot=plot.oom,
       device="eps",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/linear_bmd_bmdl_oom.pdf",
       plot=plot.Linear.oom,
       device="pdf",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")
ggsave(filename="/linear_bmdl_oom.eps",
       plot=plot.Linear.oom,
       device="eps",
       path=pathout,
       dpi=300,
       width=8,
       height=10.5,
       units="in")

# plot.panel <- plot_grid(plot.ward, plot.log10ward,
#                         plot.oom, plot.Linear.oom,
#                         ncol=2, nrow=2, scale=c(0.7,0.7,0.7,0.7))
# ggsave(filename="/grid_bmd_bmdl_plots.pdf",
#        plot=plot.panel,
#        device="pdf",
#        path=pathout,
#        dpi=300,
#        width=8,
#        height=10.5,
#        units="in")
# ggsave(filename="/linear_bmdl_oom.eps",
#        plot=plot.Linear.oom,
#        device="eps",
#        path=pathout,
#        dpi=300,
#        width=8,
#        height=10.5,
#        units="in")
################################################################################
##############################QC/Misc Stuff#####################################
################################################################################

qc <- d1 %>% filter(is.na(Length_rev))
qc <- d1 %>% filter(Length_rev==-9) # measureable, but not reported
qc <- d1 %>% filter(is.na(PP_size_nm))
qc <- d1 %>% filter(is.na(Diameter))

# minor revalues (resolved in data3.xlsx for now)
d1$Length_rev[is.na(d1$Length_rev)] <- -99 #5 instances
d1$PP_size_nm[is.na(d1$PP_size_nm)] <- -99 #12 instances
d1$Diameter[is.na(d1$Diameter)] <- -99 #1 instance
d1$Density[is.na(d1$Density)] <- -99 #17 instances




current.train <- droplevels(filter(d1, ii != 122))
str(d1$cluster.Ward.rev)


qc <- bind_cols(d1$cluster.Ward.rev, c4$cluster)



tempd <- filter(d1, Lit_Source != "nanoAOP")
tempd <- arrange(tempd, BMD)

dmat <- dist(tempd$BMD)
hc.complete <- hclust(dmat, method="complete")
clus.complete <- cutree(hc.complete, k=4)
tempd$cluster.Complete.rev <- as.factor(clus.complete)

temp <- tempd %>% group_by(cluster.Complete.rev) %>% dplyr::summarize(minbmd = min(BMD),
                                                                   meanbmd = mean(BMD),
                                                                   medbmd = quantile(BMD, .5),
                                                                   maxbmd = max(BMD),
                                                                   nbmd = n())
temp

hc.complete <- hclust(dmat, method="ward.D2")
clus.complete <- cutree(hc.complete, k=4)
tempd$cluster.Complete.rev <- as.factor(clus.complete)

temp <- tempd %>% group_by(cluster.Complete.rev) %>% dplyr::summarize(minbmd = min(BMD),
                                                                   meanbmd = mean(BMD),
                                                                   medbmd = quantile(BMD, .5),
                                                                   maxbmd = max(BMD),
                                                                   nbmd = n())
temp


d1$PP_size_nm_rev
49+26




#### Technical Report stuff
# Table F-7: Material, Material Type, Index, Ward Cluster, oom band, bmd, bmdl
d1 <- readRDS(paste0(pathout, "d1.RDS"))
d1.resort <- readRDS(paste0(pathout, "d1.resort.RDS"))

names(d1)

d1$cluster.OOM.rev <- as.factor(case_when(d1$BMDL < 0.01 ~ "< 0.01 ug/g lung",
                                          d1$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
                                          d1$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
                                          d1$BMDL < 10 ~ "1 - 10 ug/g lung",
                                          d1$BMDL < 100 ~ "10 - 100 ug/g lung",
                                          d1$BMDL < 1000 ~ "100 - 1000 ug/g lung",
                                          d1$BMDL < 10000 ~ "1000 - 10000 ug/g lung"))
saveRDS(d1, file=paste0(pathout,"d1_v2.RDS"))

tbf7 <- d1 %>% select(index, material, material_type, 
                      cluster.Ward.rev, cluster.OOM.rev, BMD, BMDL) %>%
        arrange(BMD)

saveRDS(tbf7, file=paste0(pathout,"tbf7.RDS"))
write.csv(tbf7, file=paste0(pathout,"tableF7.csv"))



# Table F-8: Material, Material type, index, Study ref
tbf8 <- d1 %>% arrange(BMD) %>% select(index, material, material_type, StudyRef, Lit_Source)
saveRDS(tbf8, file=paste0(pathout,"tbf8.RDS"))
write.csv(tbf8, file=paste0(pathout,"tableF8.csv"))


# Table F-10: Length summary by Ward cluster
tbf10a <- d1 %>% 
  select(cluster.Ward.rev, Length_rev) %>%
  filter(Length_rev>0) %>%
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(Minimum=min(Length_rev),
            `1st Quartile`=quantile(Length_rev, 0.25),
            Median=median(Length_rev),
            Mean=mean(Length_rev),
            `3rd Quartile`=quantile(Length_rev, 0.75),
            Maximum=max(Length_rev),
            `Number (n)`=n())

# -9 means missing and should be there (e.g., for CNT)
tbf10b <- d1 %>%
  select(cluster.Ward.rev, Length_rev) %>%
  filter(Length_rev==-9) %>% 
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(`Number Missing`=n())

# -99 means missing and not applicable (e.g., spherical particles)
tbf10c <- d1 %>%
  select(cluster.Ward.rev, Length_rev) %>%
  filter(Length_rev==-99) %>% 
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(`Number Not Applicable`=n())

tbf10cb <- left_join(tbf10c, tbf10b)
tbf10 <- left_join(tbf10cb, tbf10a)

t_tbf10 <- transpose(tbf10)
colnames(t_tbf10) <- rownames(tbf10)
rownames(t_tbf10) <- colnames(tbf10)

saveRDS(t_tbf10, file=paste0(pathout,"tbf10.RDS"))
write.csv(t_tbf10, file=paste0(pathout,"tableF10.csv"))


# Table F-11: Crystal types by cluster
tbf11 <- d1 %>% 
  select(cluster.Ward.rev, Crystal_Structure_rev, Crystal_Type_rev) %>%
  group_by(cluster.Ward.rev, Crystal_Structure_rev, Crystal_Type_rev) %>%
  summarize(`Number (n)` = n())

saveRDS(tbf11, file=paste0(pathout,"tbf11.RDS"))
write.csv(tbf11, file=paste0(pathout,"tableF11.csv"))


#Table F-12: Density by cluster
tbf12a <- d1 %>% 
  select(cluster.Ward.rev, Density) %>%
  filter(Density>0) %>%
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(Minimum=min(Density),
                   `1st Quartile`=quantile(Density, 0.25),
                   Median=median(Density),
                   Mean=mean(Density),
                   `3rd Quartile`=quantile(Density, 0.75),
                   Maximum=max(Density),
                   `Number (n)`=n())

# -99 means missing 
tbf12c <- d1 %>%
  select(cluster.Ward.rev, Density) %>%
  filter(Density==-99) %>% 
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(`Number Missing`=n())

tbf12 <- left_join(tbf12c, tbf12a)

t_tbf12 <- transpose(tbf12)
colnames(t_tbf12) <- rownames(tbf12)
rownames(t_tbf12) <- colnames(tbf12)

saveRDS(t_tbf12, file=paste0(pathout,"tbf12.RDS"))
write.csv(t_tbf12, file=paste0(pathout,"tableF12.csv"))




#Table F-13: Zeta potential by cluster
describe(d1$Zeta_Potential)

tbf13a <- d1 %>% 
  select(cluster.Ward.rev, Zeta_Potential) %>%
  filter(Zeta_Potential != -99) %>%
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(Minimum=min(Zeta_Potential),
                   `1st Quartile`=quantile(Zeta_Potential, 0.25),
                   Median=median(Zeta_Potential),
                   Mean=mean(Zeta_Potential),
                   `3rd Quartile`=quantile(Zeta_Potential, 0.75),
                   Maximum=max(Zeta_Potential),
                   `Number (n)`=n())

# -99 means missing 
tbf13c <- d1 %>%
  select(cluster.Ward.rev, Zeta_Potential) %>%
  filter(Zeta_Potential==-99) %>% 
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(`Number Missing`=n())

tbf13 <- left_join(tbf13c, tbf13a)

t_tbf13 <- transpose(tbf13)
colnames(t_tbf13) <- rownames(tbf13)
rownames(t_tbf13) <- colnames(tbf13)

saveRDS(t_tbf13, file=paste0(pathout,"tbf13.RDS"))
write.csv(t_tbf13, file=paste0(pathout,"tableF13.csv"))




#Table F-14: Primary particle size by cluster
describe(d1$PP_size_nm_rev)

d1$PP_size_nm_rev <- as.numeric(d1$PP_size_nm_rev)
d1$PP_size_nm_rev[is.na(d1$PP_size_nm_rev)] <- -99

tbf14a <- d1 %>% 
  select(cluster.Ward.rev, PP_size_nm_rev) %>%
  filter(PP_size_nm_rev > 0) %>%
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(Minimum=min(PP_size_nm_rev),
                   `1st Quartile`=quantile(PP_size_nm_rev, 0.25),
                   Median=median(PP_size_nm_rev),
                   Mean=mean(PP_size_nm_rev),
                   `3rd Quartile`=quantile(PP_size_nm_rev, 0.75),
                   Maximum=max(PP_size_nm_rev),
                   `Number (n)`=n())

# -99 means missing 
tbf14c <- d1 %>%
  select(cluster.Ward.rev, PP_size_nm_rev) %>%
  filter(PP_size_nm_rev <= 0) %>% 
  dplyr::group_by(cluster.Ward.rev) %>%
  dplyr::summarize(`Number Missing`=n())

tbf14b <- d1 %>%
  select(cluster.Ward.rev, PP_size_nm_rev) %>%
  filter(is.na(PP_size_nm_rev))

temp <- tbf13 %>% select(cluster.Ward.rev) #bring in row for each cluster

tbf14 <- left_join(temp, tbf14c)
tbf14 <- left_join(tbf14, tbf14a)

t_tbf14 <- transpose(tbf14)
colnames(t_tbf14) <- rownames(tbf14)
rownames(t_tbf14) <- colnames(tbf14)

saveRDS(t_tbf14, file=paste0(pathout,"tbf14.RDS"))
write.csv(t_tbf14, file=paste0(pathout,"tableF14.csv"))
