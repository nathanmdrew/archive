##
##  This program puts BMD estimates into order-of-magnitude groups
##  Fits a RF
##  Evaluates accuracy of RF
##  Explores model improvement

library(dplyr)
library(ggplot2)
library(randomForest)

set.seed(51118) #sully

oldtrain1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\train1.rds")
oldtest1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\04_random_forests_OUTPUT\\test1.rds")

#read in data, combine, reformat
data1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\03_cluster_all_pmn_OUTPUT\\final_data.rds")

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
                          -Solubility_Method, -Coated_Type, -Ground_Type, -Lit_Source, -Notes)

data2$Crystal_Type[data2$Crystal_Type=="anatase"] <- "Anatase"
data2$Crystal_Type[data2$Crystal_Type=="rutile"] <- "Rutile"
data2$Crystal_Type[data2$Crystal_Type=="N/A"] <- "NA"

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
data2$BMD <- as.numeric(data2$BMD)
data2$BMDL <- as.numeric(data2$BMDL)

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

#saveRDS(data2, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")
data2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2.rds")


data2.summary <- summary(data2, maxsum=100)
#write.csv(data2.summary, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\data2_summary.csv")

# Order of Magnitude (oom) bands
all <- data2

# previous stuff made OoM based on BMDLs
all$cluster.OOM <- as.factor(case_when(all$BMDL < 0.01 ~ "< 0.01 ug/g lung",
                             all$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
                             all$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
                             all$BMDL < 10 ~ "1 - 10 ug/g lung",
                             all$BMDL < 100 ~ "10 - 100 ug/g lung",
                             all$BMDL < 1000 ~ "100 - 1000 ug/g lung",
                             all$BMDL < 10000 ~ "1000 - 10000 ug/g lung"))


summary(all$cluster.OOM)
#6 4 10 11 53 29 2

table_material_oom <- table(all$material, all$cluster.OOM)
write.csv(table_material_oom, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\table_material_oom.csv")


#table(all$cluster.OOM, all$cluster.OOM2)

#qc <- filter(all, cluster.OOM != cluster.OOM2)


#get previously used random integer for test/train assignment
# train<67
# test >67
old <- bind_rows(oldtrain1, oldtest1)
old <- old %>% select(index, rand)

all2 <- merge(all, old, by="index")

train <- filter(all2, rand<=67)
test <- filter(all2, rand>67)
 
train2 <- train %>% select(-index, -cluster.Complete, -cluster.Ward, -rand, -material_type, 
                           -Nanomat_Treatment, -BMD, -BMDL, -Post.Exp, -Route, -Surface_reactivity,
                           -Surface_modifications, -Surface_Charge, -Aerodynamic_Diameter_GSD)
names(train2)

#rf.oom <- randomForest(cluster.OOM ~ ., data=train2, importance=T)
#saveRDS(rf.oom, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\rf_oom1.rds")
rf.oom <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\rf_oom1.rds")

imp.rf.oom <- as.data.frame(importance(rf.oom))
imp.rf.oom[with(imp.rf.oom, order("MeanDecreaseGini")), ]
varImpPlot(rf.oom)
#write.csv(imp.rf.oom, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\importance_oom_RF.csv")

pred <- predict(object=rf.oom, newdata=test)

test2 <- test
test2$pred.OOM <- pred

rf.confusion <- table(test2$cluster.OOM, test2$pred.OOM)
rf.confusion
#write.csv(rf.confusion, file="Z:\\ENM Categories\\Framework Update 2019\\07_random_forest_oom_OUTPUT\\rf_confusion.csv")

acc <- sum(diag(rf.confusion))/sum(rf.confusion)
acc



#qc
qc <- filter(test2, cluster.OOM=="1 - 10 ug/g lung", pred.OOM=="10 - 100 ug/g lung")

#viz
legend_title <- "Order of Magnitude Group"

plot1 <- arrange(all, BMD)
plot1$index2 <- seq(1:nrow(plot1))

bmdl1 <- select(plot1, -BMD)
bmdl1 <- bmdl1 %>% rename(BMD=BMDL)

plot2 <- bind_rows(plot1,bmdl1)
plot2 <- arrange(plot2, index2)

ggplot(data=plot2, aes(x=BMD, y=index2, group=index2, color=cluster.OOM)) +
  geom_point() +
  geom_line() +
  labs(x="BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Order of Magnitude", color=legend_title) +
  theme(legend.position=c(0.8,0.5),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

ggplot(data=plot2, aes(x=log10(BMD), y=index2, group=index2, color=cluster.OOM)) +
  geom_point() +
  geom_line() +
  labs(x="Log10 BMDL - BMD (ug/g lung)", y=NULL, title="Potency Estimates (Background +4%) and Clusters",
       subtitle="Order of Magnitude", color=legend_title) +
  theme(legend.position=c(0.2,0.7),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())





# var selection
bwRF <- function(){
  backwards.rf <- randomForest(cluster.OOM ~ ., 
                                    data=backwards.train, 
                                    importance=T)
  
  backwards.imp <- as.data.frame(importance(backwards.rf))
  backwards.imp[with(backwards.imp, order("MeanDecreaseGini")), ]
  varImpPlot(backwards.rf)
  
  backwards.pred <- predict(object=backwards.rf, newdata=test)
  test2$backwards.pred <- backwards.pred
  
  bw.confusion <- table(test2$cluster.OOM, test2$backwards.pred)
  bw.confusion
  backwards.accuracy <- sum(diag(bw.confusion))/sum(bw.confusion)
  change.accuracy <- backwards.accuracy - acc
  change.accuracy #Positive = Better
  
}

backwards.train <- train2 %>% select(-Agglomerated_)
bwRF() #0

backwards.train <- backwards.train %>% select(-Median_Aerodynamic_Diameter)
bwRF() #-0.02439024
# So at this stage, only Agglomerated may be dropped without negatively impacting accuracy
# Let's continue and see what happens
# NOTE: 0.02439024*41 =~ 1, so we are adding 1 misclassification

backwards.train <- backwards.train %>% select(-Contaminant_Amount)
bwRF() #0

backwards.train <- backwards.train %>% select(-Solubility)
bwRF() #0

backwards.train <- backwards.train %>% select(-Contaminants_)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Purification_Type)
bwRF() #0

backwards.train <- backwards.train %>% select(-Contaminant_Type)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Crystal_Structure_)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Modification)
bwRF() #0

