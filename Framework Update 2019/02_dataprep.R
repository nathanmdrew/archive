######################################
###  Get all of the datafiles together
###  Materials, BMDs, Pchem
###
###  2017 Framework (A)
###  Theresa/Alyssa (B)
###  Alyssa Krug/Indrani additions (C)


library(xlsx)
library(readxl)
library(dplyr)
library(cluster) #kmeans
library(ggplot2)

set.seed(51118) #sully


# TODO
#


######################
### 2017 Framework (A)

#all pchem
a.pchem1 <- read_excel(path="Z:\\ENM Categories\\DB\\physiochemical_database_12may2016.xlsx",
                       sheet=3)

a.pchem1$index <- seq(1:nrow(a.pchem1))

#NanoGo BMDs
a.nanogo1 <- read_excel(path="Z:\\ENM Categories\\Desktop Files\\Stuff\\86case code\\86case code\\32 Case Output BMRbg4\\NanoGo\\Trend Tests.xlsx",
                        sheet=3)
str(a.nanogo1)

a.nanogo2 <- a.nanogo1 %>% rename(study_key=`Study key`, StudyRef=`Study Reference`, 
                                  material=Material, material_type=`Material Type`)

a.nanogo3 <- a.nanogo2 %>% select(study_key, StudyRef, material, material_type, BMD, BMDL)


# NIOSH/ENPRA/CIIT (NEC) BMDs
a.nec1 <- read.csv(file="Z:\\ENM Categories\\_Final_Kriging_BMDs_BMR4_12oct2016.csv", header=T)

a.nec2 <- a.nec1 %>% rename(study_key=Study, StudyRef=Reference, material=Material,
                            material_type=Material.Type)

# inelegant copy-paste
a.nec2$BMDL <- c(14.23,
                 18.74,
                 4.69,
                 5.18,
                 0.57,
                 0.24,
                 0.22,
                 0.25,
                 23.96,
                 6.54,
                 3.73,
                 29.68,
                 21.96,
                 83.88,
                 100.11,
                 14.65,
                 2366.11,
                 365.33)

# combine together
a.keys <- a.pchem1 %>% select(index, study_key, StudyRef, material, material_type) %>% distinct()

a.nec3 <- left_join(a.nec2, a.keys) #some indeces are missing - differences in Material Type spelling
a.nec3$index[a.nec3$BMD==2.17] <- 5
a.nec3$index[a.nec3$BMD==29.68] <- 12
a.nec3$index[a.nec3$BMD==96.60] <- 13
a.nec3$index[a.nec3$BMD==57.96] <- 15
a.nec3$index[a.nec3$BMD==225.94] <- 16
a.nec3$index[a.nec3$BMD==241.09] <- 17
a.nec3$index[a.nec3$BMD==26.26] <- 18

a.nanogo4 <- left_join(a.nanogo3, a.keys)
a.nanogo4$rownum <- seq(1:nrow(a.nanogo4))
a.nanogo4$index[a.nanogo4$rownum==5] <- 40
a.nanogo4$index[a.nanogo4$rownum==6] <- 41 #Nanobelt or Nanosphere?  Go with what is in PCHEM (sphere)
a.nanogo4$index[a.nanogo4$rownum==8] <- 42
a.nanogo4$index[a.nanogo4$rownum==9] <- 43
a.nanogo4$index[a.nanogo4$rownum==14] <- 49
a.nanogo4$index[a.nanogo4$rownum==15] <- 48
a.nanogo4$index[a.nanogo4$rownum==17] <- 52
a.nanogo4$index[a.nanogo4$rownum==18] <- 51
a.nanogo4$index[a.nanogo4$rownum==20] <- 55
a.nanogo4$index[a.nanogo4$rownum==21] <- 54
a.nanogo4$index[a.nanogo4$rownum==23] <- 58
a.nanogo4$index[a.nanogo4$rownum==24] <- 57

a.nanogo5 <- a.nanogo4 %>% select(-rownum)

a.all1 <- left_join(a.pchem1, a.nec3, by="index")
a.all2 <- left_join(a.all1, a.nanogo5, by="index")

#clean up Join variable renames
a.all3 <- a.all2 %>% select(-study_key.y, -StudyRef.y, -material.y, -material_type.y,
                            -study_key, -StudyRef, -material, -material_type)

a.all4 <- a.all3 %>% rename(BMD=BMD.x, BMDL=BMDL.x)

a.all4$BMD <- if_else(!is.na(a.all4$BMD.y), a.all4$BMD.y, a.all4$BMD)
a.all4$BMDL <- if_else(!is.na(a.all4$BMDL.y), a.all4$BMDL.y, a.all4$BMDL)

a.all5 <- a.all4 %>% select(-BMD.y, -BMDL.y)

