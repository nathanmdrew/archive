library(dplyr)
library(readxl)

#f rat - nano
d1 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040701_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d1.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040701_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                     sheet=1, 
                     range="A6:B13")

d1$Sex <-            rep(d1.doe[6,2], nrow(d1))
d1$Route <-          rep(d1.doe[4,2], nrow(d1))
d1$Material <-       rep(d1.doe[1,2], nrow(d1))
d1$CASRN <-          rep(d1.doe[2,2], nrow(d1))
d1$Study <-          rep(2040701, nrow(d1))
d1$Strain_Species <- rep(d1.doe[7,2], nrow(d1))

d1.lung <- filter(d1, Organ=="Lung")


#m rat - nano
d2 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040701_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d2.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040701_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d2$Sex <-      rep(d2.doe[6,2], nrow(d2))
d2$Route <-    rep(d2.doe[4,2], nrow(d2))
d2$Material <- rep(d2.doe[1,2], nrow(d2))
d2$CASRN <-    rep(d2.doe[2,2], nrow(d2))
d2$Study <-    rep(2040701, nrow(d2))
d2$Strain_Species <- rep(d2.doe[7,2], nrow(d2))


d2.lung <- filter(d2, Organ=="Lung")



#f mouse - nano
d3 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040702_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d3.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040702_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d3$Sex <-      rep(d3.doe[6,2], nrow(d3))
d3$Route <-    rep(d3.doe[4,2], nrow(d3))
d3$Material <- rep(d3.doe[1,2], nrow(d3))
d3$CASRN <-    rep(d3.doe[2,2], nrow(d3))
d3$Study <-    rep(2040702, nrow(d3))
d3$Strain_Species <- rep(d3.doe[7,2], nrow(d3))


d3.lung <- filter(d3, Organ=="Lung")



#m mouse - nano
d4 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040702_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d4.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2040702_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d4$Sex <-      rep(d4.doe[6,2], nrow(d4))
d4$Route <-    rep(d4.doe[4,2], nrow(d4))
d4$Material <- rep(d4.doe[1,2], nrow(d4))
d4$CASRN <-    rep(d4.doe[2,2], nrow(d4))
d4$Study <-    rep(2040702, nrow(d4))
d4$Strain_Species <- rep(d4.doe[7,2], nrow(d4))


d4.lung <- filter(d4, Organ=="Lung")


#f rat - micro
d5 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070101_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d5.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070101_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d5$Sex <-      rep(d5.doe[6,2], nrow(d5))
d5$Route <-    rep(d5.doe[4,2], nrow(d5))
d5$Material <- rep(d5.doe[1,2], nrow(d5))
d5$CASRN <-    rep(d5.doe[2,2], nrow(d5))
d5$Study <-    rep(2070101, nrow(d5))
d5$Strain_Species <- rep(d5.doe[7,2], nrow(d5))


d5.lung <- filter(d5, Organ=="Lung")


#m rat - micro
d6 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070101_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d6.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070101_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d6$Sex <-      rep(d6.doe[6,2], nrow(d6))
d6$Route <-    rep(d6.doe[4,2], nrow(d6))
d6$Material <- rep(d6.doe[1,2], nrow(d6))
d6$CASRN <-    rep(d6.doe[2,2], nrow(d6))
d6$Study <-    rep(2070101, nrow(d6))
d6$Strain_Species <- rep(d6.doe[7,2], nrow(d6))


d6.lung <- filter(d6, Organ=="Lung")


#f mouse - micro
d7 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070102_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d7.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070102_Female_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d7$Sex <-      rep(d7.doe[6,2], nrow(d7))
d7$Route <-    rep(d7.doe[4,2], nrow(d7))
d7$Material <- rep(d7.doe[1,2], nrow(d7))
d7$CASRN <-    rep(d7.doe[2,2], nrow(d7))
d7$Study <-    rep(2070102, nrow(d7))
d7$Strain_Species <- rep(d7.doe[7,2], nrow(d7))


d7.lung <- filter(d7, Organ=="Lung")


#m mouse - micro
d8 <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070102_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx", 
                 sheet=1, 
                 skip=15)

d8.doe <- read_excel(path="\\\\cdc.gov\\project\\NIOSH_NanoBMD\\_DATA\\NTP\\Fullerene\\2070102_Male_Individual_Animal_Non_Neoplastic_Pathology_Data.xlsx",
                     sheet=1,
                     range="A6:B13")