backwards.train <- backwards.train %>% select(-Zeta_Potential)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Length)
bwRF() #0

backwards.train <- backwards.train %>% select(-Material_Category)
bwRF() #0

backwards.train <- backwards.train %>% select(-Scale)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-PP_size_nm)
bwRF() #0

backwards.train <- backwards.train %>% select(-Crystal_Type)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Functionalized_Type)
bwRF() #-0.02439024

backwards.train <- backwards.train %>% select(-Density)
bwRF() #0

backwards.train <- backwards.train %>% select(-Diameter)
bwRF() #0

backwards.train <- backwards.train %>% select(-Surface_Area)
bwRF() # 0.07317073
### Gain 3 correct classifications?

backwards.train <- backwards.train %>% select(-material)
bwRF() #0.02439024
### Gain 1 correct classification


### So the findings are... weird.  Dropping low importance vars -> worse accuracy
###         Dropping high importance -> better accuracy
### Suspect some things
###     Correlations between variables
###     "feature engineering" needing which means I probably need to clean up vars some more
###           given the sparsity





############
### Try OoM groups = 4
all2$cluster.4OOM <- as.factor(case_when(
                               all2$BMD < 1.0 ~ "< 1 ug/g lung",
                               all2$BMD < 10 ~ "1 - 10 ug/g lung",
                               all2$BMD < 100 ~ "10 - 100 ug/g lung",
                               all2$BMD > 100 ~ "> 100 ug/g lung"))

summary(all2$cluster.4OOM)
#20 11 53 31 

train <- filter(all2, rand<=67)
test <- filter(all2, rand>67)

all3 <- all2 %>% select(-index, -cluster.Complete, -cluster.Ward, -cluster.OOM, -cluster.OOM2, -rand, -material_type, 
                           -Nanomat_Treatment, -BMD, -BMDL, -Post.Exp, -Route, -Surface_reactivity,
                           -Surface_modifications, -Surface_Charge, -Aerodynamic_Diameter_GSD)
rf.4oom.all <- randomForest()
