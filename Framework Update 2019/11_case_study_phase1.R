###########################
###   Case Study - Phase 1
###
###   Iteratively predict cluster for a pseudo-TiO2
###      Start with only knowing it is a TiO2
###      One-at-a-time add most important pchem
###         values = median/mean from other TiO2s in the data
###
###   Track cluster predictions and votes (probabilities)
###

library(dplyr)
library(randomForest)

# Random Forest Classification Model - Ward's Method


# Data