d8$Sex <-      rep(d8.doe[6,2], nrow(d8))
d8$Route <-    rep(d8.doe[4,2], nrow(d8))
d8$Material <- rep(d8.doe[1,2], nrow(d8))
d8$CASRN <-    rep(d8.doe[2,2], nrow(d8))
d8$Study <-    rep(2070102, nrow(d8))
d8$Strain_Species <- rep(d8.doe[7,2], nrow(d8))


d8.lung <- filter(d8, Organ=="Lung")

all.lung <- bind_rows(list(d1.lung, d2.lung, d3.lung, d4.lung, d5.lung, d6.lung, d7.lung, d8.lung))

summ.lesion <- as.data.frame(summary(as.factor(all.lung$`Lesion Name`)))

infl <- filter(all.lung, `Lesion Name`=="Inflammation")

#unique keys
all <- bind_rows(list(d1, d2, d3, d4, d5, d6, d7, d8))
keys <- all %>% distinct(Material, Sex, Strain_Species)
keys$index <- seq(1:nrow(keys))

all2 <- merge(all, keys)

all2.lunginfl <- filter(all2, Organ=="Lung", `Lesion Name`=="Inflammation")

total.infl <- all2.lunginfl %>% 
  group_by(index, `Treatment Group`) %>% 
  summarize(obs = n())

#out1 <- all2 %>% filter(Organ=="Lung") %>% distinct(index, `Treatment Group`, `Number Examined`)
out1 <- all2 %>% distinct(index, Organ, `Treatment Group`, `Number Examined`)
temp <- filter(out1, Organ=="Lung")

out2 <- left_join(out1, total.infl)
out2$obs[is.na(out2$obs)] <- 0
out2$`Concentration Group` <- if_else(out2$`Treatment Group`=="Vehicle Control", 
                                      "0.0 mg/m3", 
                                      out2$`Treatment Group`)

out2$`Concentration Unit` <- substr(out2$`Concentration Group`, 
                                    nchar(out2$`Concentration Group`)-5, 
                                    nchar(out2$`Concentration Group`))
out2$Concentration <- as.numeric(substr(out2$`Concentration Group`, 
                                        1, 
                                        nchar(out2$`Concentration Group`)-6))

out3 <- arrange(out2, index, Concentration)
out3 <- left_join(out3, keys)

# looks okay but there are issues
# (1) male rat (micro)     {index 6} -> only 9 animals in the 15 mg/m3 group on the web summary
# (2) female mouse (micro) {index 7} -> missing 2 mg/m3 group
# (3) male mouse (micro)   {index 8} -> missing control group

##################################
###   QC Stuff


#Any duplicate animals?
qc <- unique(infl$`Animal Number`)
nrow(qc) == nrow(infl) #returns 0 -> dupes.
                       #oh boy - same animal number, different species
# example: 1408
str(all.lung$`Animal Number`)
qc2 <- filter(all.lung, `Animal Number`==1408)
# weird - nearly everything is the same (diagnoses, cage, days on study (most animals are 89, though))
#summary(all.lung$`Days on Study`)
# Conclusion: animal number is not a unique ID.  Use animal#+species at least

# OUT1 has oddities
# e.g. index5, treatment 2mg/m3 reports 1 and 10 examined.
qc <- filter(all2, index==5, `Treatment Group`=="2 mg/m3")
# different organ system

# investigate (1)
qc <- summary(as.factor(all2$`Removal Reason`))
qc #8 moribund, all others terminal

qc <- all2 %>% filter(index==6) %>% distinct(`Removal Reason`)
qc #hmm, no moribund
# survival table shows all 10 surviving... not sure where the web summary is coming from
# ill stick with this summary rather than use the web summary 


# investigate (2)
qc <- all2 %>% filter(index==7) %>% distinct(`Treatment Group`)
qc #all 4 are here - must be missing when filtered down to Lung

qc <- all2 %>% filter(index==7, Organ=="Lung") %>% distinct(`Treatment Group`)
qc #yep, 2mg/m3 missing here
# should have 0/10 inflammed.  control group also has 0/10, but isn't missing - not an artifact of 0 response

qc <- all2 %>% filter(index==7, Organ=="Lung")
# so the control group did have a response of Hemorrhage
# change the OUT1 creation to not require Lung


