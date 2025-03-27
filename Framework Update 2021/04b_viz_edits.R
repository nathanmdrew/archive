library(randomForest)
library(ggplot2)
library(dplyr)

# clear env
rm(list=ls())

# work directory
fpath <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2021/"

# save directory
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2021/04_analysis_OUTPUTS/"

#set seed for reproducibility
set.seed(51118)

#d1 <- readRDS(file=paste0(pathout, "d1.RDS"))
d1 <- readRDS(file=paste0(pathout, "d1_v2.RDS")) #includes OOM groups
d1.resort <- readRDS(file=paste0(pathout,"d1.resort.RDS"))

#rerun OOB RF, hclust
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

saveRDS(rf.oob2, file=paste0(pathout,"rf.oob2.RDS"))
rf.oob2 <- readRDS(file=paste0(pathout,"rf.oob2.RDS"))

calc_acc <- function (mtryval) {
  sum(diag(rf.oob2[[mtryval]]$confusion))/nrow(d1)
}

oob.acc <- vector(mode="numeric", length=22)
for (bb in 1:22){
  oob.acc[bb] <- calc_acc(bb)
}
plot(oob.acc, pch=16, col="black", type="b", xlab="mtry value",
     ylab="Accuracy")

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



plot(acc.ward2*100, pch=16, col="black", type="b", xlab="mtry Value",
     ylab="Accuracy (%)", lab=c(22,5,12)) #loo_ward_accuracy_across_mtry.jpg
# 850x444 shows the full x-axis

oob.acc2 <- as.data.frame(oob.acc)
oob.acc2$mtryValue <- seq(from=1, to=22)
oob.acc2$method <- rep("Out-of-Bag", 22)
names(oob.acc2) <- c("Accuracy", "mtry Value", "Method")

acc.ward3 <- as.data.frame(acc.ward2)
acc.ward3$mtryValue <- seq(from=1, to=22)
acc.ward3$method <- rep("Leave-One-Out",22)
names(acc.ward3) <- c("Accuracy", "mtry Value", "Method")


hclust.acc <- bind_rows(oob.acc2, acc.ward3)

plotBreaks <- c("1","2","3","4","5","6","7","8","9","10",
                "11","12","13","14","15","16","17","18","19",
                "20","21","22")
hclustAcc <- 
  ggplot(data=hclust.acc, aes(x=`mtry Value`, y=Accuracy, color=Method)) +
  geom_line(aes(y=Accuracy*100)) +
  geom_point(aes(y=Accuracy*100), size=2.5) +
  theme_bw() +
  labs(y="Accuracy (%)")

ggsave(plot=hclustAcc, filename=paste0(pathout,"hclustAcc.pdf"),
       dpi=300, width=8.5, height=(1/4)*8.5, units="in")


### OOM plots
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

plot(acc.oom2) #loo_oom_accuracy_across_mtry.jpg




rf.oom2 <- readRDS(file=paste0(pathout,"rf.oom2.RDS"))
calc_acc_oom <- function (mtryval) {
  sum(diag(rf.oom2[[mtryval]]$confusion))/nrow(d1)
}

oob.acc.oom <- vector(mode="numeric", length=22)
for (bb in 1:22){
  oob.acc.oom[bb] <- calc_acc_oom(bb)
}
plot(oob.acc.oom) #oob_oom_accuracy_across_mtry.jpg


#restructure oob.acc.oom and acc.oom2
acc.oom2 <- as.data.frame(acc.oom2)
acc.oom2$mtryValue <- seq(from=1, to=22)
acc.oom2$method <- rep("Leave-One-Out", 22)
names(acc.oom2) <- c("Accuracy", "mtry Value", "Method")

oob.acc.oom <- as.data.frame(oob.acc.oom)
oob.acc.oom$mtryValue <- seq(from=1, to=22)
oob.acc.oom$method <- rep("Out-of-Bag",22)
names(oob.acc.oom) <- c("Accuracy", "mtry Value", "Method")

oom.acc <- bind_rows(acc.oom2, oob.acc.oom)

oomAcc <- 
  ggplot(data=oom.acc, aes(x=`mtry Value`, y=Accuracy, color=Method)) +
  geom_line(aes(y=Accuracy*100)) +
  geom_point(aes(y=Accuracy*100), size=2.5) +
  theme_bw() +
  labs(y="Accuracy (%)")

ggsave(plot=oomAcc, filename=paste0(pathout,"oomAcc.pdf"),
       dpi=300, width=8.5, height=(1/4)*8.5, units="in")






rf.ward <- rf.oob2[[5]]

varImpPlot(rf.ward) #wardImp_mtry5.jpg
wardImp <- as.data.frame(rf.ward$importance)
wardImp$varName <- rownames(wardImp)
rownames(wardImp) <- NULL
write.csv(x=wardImp, file=paste0(pathout,"wardImp.csv"))


rf.oom <- rf.oom2[[5]] # mtry with highest accuracy
varImpPlot(rf.oom) #varImp_oom_mtry5.jpg
oomImp <- as.data.frame(rf.oom$importance)
oomImp$varName <- rownames(oomImp)
rownames(oomImp) <- NULL
write.csv(x=oomImp, file=paste0(pathout,"oomImp.csv"))
