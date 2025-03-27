########################################
###   Random forest models
###
###     Primarily, remove "STRUCTURE" from models as this is similar to Material Type
###     Resolve some of the missingnes, e.g. Scale
###     Refit models, update tables and figures
###

library(dplyr)
library(ggplot2)
library(randomForest)

set.seed(51118) #sully

oldtrain1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\train1.rds")
oldtest1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\test1.rds")
oldtrain2a <- oldtrain1 %>% select(-index, -cluster.Ward, -rand, -material_type, -Nanomat_Treatment)
oldtrain2b <- oldtrain1 %>% select(-index, -cluster.Complete, -rand, -material_type, -Nanomat_Treatment)
oldtrain3a <- oldtrain2a %>% select(-Route, -Post.Exp, -Surface_reactivity,
                                    -Surface_modifications, -Surface_Charge,
                                    -Aerodynamic_Diameter_GSD)

oldtrain3b <- oldtrain2b %>% select(-Route, -Post.Exp, -Surface_reactivity,
                                    -Surface_modifications, -Surface_Charge,
                                    -Aerodynamic_Diameter_GSD)

#remove Structure - similar info as Material Type
oldtrain4a <- oldtrain3a %>% select(-Structure)
oldtrain4b <- oldtrain3b %>% select(-Structure)


old.rf.Complete3 <- randomForest(cluster.Complete ~ ., data=oldtrain4a, importance=T)
old.rf.Ward3 <- randomForest(cluster.Ward ~ ., data=oldtrain4b, importance=T)

### Save the models
#saveRDS(old.rf.Complete3, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\RF_complete3.RDS")
#saveRDS(old.rf.Ward3, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\RF_ward3.RDS")


imp.rfC3 <- as.data.frame(importance(old.rf.Complete3))
imp.rfC3[with(imp.rfC3, order("MeanDecreaseGini")), ]
varImpPlot(old.rf.Complete3)
#write.csv(imp.rfC3, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\importance_complete_RF3.csv")


imp.rfW3 <- as.data.frame(importance(old.rf.Ward3))
imp.rfW3[with(imp.rfW3, order("MeanDecreaseGini")), ]
varImpPlot(old.rf.Ward3)
#write.csv(imp.rfW3, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\importance_ward_RF3.csv")

oldvalidation3a <- predict(object=old.rf.Complete3, newdata=oldtest1)
oldvalidation3b <- predict(object=old.rf.Ward3, newdata=oldtest1)

oldtest1$pred.Complete3 <- oldvalidation3a
oldtest1$pred.Ward3 <- oldvalidation3b

rf3.confusion <- table(oldtest1$cluster.Complete, oldtest1$pred.Complete3)
rf3.confusion
#accuracy <- abs(as.integer(oldtest1$cluster.Complete) - as.integer(oldtest1$pred.Complete2))/41
#init.accuracy <- 1-sum(accuracy)
#init.accuracy
#write.csv(rf3.confusion, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\rf3_confusion.csv")

ward3.confusion <- table(oldtest1$cluster.Ward, oldtest1$pred.Ward3)
ward3.confusion
#accuracy <- abs(as.integer(oldtest1$cluster.Ward) - as.integer(oldtest1$pred.Ward2))/41
#init.accuracy <- 1-sum(accuracy)
#write.csv(ward3.confusion, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\ward3_confusion.csv")





#Order of Magnitude
data2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")

all <- data2

# previous stuff made OoM based on BMDLs
all$cluster.OOM <- as.factor(case_when(all$BMDL < 0.01 ~ "< 0.01 ug/g lung",
                                       all$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
                                       all$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
                                       all$BMDL < 10 ~ "1 - 10 ug/g lung",
                                       all$BMDL < 100 ~ "10 - 100 ug/g lung",
                                       all$BMDL < 1000 ~ "100 - 1000 ug/g lung",
                                       all$BMDL < 10000 ~ "1000 - 10000 ug/g lung"))

#get previously used random integer for test/train assignment
# train<67
# test >67
old <- bind_rows(oldtrain1, oldtest1)
old <- old %>% select(index, rand)

all2 <- merge(all, old, by="index")
#saveRDS(all2, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\all2.rds")
#write.csv(x=all2, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\all2.csv")

train <- filter(all2, rand<=67)
test <- filter(all2, rand>67)

train2 <- train %>% select(-index, -cluster.Complete, -cluster.Ward, -rand, -material_type, 
                           -Nanomat_Treatment, -BMD, -BMDL, -Post.Exp, -Route, -Surface_reactivity,
                           -Surface_modifications, -Surface_Charge, -Aerodynamic_Diameter_GSD)

train3 <- train2 %>% select(-Structure)


#rf.oom2 <- randomForest(cluster.OOM ~ ., data=train3, importance=T)
#saveRDS(rf.oom2, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\rf_oom2.rds")
rf.oom2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\rf_oom2.rds")

imp.rf.oom2 <- as.data.frame(importance(rf.oom2))
imp.rf.oom2[with(imp.rf.oom2, order("MeanDecreaseGini")), ]
varImpPlot(rf.oom2)
#write.csv(imp.rf.oom2, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\importance_oom_RF2.csv")

pred <- predict(object=rf.oom2, newdata=test)

test2 <- test
test2$pred.OOM <- pred

rf.oom.confusion <- table(test2$cluster.OOM, test2$pred.OOM)
rf.oom.confusion
#write.csv(rf.oom.confusion, file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\rf_oom_confusion.csv")
