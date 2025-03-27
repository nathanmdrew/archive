### On the first run of the RF models in program 04,
##  the test and train datasets that were generated were saved.
##  Since a seed was set, I assumed that this would lead to
##  the same test/train sets and same models.
##  That is not the case.
##
##  This program refits the RF models to the initial test/train sets
##  for comparison purposes of the results.

library(dplyr)
library(ggplot2)
library(randomForest)

set.seed(51118) #sully

oldtrain1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\train1.rds")
oldtest1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\test1.rds")


oldtrain2a <- oldtrain1 %>% select(-index, -cluster.Ward, -rand, -material_type, -Nanomat_Treatment)
old.rf.Complete <- randomForest(cluster.Complete ~ ., data=oldtrain2a, importance=T)


oldtrain2b <- oldtrain1 %>% select(-index, -cluster.Complete, -rand, -material_type, -Nanomat_Treatment)
old.rf.Ward <- randomForest(cluster.Ward ~ ., data=oldtrain2b, importance=T)

oldvalidation1a <- predict(object=old.rf.Complete, newdata=oldtest1)
oldvalidation1b <- predict(object=old.rf.Ward, newdata=oldtest1)

oldtest1$pred.Complete <- oldvalidation1a
oldtest1$pred.Ward <- oldvalidation1b

table(oldtest1$cluster.Complete, oldtest1$pred.Complete)
table(oldtest1$cluster.Ward, oldtest1$pred.Ward)




# Refit without DoE factors, completely missings, GSD
oldtrain3a <- oldtrain2a %>% select(-Route, -Post.Exp, -Surface_reactivity,
                                    -Surface_modifications, -Surface_Charge,
                                    -Aerodynamic_Diameter_GSD)

oldtrain3b <- oldtrain2b %>% select(-Route, -Post.Exp, -Surface_reactivity,
                                    -Surface_modifications, -Surface_Charge,
                                    -Aerodynamic_Diameter_GSD)

old.rf.Complete2 <- randomForest(cluster.Complete ~ ., data=oldtrain3a, importance=T)
old.rf.Ward2 <- randomForest(cluster.Ward ~ ., data=oldtrain3b, importance=T)

### Save the models
#saveRDS(old.rf.Complete2, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_complete2.RDS")
#saveRDS(old.rf.Ward2, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_ward2.RDS")

### Load the models
old.rf.Complete2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_complete2.RDS")
old.rf.Ward2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\RF_ward2.RDS")

imp.rfC2 <- as.data.frame(importance(old.rf.Complete2))
imp.rfC2[with(imp.rfC2, order("MeanDecreaseGini")), ]
varImpPlot(old.rf.Complete2)
#write.csv(imp.rfC2, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\importance_complete_RF2.csv")


imp.rfW2 <- as.data.frame(importance(old.rf.Ward2))
imp.rfW2[with(imp.rfW2, order("MeanDecreaseGini")), ]
varImpPlot(old.rf.Ward2)
#write.csv(imp.rfW2, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\importance_ward_RF2.csv")


oldvalidation2a <- predict(object=old.rf.Complete2, newdata=oldtest1)
oldvalidation2b <- predict(object=old.rf.Ward2, newdata=oldtest1)

oldtest1$pred.Complete2 <- oldvalidation2a
oldtest1$pred.Ward2 <- oldvalidation2b

rf2.confusion <- table(oldtest1$cluster.Complete, oldtest1$pred.Complete2)
rf2.confusion
accuracy <- abs(as.integer(oldtest1$cluster.Complete) - as.integer(oldtest1$pred.Complete2))/41
init.accuracy <- 1-sum(accuracy)
init.accuracy

ward2.confusion <- table(oldtest1$cluster.Ward, oldtest1$pred.Ward2)
ward2.confusion
accuracy <- abs(as.integer(oldtest1$cluster.Ward) - as.integer(oldtest1$pred.Ward2))/41
init.accuracy <- 1-sum(accuracy)

qc.rfC2 <- oldtest1 %>% filter(cluster.Complete != pred.Complete2)
qc.rfC2.2 <- data1 %>% filter(index %in% c(88, 104, 108, 146))
qc.rfC2.3 <- oldtest1 %>% filter(cluster.Complete==3)

