######################################
###  Random Forests
###  
###
###  2021-08-16
###  Investigate the effect of removing the 8 duplicate NanoGo records
###


#TODO
# fine-tune pchem
# heatmap of missingness
# correlations between pchem
# backwards selection models

library(dplyr)
library(ggplot2)
library(randomForest)

set.seed(51118) #sully

data1 <- readRDS(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2019/03_cluster_all_pmn_OUTPUT/final_data.rds")
#write.csv(data1, file="Z:\\ENM Categories\\Framework Update 2019\\03_cluster_all_pmn_OUTPUT\\final_data.csv")

data1$cluster.Complete <- as.factor(data1$cluster.Complete)
data1$cluster.Ward <- as.factor(data1$cluster.Ward)

#Change um lengths to nm   *1000
data1$Length[data1$Length=="3"] <- "3000"
data1$Length[data1$Length=="9"] <- "9000"
data1$Length[data1$Length=="20"] <- "20000"
data1$Length[data1$Length=="5"] <- "5000"

#remove extraneous vars
data2 <- data1 %>% select(-study_key, -StudyRef, -Material_Manufacturer, -Material_Lot_Number,
                          -reported_diameter, -Diameter_Units, -Diameter_method, -reported_length,
                          -Length_Units, -Thickness, -Thickness_Units, -Rigidity, -Entangled,
                          -Aerodynamic_Diameter_Units, -Surface_Area_Units, -Surface_Area_Method,
                          -Volume, -Density_units, -Density_method, -Zeta_Potential_Units,
                          -Solubility_Method, -Coated_Type, -Ground_Type, -BMD, -BMDL,
                          -Lit_Source, -Notes)

data2$rand <- runif(nrow(data2),min=1, max=100)

data2$material_type[is.na(data2$material_type)] <- "NA"
data2$Scale[is.na(data2$Scale)] <- "NA"
data2$Agglomerated_[is.na(data2$Agglomerated_)] <- "NA"
data2$Crystal_Structure_[is.na(data2$Crystal_Structure_)] <- "NA"
data2$Median_Aerodynamic_Diameter[is.na(data2$Median_Aerodynamic_Diameter)] <- "NA"
data2$Aerodynamic_Diameter_GSD[is.na(data2$Aerodynamic_Diameter_GSD)] <- "NA"
data2$Surface_Charge[is.na(data2$Surface_Charge)] <- "NA"
data2$Zeta_Potential[is.na(data2$Zeta_Potential)] <- "NA"
data2$Solubility[is.na(data2$Solubility)] <- "NA"
data2$Modification[is.na(data2$Modification)] <- "NA"
data2$Purification_Type[is.na(data2$Purification_Type)] <- "NA"
data2$Functionalized_Type[is.na(data2$Functionalized_Type)] <- "NA"
data2$Contaminants_[is.na(data2$Contaminants_)] <- "NA"
data2$Contaminant_Type[is.na(data2$Contaminant_Type)] <- "NA"
data2$Contaminant_Amount[is.na(data2$Contaminant_Amount)] <- "NA"
data2$Nanomat_Treatment[is.na(data2$Nanomat_Treatment)] <- "NA"
data2$PP_size_nm[is.na(data2$PP_size_nm)] <- "NA"
data2$Structure[is.na(data2$Structure)] <- "NA"
data2$Surface_reactivity[is.na(data2$Surface_reactivity)] <- "NA"
data2$Surface_modifications[is.na(data2$Surface_modifications)] <- "NA"

data2$Diameter <- as.numeric(data2$Diameter)
data2$Length <- as.numeric(data2$Length)
data2$Median_Aerodynamic_Diameter <- as.numeric(data2$Median_Aerodynamic_Diameter)
data2$Aerodynamic_Diameter_GSD <- as.numeric(data2$Aerodynamic_Diameter_GSD)
data2$Surface_Area <- as.numeric(data2$Surface_Area)
data2$Density <- as.numeric(data2$Density)
data2$Surface_Charge <- as.numeric(data2$Surface_Charge)
data2$Zeta_Potential <- as.numeric(data2$Zeta_Potential)
data2$Contaminant_Amount <- as.numeric(data2$Contaminant_Amount)
data2$PP_size_nm <- as.numeric(data2$PP_size_nm)

data2$Diameter[is.na(data2$Diameter)] <- -99
data2$Length[is.na(data2$Length)] <- -99
data2$Median_Aerodynamic_Diameter[is.na(data2$Median_Aerodynamic_Diameter)] <- -99
data2$Aerodynamic_Diameter_GSD[is.na(data2$Aerodynamic_Diameter_GSD)] <- -99
data2$Surface_Area[is.na(data2$Surface_Area)] <- -99
data2$Density[is.na(data2$Density)] <- -99
data2$Surface_Charge[is.na(data2$Surface_Charge)] <- -99
data2$Zeta_Potential[is.na(data2$Zeta_Potential)] <- -99
data2$Contaminant_Amount[is.na(data2$Contaminant_Amount)] <- -99
data2$PP_size_nm[is.na(data2$PP_size_nm)] <- -99

data2$material <- as.factor(data2$material)
data2$material_type <- as.factor(data2$material_type)
data2$Material_Category <- as.factor(data2$Material_Category)
data2$Scale <- as.factor(data2$Scale)
data2$Agglomerated_ <- as.factor(data2$Agglomerated_)
data2$Structural_Form <- as.factor(data2$Structural_Form)
data2$Crystal_Structure_ <- as.factor(data2$Crystal_Structure_)
data2$Crystal_Type <- as.factor(data2$Crystal_Type)
data2$Solubility <- as.factor(data2$Solubility)
data2$Modification <- as.factor(data2$Modification)
data2$Purification_Type <- as.factor(data2$Purification_Type)
data2$Functionalized_Type <- as.factor(data2$Functionalized_Type)
data2$Contaminants_ <- as.factor(data2$Contaminants_)
data2$Contaminant_Type <- as.factor(data2$Contaminant_Type)
data2$Post.Exp <- as.factor(data2$Post.Exp)
data2$Route <- as.factor(data2$Route)
data2$Nanomat_Treatment <- as.factor(data2$Nanomat_Treatment)
data2$Structure <- as.factor(data2$Structure)
data2$Surface_reactivity <- as.factor(data2$Surface_reactivity)
data2$Surface_modifications <- as.factor(data2$Surface_modifications)

#str(data2)
#write.csv(x=data2, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\data2.csv")
data2 <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2019/04_random_forests_OUTPUT/data2.csv")
data2$cluster.Complete <- as.factor(data1$cluster.Complete)
data2$cluster.Ward <- as.factor(data1$cluster.Ward)

train1 <- filter(data2, rand<67)
test1 <- filter(data2, rand>67)

summary(train1$cluster.Complete) #79 5 4 2
summary(test1$cluster.Complete)  #25 0 0 0

summary(train1$cluster.Ward) #61 18 9 2
summary(test1$cluster.Ward) #19 6 0 0

train2a <- train1 %>% select(-index, -cluster.Ward, -rand, -material_type, -Nanomat_Treatment)

rf.Complete <- randomForest(cluster.Complete ~ ., data=train2a, importance=T)

rf.Complete
summary(rf.Complete)
plot(rf.Complete)
imp4 <- as.data.frame(importance(rf.Complete))
imp4[with(imp4, order("MeanDecreaseGini")), ]
varImpPlot(rf.Complete)
#write.csv(imp4, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\importance_complete.csv")

train2b <- train1 %>% select(-index, -cluster.Complete, -rand, -material_type, -Nanomat_Treatment)
rf.Ward <- randomForest(cluster.Ward ~ ., data=train2b, importance=T)

validation1a <- predict(object=rf.Complete, newdata=test1)
validation1b <- predict(object=rf.Ward, newdata=test1)

test1$pred.Complete <- validation1a
test1$pred.Ward <- validation1b

summary(data1$cluster.Complete)
summary(data1$cluster.Ward)


#saveRDS(train1, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\train1.rds")
#saveRDS(test1, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\test1.rds")


# manual confusion matrices
table(test1$cluster.Complete, test1$pred.Complete)
table(test1$cluster.Ward, test1$pred.Ward)

qc <- summary(test1, maxsum=100)
write.csv(x=qc, file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\qc.csv")
