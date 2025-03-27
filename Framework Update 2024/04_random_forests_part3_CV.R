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




d1 <- readRDS(file=paste0(pathin,"trimmed_data.RDS"))

# d1.k4 <- d1 %>% select(k4, Crystal_Structure_rev, Crystal_Type_rev,
#                          Length_rev, Scale_rev, PP_size_nm_rev,
#                          Contaminants_, Contaminant_Type, Contaminant_Amount,
#                          Functionalized_Type, Purification_Type, Modification,
#                          Solubility, Zeta_Potential, Density, 
#                          Surface_Area, Median_Aerodynamic_Diameter, Diameter,
#                          Agglomerated_, Material_Category, material, Shape)

trg <- data.frame(mtry=seq(1,21,by=1)) #restrict CV to mtry <= # predictors



start.time <- Sys.time()

### set seed for reproducibility
set.seed(71610)

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

fit.k5 <- train(k5 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.k6 <- train(k6 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.k7 <- train(k7 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.k8 <- train(k8 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.k9 <- train(k9 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.k10 <- train(k10 ~ Crystal_Structure_rev + Crystal_Type_rev +
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

fit.kOOM <- train(kOOM ~ Crystal_Structure_rev + Crystal_Type_rev +
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
time.taken #Time difference of 27.23249 mins


# saveRDS(fit.k4, file=paste0(pathout,"fit.k4.RDS"))
# saveRDS(fit.k5, file=paste0(pathout,"fit.k5.RDS"))
# saveRDS(fit.k6, file=paste0(pathout,"fit.k6.RDS"))
# saveRDS(fit.k7, file=paste0(pathout,"fit.k7.RDS"))
# saveRDS(fit.k8, file=paste0(pathout,"fit.k8.RDS"))
# saveRDS(fit.k9, file=paste0(pathout,"fit.k9.RDS"))
# saveRDS(fit.k10, file=paste0(pathout,"fit.k10.RDS"))
# saveRDS(fit.kOOM, file=paste0(pathout,"fit.kOOM.RDS"))

fit.k4 #19
fit.k5 #14
fit.k6 #17
fit.k7 #19
fit.k8 #10 
fit.k9 #9
fit.k10 #16 
fit.kOOM #10
 
fit.k4[["finalModel"]][["confusion"]]
fit.k4[["finalModel"]][["importance"]]



rf <- randomForest(k4 ~ Crystal_Structure_rev + Crystal_Type_rev +
                     Length_rev + Scale_rev + PP_size_nm_rev +
                     Contaminants_ + Contaminant_Type + Contaminant_Amount +
                     Functionalized_Type + Purification_Type + Modification +
                     Solubility + Zeta_Potential + Density + 
                     Surface_Area + Median_Aerodynamic_Diameter + Diameter +
                     Agglomerated_ + Material_Category + material + Shape,
                   data=d1,
                   importance=T,
                   mtry=6)
rf
varImpPlot(rf)
# a little different than the CV model
# CV models create dummy vars for the factor predictors, making it difficult
# to assess variable importance




# x <- as.data.frame(d1.k4[,-1])
# y <- unlist(as.vector(d1.k4[,1]))
# 
# temp <- train(x=x,
#               y=y,
#                 method="rf",
#                 importance=T,
#                 tuneGrid=trg,
#                 metric="Kappa",
#                 trControl=trainControl(method="repeatedcv",
#                                        number=10,
#                                        repeats=10))
# temp
# temp[["finalModel"]][["confusion"]]
# temp[["finalModel"]][["importance"]]
#still different than a separate RF call, but now variables are maintained





d1.k4 <- d1 %>% select(k4, Crystal_Structure_rev, Crystal_Type_rev,
                         Length_rev, Scale_rev, PP_size_nm_rev,
                         Contaminants_, Contaminant_Type, Contaminant_Amount,
                         Functionalized_Type, Purification_Type, Modification,
                         Solubility, Zeta_Potential, Density,
                         Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                         Agglomerated_, Material_Category, material, Shape)

d1.k5 <- d1 %>% select(k5, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.k6 <- d1 %>% select(k6, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.k7 <- d1 %>% select(k7, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.k8 <- d1 %>% select(k8, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.k9 <- d1 %>% select(k9, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.k10 <- d1 %>% select(k10, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

d1.kOOM <- d1 %>% select(kOOM, Crystal_Structure_rev, Crystal_Type_rev,
                       Length_rev, Scale_rev, PP_size_nm_rev,
                       Contaminants_, Contaminant_Type, Contaminant_Amount,
                       Functionalized_Type, Purification_Type, Modification,
                       Solubility, Zeta_Potential, Density,
                       Surface_Area, Median_Aerodynamic_Diameter, Diameter,
                       Agglomerated_, Material_Category, material, Shape)

start.time <- Sys.time()

### set seed for reproducibility
set.seed(71610)

x <- as.data.frame(d1.k4[,-1]) #maintain across all fits
y <- unlist(as.vector(d1.k4[,1]))
cv.k4 <- train(x=x,
              y=y,
                method="rf",
                importance=T,
                tuneGrid=trg,
                metric="Kappa",
                trControl=trainControl(method="repeatedcv",
                                       number=10,
                                       repeats=10))

y <- unlist(as.vector(d1.k5[,1]))
cv.k5 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.k6[,1]))
cv.k6 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.k7[,1]))
cv.k7 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.k8[,1]))
cv.k8 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.k9[,1]))
cv.k9 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.k10[,1]))
cv.k10 <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

y <- unlist(as.vector(d1.kOOM[,1]))
cv.kOOM <- train(x=x,
               y=y,
               method="rf",
               importance=T,
               tuneGrid=trg,
               metric="Kappa",
               trControl=trainControl(method="repeatedcv",
                                      number=10,
                                      repeats=10))

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken #Time difference of 3.719012 hours

cv.k4
cv.k5
cv.k6
cv.k7
cv.k8
cv.k9
cv.k10
cv.kOOM
warnings() #empty classes


cv.k4[["finalModel"]][["confusion"]]
cv.k5[["finalModel"]][["confusion"]]
cv.k6[["finalModel"]][["confusion"]]
cv.k7[["finalModel"]][["confusion"]]
cv.k8[["finalModel"]][["confusion"]]
cv.k9[["finalModel"]][["confusion"]]
cv.k10[["finalModel"]][["confusion"]]
cv.kOOM[["finalModel"]][["confusion"]]

saveRDS(cv.k4, file=paste0(pathout,"cv.k4.RDS"))
saveRDS(cv.k5, file=paste0(pathout,"cv.k5.RDS"))
saveRDS(cv.k6, file=paste0(pathout,"cv.k6.RDS"))
saveRDS(cv.k7, file=paste0(pathout,"cv.k7.RDS"))
saveRDS(cv.k8, file=paste0(pathout,"cv.k8.RDS"))
saveRDS(cv.k9, file=paste0(pathout,"cv.k9.RDS"))
saveRDS(cv.k10, file=paste0(pathout,"cv.k10.RDS"))
saveRDS(cv.kOOM, file=paste0(pathout,"cv.kOOM.RDS"))