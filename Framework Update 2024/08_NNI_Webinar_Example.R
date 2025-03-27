library(dplyr)
library(ggplot2)
library(Hmisc)     #describe
library(caret)
library(randomForest)

# run a scenario of using the RF model for hierachical clustering and order
# of magnitude bands
#
# let material = tio2, and observe the predicted group as well as vote %s
# observe how those change as more info is added
# e.g., scale, shape, etc.

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/04_output/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/08_output/"

### set seed for reproducibility
set.seed(71610)

model.hc <- readRDS(file=paste0(pathin,"cv.k8.RDS"))
model.oom <- readRDS(file=paste0(pathin, "cv.kOOM.RDS"))

example <- data.frame(material="TiO2")
example$material <- as.factor(example$material)

str(model.hc)
train <- model.hc$trainingData
summary(model.hc$trainingData$material)

temp <- train[1,1:21]

temp[1] <- as.factor("NA")
temp[2] <- as.factor("NA")
temp[3] <- -99
temp[4] <- as.factor("NA")

str(temp)
p <- predict(model.hc, newdata=temp)
