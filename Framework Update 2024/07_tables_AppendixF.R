library(dplyr)
library(ggplot2)
library(readxl)

pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/07_output/"

#### Table F2 ####
oldF2 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/Table_F2_extReview.xlsx")
names(oldF2)
oldF2 <- oldF2 %>% rename(index=`Index†`)


d1 <- readRDS(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/trimmed_data.RDS")
d1.sub <- d1 %>% select(index, material, material_type_rev, study_key, StudyRef, Lit_Source)


refs1 <- left_join(x=d1.sub, y=oldF2, by="index")

##################################################################
#################### Tables F-4 through F-8 ######################
##################################################################
s <- d1 %>% select(Length_rev, Crystal_Structure_rev, Crystal_Type_rev, Density,
                   Zeta_Potential, PP_size_nm_rev, k4, k5, k6, k7, k8, k9, 
                   k10, kOOM)

#####          Table F4 Length within hazard potency groups k8)
#              ------------------------------------------------

# Length=-9 means relevant but not available; Length=-99 means NA (e.g. particles)
temp <- s %>% select(Length_rev, k8) %>% filter(Length_rev<0)

temp2 <- table(temp$Length_rev, temp$k8) #get the last 2 rows of Table F4

s$Length_rev[s$Length_rev==-99] <- NA
s$Length_rev[s$Length_rev==-9] <- NA

s2 <- s %>% group_by(k8) %>% summarize(mini = min(Length_rev, na.rm=T),
                                       qua1 = quantile(Length_rev, 0.25, na.rm=T),
                                       medi = median(Length_rev, na.rm=T),
                                       aver = mean(Length_rev, na.rm=T),
                                       qua3 = quantile(Length_rev, 0.75, na.rm=T),
                                       maxi = max(Length_rev, na.rm=T),
                                       tally=n())
s2

t.s2 <- t(s2)
t.s2

t.F4 <- rbind(t.s2, temp2)
t.F4

saveRDS(t.F4, file=paste0(pathout,"tableF4.k8.RDS"))
write.csv(t.F4, file=paste0(pathout, "tableF4.k8.csv"))


#####          Table F5 Crystallinity within hazard potency groups k8)
#              -------------------------------------------------------

t.F5 <- s %>% select(k8, Crystal_Type_rev, Crystal_Structure_rev) %>%
            group_by(k8, Crystal_Structure_rev, Crystal_Type_rev) %>%
            summarize(tally=n())
t.F5

saveRDS(t.F5, file=paste0(pathout,"tableF5.k8.RDS"))
write.csv(t.F5, file=paste0(pathout, "tableF5.k8.csv"))


#####          Table F6 Density within hazard potency groups k8)
#              -------------------------------------------------------
summary(d1$Density)

s$Density[s$Density==-99] <- NA

s2 <- s %>% group_by(k8) %>% summarize(mini = min(Density, na.rm=T),
                                       qua1 = quantile(Density, 0.25, na.rm=T),
                                       medi = median(Density, na.rm=T),
                                       aver = mean(Density, na.rm=T),
                                       qua3 = quantile(Density, 0.75, na.rm=T),
                                       maxi = max(Density, na.rm=T),
                                       tally=n(),
                                       nmiss = sum(is.na(Density))
                                       )
s2

t.F6 <- t(s2)
t.F6

saveRDS(t.F6, file=paste0(pathout,"tableF6.k8.RDS"))
write.csv(t.F6, file=paste0(pathout, "tableF6.k8.csv"))


#####          Table F7 Zeta Potential within hazard potency groups k8)
#              ---------------------------------------------------------
summary(d1$Zeta_Potential)

s$Zeta_Potential[s$Zeta_Potential==-99] <- NA


s2 <- s %>% group_by(k8) %>% summarize(mini = min(Zeta_Potential, na.rm=T),
                                       qua1 = quantile(Zeta_Potential, 0.25, na.rm=T),
                                       medi = median(Zeta_Potential, na.rm=T),
                                       aver = mean(Zeta_Potential, na.rm=T),
                                       qua3 = quantile(Zeta_Potential, 0.75, na.rm=T),
                                       maxi = max(Zeta_Potential, na.rm=T),
                                       tally=n(),
                                       nmiss = sum(is.na(Zeta_Potential))
                                      )
s2

t.F7 <- t(s2)
t.F7

saveRDS(t.F7, file=paste0(pathout,"tableF7.k8.RDS"))
write.csv(t.F7, file=paste0(pathout, "tableF7.k8.csv"))


#####          Table F8 Primary Particle Size within hazard potency groups k8)
#              ---------------------------------------------------------
summary(d1$PP_size_nm_rev)


s$PP_size_nm_rev[s$PP_size_nm_rev==-99] <- NA


s2 <- s %>% group_by(k8) %>% summarize(mini = min(PP_size_nm_rev, na.rm=T),
                                       qua1 = quantile(PP_size_nm_rev, 0.25, na.rm=T),
                                       medi = median(PP_size_nm_rev, na.rm=T),
                                       aver = mean(PP_size_nm_rev, na.rm=T),
                                       qua3 = quantile(PP_size_nm_rev, 0.75, na.rm=T),
                                       maxi = max(PP_size_nm_rev, na.rm=T),
                                       tally=n(),
                                       nmiss = sum(is.na(PP_size_nm_rev))
)
s2

t.F8 <- t(s2)
t.F8

saveRDS(t.F8, file=paste0(pathout,"tableF8.k8.RDS"))
write.csv(t.F8, file=paste0(pathout, "tableF8.k8.csv"))
