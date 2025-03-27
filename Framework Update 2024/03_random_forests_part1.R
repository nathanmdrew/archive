library(readxl)
library(dplyr)
library(randomForest)
#library(Hmisc)     #describe
#library(caret)   #loocv
library(cluster) #kmeans
library(ggplot2)
#library(data.table)
#library(cowplot)

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/03_output/"


### set seed for reproducibility
set.seed(20150615)

d1 <- readRDS(file=paste0(pathin,"trimmed_data.RDS"))
#str(d1)


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

#saveRDS(wss_values, file=paste0(pathout,"wss_values.RDS"))
        
screePlot <- ggplot(data=wss_values, aes(x=as.factor(k), y=V1, group=1)) +
  geom_point() +
  geom_line() +
  labs(x="Number of clusters (K)", y="Total within-cluster sum of squares") +
  theme_bw()
  
#saveRDS(screePlot, file=paste0(pathout, "screePlot.RDS"))

# ggsave(filename=paste0(pathout,"screePlot.pdf"),
#        plot=screePlot,
#        device="pdf",
#        dpi=300)



### tune MTRY across 21 predictors
mtry_search <- function (mtryval, clusterVar) {
  randomForest(clusterVar ~ Crystal_Structure_rev + Crystal_Type_rev +
                 Length_rev + Scale_rev + PP_size_nm_rev +
                 Contaminants_ + Contaminant_Type + Contaminant_Amount +
                 Functionalized_Type + Purification_Type + Modification +
                 Solubility + Zeta_Potential + Density + 
                 Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                 Agglomerated_ + Material_Category + material + Shape,
               data=d1,
               mtry=mtryval,
               importance=T)
}

mtry.k4 <- vector(mode="list", length=21)
for (aa in 1:21){
  mtry.k4[[aa]] <- mtry_search(aa, d1$k4)
}

#saveRDS(mtry.k4, file=paste0(pathout,"mtry.k4.RDS"))

calc_acc <- function (mtryval) {
  sum(diag(mtry.k4[[mtryval]]$confusion))/nrow(d1)
}

oob.acc <- vector(mode="numeric", length=21)
for (bb in 1:21){
  oob.acc[bb] <- calc_acc(bb)
}
acc <- data.frame(mtry=seq(1:21), oob.acc=oob.acc)
plot(acc)
arrange(acc, oob.acc, mtry) #2 or 11

mtry.k4[[2]]


mtry.k5 <- vector(mode="list", length=21)
for (aa in 1:21){
  mtry.k4[[aa]] <- mtry_search(aa, d1$k5)
}


#current RF Removes surface charge, replaces Structural_Form_rev with Shape

### Repeated fits with the same mtry have varying OOB error rates
### try 100 iterations, histogram OOB error/accuracy, get central tendency

# 21 different mtrys, each one has 100 fits
# list of lists
oobVariability <- vector(mode="list", length=21)

### !!!!!   RUNTIME IS APPROXIMATELY 30 MINUTES FOR ONE CLUSTER LABEL !!!!!!
### !!!!!   7 CLUSTER LABELS + 1 OOM = 8, EXPECT 4 HOURS FOR ALL LABELS !!!!
for (ii in 1:21){
  hundredFits <- vector(mode="list", length=100)
  
  for (jj in 1:100){
    hundredFits[[jj]] <- randomForest(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                                        Length_rev + Scale_rev + PP_size_nm_rev +
                                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                                        Functionalized_Type + Purification_Type + Modification +
                                        Solubility + Zeta_Potential + Density + 
                                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                                        Agglomerated_ + Material_Category + material + Shape,
                                      data=d1,
                                      importance=T,
                                      mtry=ii)
  } #end jj loop
  
  oobVariability[[ii]] <- hundredFits
  
} #end ii loop

#saveRDS(oobVariability, file=paste0(pathout,"oobVariability.RDS"))

e <- lapply(oobVariability[[1]], "[[", "err.rate")

median(e[[1]][,1])

e[[1]][,1]





rf.k4.24 <- randomForest(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                      Length_rev + Scale_rev + PP_size_nm_rev +
                      Contaminants_ + Contaminant_Type + Contaminant_Amount +
                      Functionalized_Type + Purification_Type + Modification +
                      Solubility + Zeta_Potential + Density + 
                      Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                      Agglomerated_ + Material_Category + material + Shape,
                    data=d1,
                    importance=T,
                    mtry=2)

rf.k4.24

median(rf.k4.24$err.rate[,1]) #oob estimate of error rate

varImpPlot(rf.k4)
rf.k4$confusion
rf.k4.acc <- sum(diag(rf.k4$confusion))/nrow(d1)
oob <- 1-rf.k4.acc #matches rf.k4 output



rf.k5 <- randomForest(k5 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k5

rf.k6 <- randomForest(k6 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k6

rf.k7 <- randomForest(k7 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k7

rf.k8 <- randomForest(k8 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k8

rf.k9 <- randomForest(k9 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k9

rf.k10 <- randomForest(k10 ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.k10

rf.kOOM <- randomForest(kOOM ~ Crystal_Structure_rev + Crystal_Type_rev +
                        Length_rev + Scale_rev + PP_size_nm_rev +
                        Contaminants_ + Contaminant_Type + Contaminant_Amount +
                        Functionalized_Type + Purification_Type + Modification +
                        Solubility + Zeta_Potential + Density + 
                        Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                        Agglomerated_ + Material_Category + material + Shape,
                      data=d1,
                      importance=T)

rf.kOOM


rf.k4.acc <- sum(diag(rf.k4$confusion))/nrow(d1)
oob <- 1-rf.k4.acc #matches rf.k4 output

accuracies <- vector(mode="numeric", length=8)
accuracies[1] <- sum(diag(rf.k4$confusion))/nrow(d1)
accuracies[2] <- sum(diag(rf.k5$confusion))/nrow(d1)
accuracies[3] <- sum(diag(rf.k6$confusion))/nrow(d1)
accuracies[4] <- sum(diag(rf.k7$confusion))/nrow(d1)
accuracies[5] <- sum(diag(rf.k8$confusion))/nrow(d1)
accuracies[6] <- sum(diag(rf.k9$confusion))/nrow(d1)
accuracies[7] <- sum(diag(rf.k10$confusion))/nrow(d1)
accuracies[8] <- sum(diag(rf.kOOM$confusion))/nrow(d1)

accuracies <- as.data.frame(accuracies)
accuracies$Clusters <- c("4", "5", "6", "7", "8", "9", "10", "Order of Magnitude [7]")
accuracies

rf.k4$confusion
rf.k5$confusion
rf.k6$confusion
rf.k7$confusion
rf.k8$confusion
rf.k9$confusion
rf.k10$confusion
rf.kOOM$confusion


varImpPlot(rf.k4)
varImpPlot(rf.k5)
varImpPlot(rf.k6)
varImpPlot(rf.k7)
varImpPlot(rf.k8)
varImpPlot(rf.k9)
varImpPlot(rf.k10)
varImpPlot(rf.kOOM)