#fix indices - hacky but ok
a.all5$index[a.all5$BMD==35.370000] <- 72
a.all5$index[a.all5$BMD==9.080000] <- 73





#######################
### Theresa/Alyssa (B)

b.pod1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\TEB Finalized BMDs\\Finalized_BMDs.xlsx",
                     sheet=3)

b.pod1$index <- seq(1:nrow(b.pod1)) + nrow(a.all5)

b.cnt1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\TEB Finalized BMDs\\Finalized_BMDs.xlsx",
                     sheet=1)

#keep additional cnt specific pchem
b.cnt2 <- b.cnt1 %>% select(Material_Group, Material_Label, Study_ID, Nanomat_Treatment,
                            Functionalized, Length_nm)

b.ti1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\TEB Finalized BMDs\\Finalized_BMDs.xlsx",
                    sheet=2)

b.ti2 <- b.ti1 %>% select(Material_Group, Material_Label, Study_ID, Nanomat_Treatment,
                          Comp, Size)

b.all1 <- left_join(b.pod1, b.ti2, by=c("Study_ID", "Nanomat_Treatment"))

b.all2 <- left_join(b.all1, b.cnt2, by=c("Study_ID", "Nanomat_Treatment"))





#####################################
### Alyssa Krug/Indrani additions (C)



c.pod1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\Krug&Indrani_BMD\\BMD_Estimates_Reformatted.xlsx",
                     sheet=1)

c.pod1$index <- seq(1:nrow(c.pod1)) + nrow(a.all5) + nrow(b.all2)



c.pchem.krug1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\Updated Searches\\Krug_Update\\Krug_Summary_Template.xlsx",
                            sheet=2)
c.pchem.krug2 <- distinct(c.pchem.krug1, Study_ID, Chemical_comp, .keep_all=T)
c.pchem.krug3 <- c.pchem.krug2 %>% filter(Chemical_comp != "NA") %>% 
                                   filter(!is.na(Study_ID)) %>%
                                   rename(Nanomat_Treatment = Material_Treatment)

c.pchem.indr1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\Updated Searches\\Indrani_Update\\Indrani_Summary_Data_Template.xlsx",
                            sheet=2)
c.pchem.indr2 <- distinct(c.pchem.indr1, Study_ID, Chemical_comp, .keep_all=T)
c.pchem.indr3 <- c.pchem.indr2 %>% filter(Chemical_comp != "NA") %>% 
                                   filter(!is.na(Study_ID))%>%
                                   rename(Nanomat_Treatment = Material_Treatment)

# Fuuuuuuck nanomat_treatments are not identical between PoD and Pchem files !!!!!!!!!!! 
# Gotta hacky manually match up - 23 PoDs with 15+23=38 pchems
# Not too bad, but not ideal
# The dedupe/distinct above does exclude cases with multiple post-exposures
#    e.g. Indrani - Keller_2014 has CeO2 1dPE and 3dPE
#         Different indeces as they are different associations, but same material properties
#    Manually copied and added index

# NOTE! A pchem row MUST be mapped to every PoD row
#write.csv(c.pod1, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\c_pod.csv")
#write.csv(c.pchem.indr3, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\c_pchem_indr.csv")
#write.csv(c.pchem.krug3, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\c_pchem_krug.csv")

# In c.pod, Study=3745 should be Cu-1dPE, not CeO2
c.pod1$Nanomat_Treatment[c.pod1$Study_ID=="3745"] <- "Cu-1dPE"

