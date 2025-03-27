#    Eileen identified missing data (female rats) for Gosens et al 2014
#    Further investigation found numerous issues
#    Starting from the beginning, data was compiled and Eileen estimated deposition information
#
#    This file computes model averages for comparison to BMDS single fits



library(dplyr)
library(readxl)
library(ToxicR)

profile <- Sys.getenv("USERNAME")

pathin  <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/Gosens 2014 Recheck/")
pathout <- paste0("C:/Users/", 
                  profile, 
                  "/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/03_output/")


d <- read_excel(path=paste0(pathin,"Gosens et al 2014 Data Redo.xlsx"),
                sheet=1,
                col_names=T)

keys <- d %>% distinct(Material, Sex)
keys$index <- seq(from=1, to=nrow(keys), by=1)

d2 <- merge(d, keys)
d2 <- arrange(d2, index, `Deposited Dose (ug/g lung)`)


maFits <- vector(mode="list", length=nrow(keys))

#model initial deposited dose-response
for (ii in 1:nrow(keys)){
  currentData <- d2[d2$index==ii,]
  doses=currentData[,4]
  #Y = mean, n, sd
  resp=dplyr::bind_cols(currentData[,7],
                        currentData[,6],
                        currentData[,8])
  
  
  maFits[[ii]] <- ToxicR::ma_continuous_fit(D=doses,
                                            Y=resp,
                                            fit_type="mle",
                                            BMR_TYPE="abs",
                                            BMR=4)
  
}

summary(maFits[[1]])
p <- plot(maFits[[1]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-211 Male \n
                   111.70 (70.69, 149.13) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p

summary(maFits[[2]])
p <- plot(maFits[[2]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-211 Female \n
                   44.46 (13.95, 80.47) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p

summary(maFits[[3]])
p <- plot(maFits[[3]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-212 Male \n
                   274.04 (160.64, 404.12) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p

summary(maFits[[4]])
p <- plot(maFits[[4]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-212 Female \n
                   90.48 (29.69, 158.59) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p

summary(maFits[[5]])
p <- plot(maFits[[5]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-213 Male \n
                   386.92 (215.10, 537.52) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p

summary(maFits[[6]])
p <- plot(maFits[[6]])
p$labels$title <- "Continuous MA Estimate for Gosens 2014, NM-213 Female \n
                   323.90 (176.64, 470.76) 90.0% CI"
p$labels$x <- "Deposited Dose (ug/g lung)"
p$labels$y <- "Response - PMN%"
p


maFitsAlternate <- vector(mode="list", length=4)

#model alternate deposited dose-response, not available for NM-213
for (ii in 1:4){
  currentData <- d2[d2$index==ii,]
  doses=currentData[,5]
  #Y = mean, n, sd
  resp=dplyr::bind_cols(currentData[,7],
                        currentData[,6],
                        currentData[,8])
  
  
  maFitsAlternate[[ii]] <- ToxicR::ma_continuous_fit(D=doses,
                                            Y=resp,
                                            fit_type="mle",
                                            BMR_TYPE="abs",
                                            BMR=4)
  
}


summary(maFits[[1]])
summary(maFitsAlternate[[1]]) #should be a constant factor difference (~1.74)


