### Read in the pooled Thomson et al data
### Fit exploratory model averages
### Compare using only the first control group vs. pooled controls

library(ToxicR)
library(ggplot2)

profile <- Sys.getenv("USERNAME")

pathin  <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/04_output/")
pathout <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/04a_output/")

d <- read.csv(file=paste0(pathin,"data_out.csv"),
              header=T)


set1 <- rbind(d[1,], d[6:10,]) #Aluminum, first control
set2 <- rbind(d[21,], d[6:10,]) #Aluminum, pooled control
set3 <- rbind(d[11,], d[16:20,]) #Brass, first control
set4 <- rbind(d[21,], d[16:20,]) #Brass, pooled control


maFits <- vector(mode="list", length=4) #initialize spots to store MA fits

#Dose = column 4
#Y = mean [7], n [6], sd [8]
maFits[[1]] <- ToxicR::ma_continuous_fit(D=set1[,4],
                                         Y=cbind(set1[,7], set1[,6], set1[,8]),
                                         fit_type="mle",
                                         BMR_TYPE="abs",
                                         BMR=4)

maFits[[2]] <- ToxicR::ma_continuous_fit(D=set2[,4],
                                         Y=cbind(set2[,7], set2[,6], set2[,8]),
                                         fit_type="mle",
                                         BMR_TYPE="abs",
                                         BMR=4)

maFits[[3]] <- ToxicR::ma_continuous_fit(D=set3[,4],
                                         Y=cbind(set3[,7], set3[,6], set3[,8]),
                                         fit_type="mle",
                                         BMR_TYPE="abs",
                                         BMR=4)

maFits[[4]] <- ToxicR::ma_continuous_fit(D=set4[,4],
                                         Y=cbind(set4[,7], set4[,6], set4[,8]),
                                         fit_type="mle",
                                         BMR_TYPE="abs",
                                         BMR=4)




summary(maFits[[1]])
p <- plot(maFits[[1]])
p$labels$title <- "Continuous MA Estimate for Thomson 2014, Aluminum dust, 1 control \n
                   33.29 (25.49, 38.23) 90.0% CI"
p$labels$x <- "Exposure Concentration (mg/m3)"
p$labels$y <- "Response - PMN%"
p
ggsave(filename=paste0(pathout,"thomson_al_1control.png"), plot=p, bg="white")

summary(maFits[[2]])
p <- plot(maFits[[2]])
p$labels$title <- "Continuous MA Estimate for Thomson 2014, Aluminum dust, pooled control \n
                   31.51 (23.43, 39.70) 90.0% CI"
p$labels$x <- "Exposure Concentration (mg/m3)"
p$labels$y <- "Response - PMN%"
p
ggsave(filename=paste0(pathout,"thomson_al_pooled_control.png"), plot=p, bg="white")


summary(maFits[[3]])
p <- plot(maFits[[3]])
p$labels$title <- "Continuous MA Estimate for Thomson 2014, Brass dust, 1 control \n
                   0.20 (0.06, 0.44) 90.0% CI"
p$labels$x <- "Exposure Concentration (mg/m3)"
p$labels$y <- "Response - PMN%"
p
ggsave(filename=paste0(pathout,"thomson_brass_1control.png"), plot=p, bg="white")


summary(maFits[[4]])
p <- plot(maFits[[4]])
p$labels$title <- "Continuous MA Estimate for Thomson 2014, Brass dust, pooled control \n
                   0.20 (0.06, 0.44) 90.0% CI"
p$labels$x <- "Exposure Concentration (mg/m3)"
p$labels$y <- "Response - PMN%"
p
ggsave(filename=paste0(pathout,"thomson_brass_pooled_control.png"), plot=p, bg="white")





#save
write.csv(set1, file = paste0(pathout,"thomson_al_1control.csv"))
write.csv(set2, file = paste0(pathout,"thomson_al_pooled_control.csv"))
write.csv(set3, file = paste0(pathout,"thomson_brass_1control.csv"))
write.csv(set4, file = paste0(pathout,"thomson_brass_pooled_control.csv"))

saveRDS(d, file=paste0(pathout,"d.RDS"))
saveRDS(maFits, file=paste0(pathout, "maFits.RDS"))

