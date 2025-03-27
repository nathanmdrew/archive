########################################
###   Revise data
###
###     Some vars can be filled in (e.g. scale)
###     Implement reformats from EDK (e.g. CNT+MWCNT, id SW vs MW)
###     Resummarize overall, by complete link clust - ward clust - oom
###


library(dplyr)
library(readxl)

### load most recent data used in analyses
rev1 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\12_revised_RFs\\all2.rds")

#bring in study keys/refs for lookups
d1 <- read_excel(path="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_INPUT\\all_a_b_c.xlsx",
                 sheet=1)

d2 <- select(d1, index, study_key, StudyRef, Lit_Source)

rev2 <- left_join(rev1, d2) 

### material type
temp1 <- filter(rev2, material_type=="NA") #can replace these with Structure

rev2$material_type_rev <- if_else(rev2$material_type=="NA", 
                                  as.character(rev2$Structure), 
                                  as.character(rev2$material_type))


### Scale
#Set all missing scales to Nano - all come from lit update
temp <- filter(rev2, Scale=="NA")
rev2$Scale_rev <- if_else(rev2$Scale=="NA", 
                                  "Nano", 
                                  as.character(rev2$Scale))

#this one C60 is not nano
rev2$Scale_rev[rev2$index==107] <- "Micro"

summ <- rev2 %>% group_by(cluster.Ward, Scale_rev) %>% summarize(N=n())

write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\scale_by_Ward.csv")


###Structural Form
# Eileen wanted to combine/specify some groups
temp2 <- distinct(rev2, Structural_Form)

rev2$Structural_Form_rev <- as.character(rev2$Structural_Form)

rev2$Structural_Form_rev[rev2$Structural_Form=="Fiber-like"] <- "Nanobelt"
rev2$Structural_Form_rev[rev2$Structural_Form=='"Belt"'] <- "Nanobelt"
rev2$Structural_Form_rev[rev2$Structural_Form=="Belt"] <- "Nanobelt"
rev2$Structural_Form_rev[rev2$Structural_Form=="belt"] <- "Nanobelt"


rev2$Structural_Form_rev[rev2$Structural_Form=="short fiber"] <- "Nanofiber"

rev2$Structural_Form_rev[rev2$Structural_Form=='Particle; "Spheriod"'] <- "Spherical Particle"
rev2$Structural_Form_rev[rev2$Structural_Form=='Particle "Spherical"'] <- "Spherical Particle"
rev2$Structural_Form_rev[rev2$Structural_Form=="sphere"] <- "Spherical Particle"
rev2$Structural_Form_rev[rev2$Structural_Form=="spherical particle"] <- "Spherical Particle"
rev2$Structural_Form_rev[rev2$Structural_Form=="spheroid"] <- "Spherical Particle"


rev2$Structural_Form_rev[rev2$Structural_Form=="amorphous nanoparticle"] <- "Nanoparticles"
rev2$Structural_Form_rev[rev2$Structural_Form=="nanoparticles"] <- "Nanoparticles"

rev2$Structural_Form_rev[rev2$Structural_Form=="particle"] <- "Particle"

rev2$Structural_Form_rev[rev2$Structural_Form=="Tube"] <- "Nanotube"      #new change for TRTable3-7
rev2$Structural_Form_rev[rev2$Structural_Form=="nanotube"] <- "Nanotube"

rev2$Structural_Form_rev[rev2$Structural_Form=="rod"] <- "Nanorod" #new change for TRTable3-7


#check this aligns with TR Table 3-7
qc <- rev2 %>% group_by(Structural_Form_rev, cluster.Ward) %>% summarize(count=n())
qc <- arrange(qc, cluster.Ward, Structural_Form_rev) #looks good

#TODO fill in missing structural forms
temp <- filter(rev2, Structural_Form_rev=="NA")

#microC60 is a Microparticle - would the other C60 be a Particle or nanoparticle?



###Length
# Indicate differences in missingness - Not Reported vs. Not Applicable
# Lengths do not apply to spherical particles, but do to Tube, Fiber, Belt, etc.

rm(temp1)
temp1 <- filter(rev2, Length==-99)

