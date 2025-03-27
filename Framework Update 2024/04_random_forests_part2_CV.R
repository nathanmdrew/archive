#library(readxl)
library(dplyr)
library(randomForest)
#library(Hmisc)     #describe
library(caret)   #loocv
#library(cluster) #kmeans
library(ggplot2)
#library(data.table)
#library(cowplot)

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/04_output/"


### set seed for reproducibility
set.seed(71610)

d1 <- readRDS(file=paste0(pathin,"trimmed_data.RDS"))

# d1.k4 <- d1 %>% select(k4, Crystal_Structure_rev, Crystal_Type_rev,
#                          Length_rev, Scale_rev, PP_size_nm_rev,
#                          Contaminants_, Contaminant_Type, Contaminant_Amount,
#                          Functionalized_Type, Purification_Type, Modification,
#                          Solubility, Zeta_Potential, Density,
#                          Surface_Area, Median_Aerodynamic_Diameter, Diameter,
#                          Agglomerated_, Material_Category, material, Shape)

trg <- data.frame(mtry=seq(1,21,by=1)) #restrict CV to mtry <= # predictors

rm(temp)
temp <- train(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                Length_rev + Scale_rev + PP_size_nm_rev +
                Contaminants_ + Contaminant_Type + Contaminant_Amount +
                Functionalized_Type + Purification_Type + Modification +
                Solubility + Zeta_Potential + Density + 
                Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                Agglomerated_ + Material_Category + material + Shape,
              data=d1,
              method="rf",
              tuneGrid=trg,
              trControl=trainControl(method="repeatedcv",
                                     number=10,
                                     repeats=10))
#accuracy was the metric, mtry is 4

temp

temp.pred <- predict(temp, d1)

confusionMatrix(data=temp.pred, reference=d1$k4)






rm(temp2)
temp2 <- train(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                Length_rev + Scale_rev + PP_size_nm_rev +
                Contaminants_ + Contaminant_Type + Contaminant_Amount +
                Functionalized_Type + Purification_Type + Modification +
                Solubility + Zeta_Potential + Density + 
                Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                Agglomerated_ + Material_Category + material + Shape,
              data=d1,
              method="rf",
              tuneGrid=trg,
              metric="Kappa",
              trControl=trainControl(method="repeatedcv",
                                     number=10,
                                     repeats=10))

temp2

temp2.pred <- predict(temp2, d1)

confusionMatrix(data=temp2.pred, reference=d1$k4)
#Kappa metric way better

plot(temp2, metric = "Kappa")

temp2Imp <- varImp(temp2, scale = FALSE)
temp2Imp



# Fit the RF to 4 clusters, with importance
set.seed(71610)

start.time <- Sys.time()
fit.k4 <- train(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                  Length_rev + Scale_rev + PP_size_nm_rev +
                  Contaminants_ + Contaminant_Type + Contaminant_Amount +
                  Functionalized_Type + Purification_Type + Modification +
                  Solubility + Zeta_Potential + Density + 
                  Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                  Agglomerated_ + Material_Category + material + Shape,
                data=d1,
                method="rf",
                importance=T,
                tuneGrid=trg,
                metric="Kappa",
                trControl=trainControl(method="repeatedcv",
                                       number=10,
                                       repeats=10))
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

fit.k4
varImpPlot(fit.k4[["finalModel"]])
k4Imp <- varImp(fit.k4, scale = FALSE)
k4Imp
print(k4Imp, top=57)

importance(fit.k4[["finalModel"]]) #use this, has the overall values

d1 %>% group_by(k4) %>% summarize(tally=n())
d1 %>% group_by(material) %>% summarize(tally=n())



rf <- randomForest(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                     Length_rev + Scale_rev + PP_size_nm_rev +
                     Contaminants_ + Contaminant_Type + Contaminant_Amount +
                     Functionalized_Type + Purification_Type + Modification +
                     Solubility + Zeta_Potential + Density + 
                     Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                     Agglomerated_ + Material_Category + material + Shape,
                   data=d1,
                   importance=T,
                   mtry=19)
rf

rf.pred <- predict(rf, d1)

confusionMatrix(data=rf.pred, reference=d1$k4)

data.frame(preds=rf.pred, obs=d1$k4, diff=obs-pred)

fit.k4[["finalModel"]][["confusion"]]
fit.k4[["finalModel"]][["importance"]]




###### conclusions
# use caret to find the best rf, using kappa instead of accuracy
# summarize model performance by the finalModel confusion and importance
# DO NOT make predictions back against the data