qc.rfW2 <- oldtest1 %>% filter(cluster.Ward != pred.Ward2)
qc.rfW2.2 <- data1 %>% filter(index %in% c(11,17,59,88,101,104,108,111,123,127,129)) %>% 
                      select(StudyRef, material, material_type,Nanomat_Treatment)
qc.rfW2.3 <- oldtest1 %>% filter(cluster.Ward==3)

### COMPLETE LINKAGE
### Try to improve model fits by dropping least important variable until predictive ability worsens
### Metric: Correct predictions (decrease in false pos OR false neg)
###         No care about type of error at this point, just seeing if accuracy can increase

backwards.train.a1 <- oldtrain3a %>% select(-Contaminant_Amount)
backwards.rf.Complete <- randomForest(cluster.Complete ~ ., 
                                      data=backwards.train.a1, 
                                      importance=T)

backwards.imp.C <- as.data.frame(importance(backwards.rf.Complete))
backwards.imp.C[with(backwards.imp.C, order("MeanDecreaseGini")), ]
varImpPlot(backwards.rf.Complete)

backwards.validation <- predict(object=backwards.rf.Complete, newdata=oldtest1)
oldtest1$pred.Complete2 <- backwards.validation

rf2.confusion <- table(oldtest1$cluster.Complete, oldtest1$pred.Complete2)
rf2.confusion
accuracy <- abs(as.integer(oldtest1$cluster.Complete) - as.integer(oldtest1$pred.Complete2))/41
backwards.accuracy <- 1-sum(accuracy)

# x = var to be omitted
bwfunc <- function(){
  backwards.rf.Complete <- randomForest(cluster.Complete ~ ., 
                                        data=backwards.train.a1, 
                                        importance=T)
  
  backwards.imp.C <- as.data.frame(importance(backwards.rf.Complete))
  backwards.imp.C[with(backwards.imp.C, order("MeanDecreaseGini")), ]
  varImpPlot(backwards.rf.Complete)
  
  backwards.validation <- predict(object=backwards.rf.Complete, newdata=oldtest1)
  oldtest1$pred.Complete2 <- backwards.validation
  
  rf2.confusion <- table(oldtest1$cluster.Complete, oldtest1$pred.Complete2)
  rf2.confusion
  accuracy <- abs(as.integer(oldtest1$cluster.Complete) - as.integer(oldtest1$pred.Complete2))/41
  backwards.accuracy <- 1-sum(accuracy)
  change.accuracy <- init.accuracy - backwards.accuracy
  change.accuracy #Negative = Better
  
}

backwards.train.a1 <- backwards.train.a1 %>% select(-Solubility)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Length)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Contaminant_Type)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Modification)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Material_Category)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Zeta_Potential)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Purification_Type)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Functionalized_Type)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Contaminants_)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Agglomerated_)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Crystal_Structure_)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-material)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Structural_Form)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Density)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Diameter)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Median_Aerodynamic_Diameter)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Surface_Area)
bwfunc() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Scale)
bwfunc() #0.07317073   accuracy has worsened by 7%

# doesn't run with only 1 var - cannot remove PP_size_nm
# model with Crystal_Type, PP_size_nm, Scale performs equally to All Vars
# w.r.t. accuracy

# look at misclassification changes (if any)
backwards.train.a1 <- oldtrain3a %>% select(cluster.Complete, Crystal_Type, PP_size_nm, Scale)

backwards.train.a1$Crystal_Type[backwards.train.a1$Crystal_Type=="anatase"] <- "Anatase"
backwards.train.a1$Crystal_Type[backwards.train.a1$Crystal_Type=="rutile"] <- "Rutile"
backwards.train.a1$Crystal_Type[backwards.train.a1$Crystal_Type=="N/A"] <- "NA"

backwards.rf.Complete <- randomForest(cluster.Complete ~ ., 
                                      data=backwards.train.a1, 
                                      importance=T)

backwards.imp.C <- as.data.frame(importance(backwards.rf.Complete))
backwards.imp.C[with(backwards.imp.C, order("MeanDecreaseGini")), ]
varImpPlot(backwards.rf.Complete)

backwards.validation <- predict(object=backwards.rf.Complete, newdata=oldtest1)
oldtest1$pred.Complete2 <- backwards.validation

rf2.confusion <- table(oldtest1$cluster.Complete, oldtest1$pred.Complete2)
rf2.confusion
accuracy <- abs(as.integer(oldtest1$cluster.Complete) - as.integer(oldtest1$pred.Complete2))/41
backwards.accuracy <- 1-sum(accuracy)
backwards.accuracy
# no changes - wow