# maintain -99 as NA
# use -9 as applicable but not reported

rev2$Length_rev <- rev2$Length

rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="Nanotube"] <- -9
rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="Nanorod"] <- -9
rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="Nanofiber"] <- -9
rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="Nanobelt"] <- -9
# Minor changes after meeting with Eileen
# Add nanoplates and flakes to the Length rule
#rev2 <- readRDS(file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\data2_REVISED.rds")
rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="nanoplates"] <- -9
rev2$Length_rev[rev2$Length==-99 & rev2$Structural_Form_rev=="flake"] <- -9


summA <- rev2 %>% filter(Length_rev>0) %>% group_by(cluster.Ward) %>%
        summarize(Minimum=min(Length_rev),
                  Q1=quantile(Length_rev,probs=0.25),
                  Median=median(Length_rev),
                  Q3=quantile(Length_rev,probs=0.75),
                  Maximum=max(Length_rev),
                  Mean=mean(Length_rev),
                  N_notMissing=n())

summB <- rev2 %>% filter(Length_rev==-9) %>% group_by(cluster.Ward) %>% summarize(N_notReported=n())
summC <- rev2 %>% filter(Length_rev==-99) %>% group_by(cluster.Ward) %>% summarize(N_notApplicable=n())

summBC <- left_join(summC, summB, by="cluster.Ward")
summABC <- left_join(summBC,summA, by="cluster.Ward")