c.pchem.indr4 <- read.csv(file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_INPUT\\c_pchem_indr_FIX.csv", header=T)
c.pchem.krug4 <- read.csv(file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_INPUT\\c_pchem_krug_FIX.csv", header=T)

c.pchem.indr4$Study_ID <- as.factor(c.pchem.indr4$Study_ID)
c.pchem.indr4$Specific_surface_area <- as.factor(c.pchem.indr4$Specific_surface_area)

c.pchem.all1 <- bind_rows(c.pchem.indr4, c.pchem.krug4)
c.pchem.all1 <- select(c.pchem.all1, -X)
#warnings()
# mostly things convert to CHR

c.all1 <- left_join(c.pod1, c.pchem.all1, by="index")


###################################
### Rename and reformat

names1 <- data.frame(varA=names(a.all5))
names2 <- data.frame(varB=names(b.all2))
names3 <- data.frame(varC=names(c.all1))
# manually copy-pasted into VARNAMES.xlsx

# Fix BMDs and BMDLs
b.all2$BMD <- b.all2$BMD.est. * 1000
b.all2$BMDL <- b.all2$BMDL.est. * 1000
b.all2 <- b.all2 %>% select(-BMD.est., -BMDL.est.)

c.all1$bmd1 <- as.numeric(c.all1$`BMD (mg/g lung)`)
c.all1$bmdl1 <- as.numeric(c.all1$`BMDL (mg/g lung)`)
c.all1$BMD <- c.all1$bmd1*1000
c.all1$BMDL <- c.all1$bmdl1*1000
c.all1 <- c.all1 %>% select(-bmd1, -bmdl1, -`BMD (mg/g lung)`, -`BMDL (mg/g lung)`)

b.all2 <- b.all2 %>% rename(Density=Density_mean)
c.all1 <- c.all1 %>% rename(Density=Density_mean)

b.all2 <- b.all2 %>% rename(Diameter=Diameter_mean_nm)
c.all1 <- c.all1 %>% rename(Diameter=Diameter_mean_nm)
c.all1$Diameter[c.all1$Diameter=="15-Apr"] <- "4-15"

c.all1$PP_Size_nm[c.all1$PP_Size_nm=="10-May"] <- "5-10"
c.all1$PP_Size_nm[c.all1$PP_Size_nm=="10-Jun"] <- "6-10"

b.all2 <- b.all2 %>% rename(Crystal_Type=Comp)
c.all1 <- c.all1 %>% rename(Crystal_Type=Structure)

a.all5 <- a.all5 %>% rename(StudyRef=StudyRef.x)
b.all2 <- b.all2 %>% rename(StudyRef=Author_Year)
c.all1 <- c.all1 %>% rename(StudyRef=Author_Year.x) %>% select(-Author_Year.y)

a.all5 <- a.all5 %>% rename(study_key=study_key.x)
b.all2 <- b.all2 %>% rename(study_key=Study_ID)
c.all1 <- c.all1 %>% rename(study_key=Study_ID.x) %>% select(-Study_ID.y)

b.all2 <- b.all2 %>% rename(Surface_Area=Specific_surface_area)
c.all1 <- c.all1 %>% rename(Surface_Area=Specific_surface_area)

b.all2 <- b.all2 %>% rename(Length=Length_nm)
c.all1 <- c.all1 %>% rename(Length=Length_mean_nm)

c.all1 <- c.all1 %>% rename(Surface_Area_Units=Specific_surface_area_units)

b.all2 <- b.all2 %>% rename(Functionalized_Type=Functionalized)

a.all5 <- a.all5 %>% rename(material=material.x)
b.all2 <- b.all2 %>% rename(material=Material_Group.x) %>% select(-Material_Group.y, -Material_Group)
#c.all1 <- c.all1 %>% rename(material=)#########

a.all5 <- a.all5 %>% rename(material_type=material_type.x)
b.all2 <- b.all2 %>% rename(material_type=Material_Label.x)

c.all1 <- c.all1 %>% rename(Notes=Comments_Other)
c.all1 <- c.all1 %>% rename(Lit_Source=Source)
c.all1 <- c.all1 %>% rename(Nanomat_Treatment=Nanomat_Treatment.x)
c.all1 <- c.all1 %>% rename(Zeta_Potential=Zeta_potential_mV)
c.all1 <- c.all1 %>% rename(Structure=Chemical_comp)

b.all2 <- b.all2 %>% rename(Structural_Form=Shape)
c.all1 <- c.all1 %>% rename(Structural_Form=Shape)

b.all2 <- b.all2 %>% rename(Route=ROE)
b.all2 <- b.all2 %>% rename(Scale=Size)


c.all1 <- c.all1 %>% select(-`T1 p-value`, -`T2 p-value`, -`T3 p-value`, -`T4 p-value`,
                            -AIC, -`BMD (mg)`, -`BMDL (mg)`, -Density_error, -Diameter_error_nm,
                            -Length_error_nm, -`Model Chosen`, -`Model Comments`, -Nanomat_Treatment.y)

b.all2 <- b.all2 %>% select(-Material_Label, -Material_Label.y, -Normalized.NOEL, - Normalized.LOEL,
                            -NMD_diff)


#qc1 <- b.all2 %>% select(Material_Label, Material_Label.x, Material_Label.y)
#rm(qc1)



#################################
### Combine all

# export and manually combine to try to get around arduously reformatting STR
#write.csv(a.all5, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\a_all.csv")
#write.csv(b.all2, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\b_all.csv")
#write.csv(c.all1, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\c_all.csv")

# Combined B and C First
# Then combined with A
# Filled in stuff manually where possible - probably more could be filled
# not the best way to do things

d1 <- read_excel(path="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_INPUT\\all_a_b_c.xlsx",
                 sheet=1)

                     
# Subset of indeces, BMDs, BMDLs                                  
bmd1 <- d1 %>% select(index, BMD, BMDL)

bmd2 <- filter(bmd1, BMD != "NA")

#write.csv(bmd2, file="Z:\\ENM Categories\\Framework Update 2019\\02_dataprep_OUTPUT\\all_pmn_BMDs.csv")



