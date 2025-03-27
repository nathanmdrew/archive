
library(dplyr)
library(ggplot2)
library(Hmisc)     #describe
library(caret)
library(randomForest)

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/04_output/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/06_output/"

d1 <- readRDS(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/trimmed_data.RDS")


#### Figure 6-1 scree plot
### made in Program 03


### Table 6-1. Distribution of 124 materials across clusters for acute rodent 
### pulmonary inflammation data from NIOSH/CIIT/ENPRA/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update

# repeat for each cluster var
s <- d1 %>% group_by(kOOM) %>% summarize(tally = n())
s$pct <- round(s$tally/116*100)
s$val <- paste0(s$tally, " (", s$pct, "%)")
t <- s %>% select(-tally, -pct) %>% t()

saveRDS(t, file=paste0(pathout,"table6.1.kOOM.RDS"))
write.csv(t, file=paste0(pathout, "table6.1.kOOM.csv"))


### Figure 6-2
### already created in program 01




### Table 6-2. Frequency of material type by cluster across linkage methods for 
###acute rodent pulmonary inflammation data from NIOSH/ENPRA/CIIT/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update

# repeat for each cluster var
rm(crossTab); rm(comb)
crossTab <- table(d1$material, d1$kOOM)
comb <- cbind(crossTab, Total=rowSums(crossTab))
comb

saveRDS(comb, file=paste0(pathout,"table6.2.kOOM.RDS"))
write.csv(comb, file=paste0(pathout, "table6.2.kOOM.csv"))



### Table 6-3. Summary of BMDs and BMDLs by hierarchical cluster for acute 
### rodent pulmonary inflammation data from NIOSH/ENPRA/CIIT/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update

tempFunc <- function (groupVar) {

rm(s); rm(s2); rm(out)
  
s <- d1 %>% group_by(paste0(groupVar)) %>% summarize(minBMD=min(BMD),
                                         medBMD=median(BMD),
                                         maxBMD=max(BMD),
                                         minBMDL=min(BMDL),
                                         fifthBMDL=quantile(BMDL,0.05))

s$BMDs <- paste0(round(s$minBMD,4), "/", round(s$medBMD,4), "/", round(s$maxBMD,4))
s$BMDLs <- paste0(round(s$minBMDL,4), "/", round(s$fifthBMDL,4))


s2 <- s[,-2:-6]

check <- deparse(substitute(groupVar)) #turn input var into text

out <- substr(check, start=4, stop=nchar(check))


saveRDS(s2, file=paste0(pathout,"table6.3.", out, ".RDS"))
write.csv(s2, file=paste0(pathout, "table6.3.", out, ".csv"))
} #end tempFunc function

tempFunc(groupVar=d1$k4)
tempFunc(groupVar=d1$k5)
tempFunc(groupVar=d1$k6)
tempFunc(groupVar=d1$k7)
tempFunc(groupVar=d1$k8)
tempFunc(groupVar=d1$k9)
tempFunc(groupVar=d1$k10)
tempFunc(groupVar=d1$kOOM)



### Table 6-4. Summary of scale across clusters assigned using hierarchical 
### clustering with Ward's method for acute rodent pulmonary inflammation data 
### from NIOSH/ENPRA/CIIT/NanoGo and Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update


func6.4 <- function (groupVar){
  t <- table(groupVar, d1$Scale_rev)
  
  check <- deparse(substitute(groupVar)) #turn input var into text
  out <- substr(check, start=4, stop=nchar(check))
  
  saveRDS(t, file=paste0(pathout,"table6.4.", out, ".RDS"))
  write.csv(t, file=paste0(pathout, "table6.4.", out, ".csv"))
}

func6.4(d1$k4)
func6.4(d1$k5)
func6.4(d1$k6)
func6.4(d1$k7)
func6.4(d1$k8)
func6.4(d1$k9)
func6.4(d1$k10)
func6.4(d1$kOOM)



### Table 6-5. Summary of structural forms across clusters assigned using 
### hierarchical clustering with Ward's method for acute rodent pulmonary 
### inflammation data from NIOSH/ENPRA/CIIT/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update


func6.5 <- function (groupVar){
  t <- table(d1$Shape, groupVar)
  
  check <- deparse(substitute(groupVar)) #turn input var into text
  out <- substr(check, start=4, stop=nchar(check))
  
  saveRDS(t, file=paste0(pathout,"table6.5.", out, ".RDS"))
  write.csv(t, file=paste0(pathout, "table6.5.", out, ".csv"))
}

func6.5(d1$k4)
func6.5(d1$k5)
func6.5(d1$k6)
func6.5(d1$k7)
func6.5(d1$k8)
func6.5(d1$k9)
func6.5(d1$k10)
func6.5(d1$kOOM)



### Table 6-6 and 6-7
### Already made - see Table 5.3

### Figure 6-3. Availability of physicochemical properties across materials for 
### acute rodent pulmonary inflammation data from NIOSH/ENPRA/CIIT/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update

# more of a table

eda <- Hmisc::describe(d1)
eda
saveRDS(eda, file=paste0(pathout, "fig6.3.EDA.RDS"))

#check surface charge, surface reactivity, surface modifications
full_data <- readRDS(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/full_data.RDS")




### Figure 6-4
### TODO - not sure if a version showing accuracy/Kappa for 10-fold*10 for all
###        cluster numbers is needed


cv.k4 <- readRDS(paste0(pathin,"cv.k4.RDS"))
cv.k5 <- readRDS(paste0(pathin,"cv.k5.RDS"))
cv.k6 <- readRDS(paste0(pathin,"cv.k6.RDS"))
cv.k7 <- readRDS(paste0(pathin,"cv.k7.RDS"))
cv.k8 <- readRDS(paste0(pathin,"cv.k8.RDS"))
cv.k9 <- readRDS(paste0(pathin,"cv.k9.RDS"))
cv.k10 <- readRDS(paste0(pathin,"cv.k10.RDS"))

cv.kOOM <- readRDS(paste0(pathin,"cv.kOOM.RDS"))

p1 <- plot(cv.k4)
p2 <- plot(cv.k5)
p3 <- plot(cv.k6)
p4 <- plot(cv.k7)
p5 <- plot(cv.k8)
p6 <- plot(cv.k9)
p7 <- plot(cv.k10)

p8 <- plot(cv.kOOM)
p8

pAll <- p1+p2+p3+p4+p5+p6+p7
pAll

ggsave(filename=paste0(pathout,"accuracy_plot_OOM.pdf"),
       plot=p8, device="pdf", dpi=300)

ggsave(filename=paste0(pathout,"accuracy_plot_hclusts.pdf"),
       plot=pAll, device="pdf", dpi=300)

cv.k4

# from CARET guidance
resamps <- resamples(list(rf4=cv.k4,
                          rf5=cv.k5,
                          rf6=cv.k6,
                          rf7=cv.k7,
                          rf8=cv.k8,
                          rf9=cv.k9,
                          rf10=cv.k10,
                          rfOOM=cv.kOOM))
saveRDS(resamps, file=paste0(pathout,"resamps.RDS"))
resamps
summary(resamps)

theme1 <- trellis.par.get()
theme1$plot.symbol$col = rgb(.2, .2, .2, .4)
theme1$plot.symbol$pch = 16
theme1$plot.line$col = rgb(1, 0, 0, .7)
theme1$plot.line$lwd <- 2
trellis.par.set(theme1)
bwplot(resamps, layout = c(4, 2))


### Figure 6-5. Confusion matrices

### use files with prefix "cv"



q3 <- bind_cols(d1$k4, cv.k4[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf4 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf4
underPredRate <- sum(conf4[[2]]*lower.tri(conf4[[2]]))/116*100


q3 <- bind_cols(d1$k5, cv.k5[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf5 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf5

q3 <- bind_cols(d1$k6, cv.k6[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf6 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf6

q3 <- bind_cols(d1$k7, cv.k7[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf7 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf7

q3 <- bind_cols(d1$k8, cv.k8[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf8 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf8

q3 <- bind_cols(d1$k9, cv.k9[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf9 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf9

q3 <- bind_cols(d1$k10, cv.k10[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
conf10 <- confusionMatrix(data=q3$pred, reference=q3$obs)
conf10


q3 <- bind_cols(d1$kOOM, cv.kOOM[["finalModel"]][["predicted"]])
q3 <- q3 %>% rename(obs=`...1`, pred=`...2`)
confOOM <- confusionMatrix(data=q3$pred, reference=q3$obs)
confOOM

saveRDS(conf4, file=paste0(pathout,"conf4.RDS"))
saveRDS(conf5, file=paste0(pathout,"conf5.RDS"))
saveRDS(conf6, file=paste0(pathout,"conf6.RDS"))
saveRDS(conf7, file=paste0(pathout,"conf7.RDS"))
saveRDS(conf8, file=paste0(pathout,"conf8.RDS"))
saveRDS(conf9, file=paste0(pathout,"conf9.RDS"))
saveRDS(conf10, file=paste0(pathout,"conf10.RDS"))
saveRDS(confOOM, file=paste0(pathout,"confOOM.RDS"))

#under prediction rates (if a material was in group 1 (most hazard), how often 
#                        was it predicted to be in a less hazardous group)
underPredRates <- vector(mode="numeric", length=8)
underPredRates[1] <- sum(conf4[[2]]*lower.tri(conf4[[2]]))/116*100
underPredRates[2] <- sum(conf5[[2]]*lower.tri(conf5[[2]]))/116*100
underPredRates[3] <- sum(conf6[[2]]*lower.tri(conf6[[2]]))/116*100
underPredRates[4] <- sum(conf7[[2]]*lower.tri(conf7[[2]]))/116*100
underPredRates[5] <- sum(conf8[[2]]*lower.tri(conf8[[2]]))/116*100
underPredRates[6] <- sum(conf9[[2]]*lower.tri(conf9[[2]]))/116*100
underPredRates[7] <- sum(conf10[[2]]*lower.tri(conf10[[2]]))/116*100
underPredRates[8] <- sum(confOOM[[2]]*lower.tri(confOOM[[2]]))/116*100
underPredRates

# sum(diag(conf4[[2]]))/116*100 #accuracy
accuracyRates <- vector(mode="numeric", length=8)
accuracyRates[1] <- sum(diag(conf4[[2]]))/116*100
accuracyRates[2] <- sum(diag(conf5[[2]]))/116*100
accuracyRates[3] <- sum(diag(conf6[[2]]))/116*100
accuracyRates[4] <- sum(diag(conf7[[2]]))/116*100
accuracyRates[5] <- sum(diag(conf8[[2]]))/116*100
accuracyRates[6] <- sum(diag(conf9[[2]]))/116*100
accuracyRates[7] <- sum(diag(conf10[[2]]))/116*100
accuracyRates[8] <- sum(diag(confOOM[[2]]))/116*100





#over prediction rates (if a material was in group 4 (least hazard), how often 
#                        was it predicted to be in a more hazardous group)
overPredRates <- vector(mode="numeric", length=8)
overPredRates[1] <- sum(conf4[[2]]*upper.tri(conf4[[2]]))/116*100
overPredRates[2] <- sum(conf5[[2]]*upper.tri(conf5[[2]]))/116*100
overPredRates[3] <- sum(conf6[[2]]*upper.tri(conf6[[2]]))/116*100
overPredRates[4] <- sum(conf7[[2]]*upper.tri(conf7[[2]]))/116*100
overPredRates[5] <- sum(conf8[[2]]*upper.tri(conf8[[2]]))/116*100
overPredRates[6] <- sum(conf9[[2]]*upper.tri(conf9[[2]]))/116*100
overPredRates[7] <- sum(conf10[[2]]*upper.tri(conf10[[2]]))/116*100
overPredRates[8] <- sum(confOOM[[2]]*upper.tri(confOOM[[2]]))/116*100
overPredRates

kappas <- vector(mode="numeric", length=8)
kappas[1] <- as.numeric(conf4[[3]][2])
kappas[2] <- as.numeric(conf5[[3]][2])
kappas[3] <- as.numeric(conf6[[3]][2])
kappas[4] <- as.numeric(conf7[[3]][2])
kappas[5] <- as.numeric(conf8[[3]][2])
kappas[6] <- as.numeric(conf9[[3]][2])
kappas[7] <- as.numeric(conf10[[3]][2])
kappas[8] <- as.numeric(confOOM[[3]][2])

accPVal <- vector(mode="numeric", length=8)
accPVal[1] <- as.numeric(conf4[[3]][6])
accPVal[2] <- as.numeric(conf5[[3]][6])
accPVal[3] <- as.numeric(conf6[[3]][6])
accPVal[4] <- as.numeric(conf7[[3]][6])
accPVal[5] <- as.numeric(conf8[[3]][6])
accPVal[6] <- as.numeric(conf9[[3]][6])
accPVal[7] <- as.numeric(conf10[[3]][6])
accPVal[8] <- as.numeric(confOOM[[3]][6])

k <- c("k4", "k5", "k6", "k7", "k8", "k9", "k10", "kOOM")

rates <- bind_cols(k, underPredRates, accuracyRates, overPredRates, kappas, accPVal)
rates <- rates %>% rename(Groups=`...1`, UnderPred=`...2`, Accuracy=`...3`, 
                          OverPred=`...4`, Kappa=`...5`, accPValue=`...6`)
rates

rates$rankUnder <- rank(rates$UnderPred)
rates$rankAcc <- rank(rates$Accuracy)+((rank(rates$Accuracy)-4.5)*-2) #invert rank
rates$rankOver <- rank(rates$OverPred)
rates$rankKappa <- rank(rates$Kappa)+((rank(rates$Kappa)-4.5)*-2) #invert rank
rates$rankaccPValue <- rank(rates$accPValue)
rates

rates$avgRank <- rowSums(rates[7:11])/5
rates

#ignore Accuracy
rates$avgRank.noAcc <- rowSums(x=rates[,c(7,9:11)])/4
rates

#ignore Accuracy and Kappa
rates$avgRank.noAccKappa <- rowSums(x=rates[,c(7,9,11)])/3
rates

saveRDS(rates, file=paste0(pathout,"rates.RDS"))
write.csv(rates, file=paste0(pathout,"rates.csv"))


### Figure 6-6. Variable importances

#first just grab a quick example to clean up the variable names
zz <- as.data.frame(cv.k4[["finalModel"]][["importance"]])
zz$pchemProperty <- rownames(zz)
rownames(zz) <- NULL

#clean up variable names (unicode for squared exponent, mu included)
vars <- as.data.frame(zz$pchemProperty)
vars <- vars %>% rename(pchemProperty=`zz$pchemProperty`)
vars$`Physicochemical Property` <- c("Crystal Structure Indicator",
                                     "Crystal Type",
                                     "Length (nm)",
                                     "Scale",
                                     "Primary Particle Size (nm)",
                                     "Impurity Indicator",
                                     "Impurity Type",
                                     "Impurity Amount",
                                     "Functionalized Type",
                                     "Purification Type",
                                     "Modification",
                                     "Solubility Indicator",
                                     "Zeta Potential (mV)",
                                     "Density (g/mL)",
                                     "Surface Area (m\U00B2/g)",
                                     "Median Aerodynamic Diameter (\U003BCm)",
                                     "Diameter (nm)",
                                     "Agglomeration Indicator",
                                     "Material Category",
                                     "Material",
                                     "Shape")



# permutation importance (https://explained.ai/rf-importance/index.html#4)
#rerun code below, update for each cluster type
rm(yy); rm(g)
yy <- as.data.frame(importance(cv.kOOM[["finalModel"]], type=1, scale=F))
arrange(yy, desc(MeanDecreaseAccuracy))
yy$pchemProperty <- rownames(yy)
rownames(yy) <- NULL
yy <- left_join(yy, vars, by="pchemProperty")

g <- ggplot(data=yy, aes(x=MeanDecreaseAccuracy,y=reorder(`Physicochemical Property`, MeanDecreaseAccuracy))) +
  geom_bar(stat="identity") +
  theme_bw() +
  xlab("Mean Decrease in Accuracy (Permutation Importance)") +
  ylab("Physicochemical Property")
g

ggsave(filename=paste0(pathout,"varImportance.kOOM.pdf"), plot=g, device="pdf",
       dpi=300)




# save everything incase
save.image(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/06_output/misc/rData.RDS")





#### Figure 6-7. Visualization of benchmark dose estimates for acute rodent 
### pulmonary inflammation data from NIOSH/ENPRA/CIIT/NanoGo and 
### Swiss-VCI/NIOSHTIC/ATL/Nano-AOP update with grouping based on 
### orders-of-magnitude into seven potency groups

bmd2 <- arrange(d1, BMD)

bmd2$index2 <- seq(1:nrow(bmd2))

bmdl1 <- select(bmd2, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

all <- bind_rows(bmd2,bmdl1)
all <- arrange(all, index2)

all$k4 <- as.factor(all$k4)
all$k5 <- as.factor(all$k5)
all$k6 <- as.factor(all$k6)
all$k7 <- as.factor(all$k7)
all$k8 <- as.factor(all$k8)
all$k9 <- as.factor(all$k9)
all$k10 <- as.factor(all$k10)
all$kOOM <- as.factor(all$kOOM)

legend_title <- "Order of Magnitude Band"

gOOM <- ggplot(data=all, aes(x=log10(BMD), y=index2, group=index2, color=kOOM)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Order of Magnitude", color=legend_title) +
  theme(legend.position="inside",
        legend.position.inside=c(0.2,0.7),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())
gOOM

ggsave(filename=paste0(pathout, "gOOM.pdf"),
      plot=gOOM, device="pdf", dpi=300,
      width=6, height=9, units="in")

cv.kOOM        

        