### WARD LINKAGE
### Try to improve model fits by dropping least important variable until predictive ability worsens
### Metric: Correct predictions (decrease in false pos OR false neg)
###         No care about type of error at this point, just seeing if accuracy can increase
init.confusion <- ward2.confusion
init.accuracy.ward <- init.accuracy
varImpPlot(old.rf.Ward2) #Solubility first to drop

bwfunc2 <- function(){
  backwards.rf.Ward <- randomForest(cluster.Ward ~ ., 
                                        data=backwards.train.a1, 
                                        importance=T)
  
  backwards.imp.C <- as.data.frame(importance(backwards.rf.Ward))
  backwards.imp.C[with(backwards.imp.C, order("MeanDecreaseGini")), ]
  varImpPlot(backwards.rf.Ward)
  
  backwards.validation <- predict(object=backwards.rf.Ward, newdata=oldtest1)
  oldtest1$pred.Complete2 <- backwards.validation
  
  rf2.confusion <- table(oldtest1$cluster.Ward, oldtest1$pred.Ward2)
  rf2.confusion
  accuracy <- abs(as.integer(oldtest1$cluster.Ward) - as.integer(oldtest1$pred.Ward2))/41
  backwards.accuracy <- 1-sum(accuracy)
  change.accuracy <- init.accuracy - backwards.accuracy
  change.accuracy #Negative = Better
  
}

backwards.train.a1 <- oldtrain3b %>% select(-Solubility)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Contaminant_Amount)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Agglomerated_)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Material_Category)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Crystal_Structure_)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Purification_Type)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Contaminants_)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Contaminant_Type)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Zeta_Potential)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Modification)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Density)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Length)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Median_Aerodynamic_Diameter)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-PP_size_nm)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Functionalized_Type)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Scale)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Diameter)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-material)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Surface_Area)
bwfunc2() #0

backwards.train.a1 <- backwards.train.a1 %>% select(-Structure)
bwfunc2() #0

#All that's needed is Structural_Form and Crystal_Type
#Wow.
bw.ward2.confusion <- table(oldtest1$cluster.Ward, oldtest1$pred.Ward2)
bw.ward2.confusion
#No changes in misclassification either

backwards.train.a1 <- oldtrain3b %>% select(cluster.Ward, Structural_Form, Crystal_Type)
backwards.rf.Ward <- randomForest(cluster.Ward ~ ., 
                                  data=backwards.train.a1, 
                                  importance=T)

backwards.imp.C <- as.data.frame(importance(backwards.rf.Ward))
backwards.imp.C[with(backwards.imp.C, order("MeanDecreaseGini")), ]
varImpPlot(backwards.rf.Ward)

backwards.validation <- predict(object=backwards.rf.Ward, newdata=oldtest1)
oldtest1$pred.Complete2 <- backwards.validation

rf2.confusion <- table(oldtest1$cluster.Ward, oldtest1$pred.Ward2)
rf2.confusion
accuracy <- abs(as.integer(oldtest1$cluster.Ward) - as.integer(oldtest1$pred.Ward2))/41
backwards.accuracy <- 1-sum(accuracy)
change.accuracy <- init.accuracy - backwards.accuracy
change.accuracy #Negative = Better


all <- bind_rows(oldtrain1, oldtest1)

write.csv(table(all$Crystal_Type, all$cluster.Complete), file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\qc_cryst_type_comp.csv") #some things to fix
plot(x=all$PP_size_nm, y=all$cluster.Complete)
table(all$Scale, all$cluster.Complete) #some things to fix
write.csv(table(all$Scale, all$cluster.Complete), file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\qc_scale_comp.csv") #some things to fix


table(all$Crystal_Type, all$cluster.Ward) #some things to fix
table(all$Structural_Form, all$cluster.Complete) #some things to fix
#write.csv(table(all$Crystal_Type, all$Structural_Form), file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\qc.csv")

all$Crystal_Type[all$Crystal_Type=="anatase"] <- "Anatase"
all$Crystal_Type[all$Crystal_Type=="rutile"] <- "Rutile"
all$Crystal_Type[all$Crystal_Type=="N/A"] <- "NA"

qc <- all %>% filter(Scale=="Micro", Scale=="Micron")