write.csv(summABC,file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\length_by_Ward_withFlakesPlates.csv")



# !TODO: Something went awry; lost some crystal types 
### Crystal_Type and Crystal_Structure_
temp <- rev2 %>% select(index, material, material_type, Material_Category, Nanomat_Treatment, Structure, Structural_Form_rev, Crystal_Structure_, Crystal_Type)


#Carbon is NA
qc <- temp %>% filter(Material_Category=="Carbon") %>% distinct(Crystal_Type, Crystal_Structure_)
   #all NA; a few have an indicator of "N"

rev2$Crystal_Type_rev <- as.character(rev2$Crystal_Type)
rev2$Crystal_Structure_rev <- as.character(rev2$Crystal_Structure_)

rev2$Crystal_Type_rev[rev2$Material_Category=="Carbon"] <- "NA"
rev2$Crystal_Structure_rev[rev2$Material_Category=="Carbon"] <- "NA"

rev2$Crystal_Structure_rev[rev2$Crystal_Type_rev!="NA"] <- "Y"

rev2$Crystal_Type_rev[rev2$Structure=="crystalline"] <- "NR"
rev2$Crystal_Structure_rev[rev2$Structure=="crystalline"] <- "Y"

temp <- rev2 %>% filter(Crystal_Structure_rev=="NA")

rev2$Crystal_Type_rev[rev2$index==78] <- "Amorphous"
rev2$Crystal_Structure_rev[rev2$index==78] <- "Y"

temp <- rev2 %>% filter(Material_Category != "Carbon", Crystal_Structure_rev=="NA")
                        
                      
rev2$Crystal_Type_rev[rev2$Material_Category != "Carbon" & rev2$Crystal_Structure_=="NA"] <- "NR"
rev2$Crystal_Structure_rev[rev2$Material_Category != "Carbon" & rev2$Crystal_Structure_=="NA"] <- "NR"

rev2$Crystal_Type_rev[rev2$index==93] <- "NA"
rev2$Crystal_Structure_rev[rev2$index==93] <- "NA"

rev2$Crystal_Type_rev[rev2$index %in% c(4,5,6,7)] <- "NR"
rev2$Crystal_Structure_rev[rev2$index %in% c(4,5,6,7)] <- "NR"

temp <- rev2 %>% filter(Crystal_Structure_rev=="NR", Crystal_Type_rev=="NA")

summ <- rev2 %>% group_by(cluster.Ward, Crystal_Structure_rev, Crystal_Type_rev) %>% summarize(N=n())
write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\crystal_by_Ward.csv")



#Density
summ <- rev2 %>% 
        filter(Density>0) %>%
        group_by(cluster.Ward) %>% 
        summarize(Minimum=min(Density),
                  Q1=quantile(Density,probs=0.25),
                  Median=median(Density),
                  Q3=quantile(Density,probs=0.75),
                  Maximum=max(Density),
                  Mean=mean(Density),
                  N_notMissing=n())
write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\density_by_Ward.csv")



#Zeta Potential
summ <- rev2 %>% 
  filter(Zeta_Potential != -99) %>%
  group_by(cluster.Ward) %>% 
  summarize(Minimum=min(Zeta_Potential),
            Q1=quantile(Zeta_Potential,probs=0.25),
            Median=median(Zeta_Potential),
            Q3=quantile(Zeta_Potential,probs=0.75),
            Maximum=max(Zeta_Potential),
            Mean=mean(Zeta_Potential),
            N_notMissing=n())
write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\zetaPotential_by_Ward.csv")



#Primary Particle Size
summ <- rev2 %>% 
  filter(PP_size_nm != -99) %>%
  group_by(cluster.Ward) %>% 
  summarize(Minimum=min(PP_size_nm),
            Q1=quantile(PP_size_nm,probs=0.25),
            Median=median(PP_size_nm),
            Q3=quantile(PP_size_nm,probs=0.75),
            Maximum=max(PP_size_nm),
            Mean=mean(PP_size_nm),
            N_notMissing=n())
write.csv(summ, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\primaryParticleSize_by_Ward.csv")




#######   Save the revised data
#saveRDS(rev2, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\data2_REVISED.rds")
#write.csv(rev2, file="Z:\\ENM Categories\\Framework Update 2019\\13_data_revisions_OUTPUT\\data2_REVISED.csv")









#!!! Scale TODO: have a defined rule for setting scale based on particle dimension info
rm(temp1)
temp1 <- filter(rev2, Scale=="NA")

#most will be nano - check for non-nanos in other fields
temp1$Scale_rev <- "Nano"


# check
# 75 76 77 91 92 93 107 108 111 122 125 126 150 151 153

#initially thought to use MMAD to determine scale - doesn't work.  need primary size
#temp1$Scale_rev[temp1$index==77] <- "Micro" #graphite - synthetic; mmad 2.18-2.96 from pub ---> micro?
#temp1$Scale_rev[temp1$index==107] <- "Micro" #MicroC60 --> micro?

# what is nano, then?
# https://www.cdc.gov/niosh/topics/nanotech/faq.html
# Research and technology development involves structures with at least one dimension 
#    in the 1-100 nanometer range.

temp2 <- select(temp1, index, material, material_type_rev, Scale_rev, Structural_Form, Diameter, Length, 
                Nanomat_Treatment, PP_size_nm)

#for those with non-missing Scale, summarize nano vs. micro size vars
summ1 <- filter(rev2, Scale != "NA")
summ1$Diameter[summ1$Diameter==-99] <- NA
summ1$Length[summ1$Length==-99] <- NA
summ1$PP_size_nm[summ1$PP_size_nm==-99] <- NA

summ1.nano <- filter(summ1, Scale=="Nano")
summ1.micro <- filter(summ1, Scale!="Nano")

summary(summ1.nano$Diameter)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#   5.94   25.00   25.00   51.76   39.00  200.00       1 
summary(summ1.micro$Diameter)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#  135.0   171.9   250.0   416.2   300.0  1400.0       7



summary(summ1.nano$Length)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#   3000    7000    7500    7911    7500   20000      15 
summary(summ1.micro$Length)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#     NA      NA      NA     NaN      NA      NA      13 



summary(summ1.nano$PP_size_nm)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#     25      25      25      25      25      25      42 

summary(summ1.micro$PP_size_nm)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#    180    2233    2584    2179    2686    2891       7 

summ1.nano$ind_nano <- if_else(summ1.nano$Diameter>100 && summ1.nano$Length>100 && summ1.nano$PP_size_nm>100, 0, 1, -1)
summ1.micro$ind_nano <- if_else(summ1.micro$Diameter>100 && summ1.micro$Length>100 && summ1.micro$PP_size_nm>100, 0, 1, -1)
