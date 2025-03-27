library(readxl)
library(dplyr)
#library(ggplot2)

pathin <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/02_output/"

d <- read_excel(path=paste0(pathin,"data4_and_clusters_and_pchem.xlsx"),
                sheet=2,
                col_names=T)

#str(d)

#restructure

d$Diameter <- as.numeric(d$Diameter)
d$Post.Exp <- as.numeric(d$Post.Exp)
d$PP_size_nm <- as.numeric(d$PP_size_nm)
d$PP_size_nm_rev <- as.numeric(d$PP_size_nm_rev)

d$material <- as.factor(d$material)
d$Material_Category <- as.factor(d$Material_Category)
d$Scale <- as.factor(d$Scale)
d$Scale_rev <- as.factor(d$Scale_rev)
d$Agglomerated_ <- as.factor(d$Agglomerated_)
d$Structural_Form <- as.factor(d$Structural_Form)
d$Structural_Form_rev <- as.factor(d$Structural_Form_rev)
d$Crystal_Structure_ <- as.factor(d$Crystal_Structure_)
d$Crystal_Structure_rev <- as.factor(d$Crystal_Structure_rev)
d$Crystal_Type <- as.factor(d$Crystal_Type)
d$Crystal_Type_rev <- as.factor(d$Crystal_Type_rev)
d$Solubility <- as.factor(d$Solubility)
d$Modification <- as.factor(d$Modification)
d$Purification_Type <- as.factor(d$Purification_Type)
d$Functionalized_Type <- as.factor(d$Functionalized_Type)
d$Contaminants_ <- as.factor(d$Contaminants_)
d$Contaminant_Type <- as.factor(d$Contaminant_Type)
d$Route <- as.factor(d$Route)
d$study_key <- as.factor(d$study_key)
d$Lit_Source <- as.factor(d$Lit_Source)
d$indi_exclude <- as.factor(d$indi_exclude)
d$k4 <- as.factor(d$k4)
d$k5 <- as.factor(d$k5)
d$k6 <- as.factor(d$k6)
d$k7 <- as.factor(d$k7)
d$k8 <- as.factor(d$k8)
d$k9 <- as.factor(d$k9)
d$k10 <- as.factor(d$k10)

# new vars or changes
d$Shape <- case_when(
  d$Structural_Form_rev %in% c("flake", "nanoplates") ~ "Plate-like",
  d$Structural_Form_rev %in% c("Nanobelt", "Nanofiber", "Nanorod", "Nanotube", "Needle", "Spindle") ~ "Fiber-like",
  d$Structural_Form_rev %in% c("Microparticle", "Nanoparticles", "Particle", "Spherical Particle", "ultrafine particle") ~ "Spherical",
  d$Structural_Form_rev=="irregular" ~ "Irregular" #possibly "Centered"? publication says Irregular
  )

d$Shape <- as.factor(d$Shape)

d$Scale_rev[d$Scale_rev=="Micron"] <- "Micro"
d$Diameter[is.na(d$Diameter)] <- -99
d$Median_Aerodynamic_Diameter[d$Median_Aerodynamic_Diameter==800] <- 800/1000  #variable units are um, but this was recorded in nm

d$kOOM <- case_when(
  d$BMDL < 0.01 ~ "< 0.01 ug/g lung",
  d$BMDL < 0.1 ~ "0.01 - 0.1 ug/g lung",
  d$BMDL < 1.0 ~ "0.1 - 1.0 ug/g lung",
  d$BMDL < 10 ~ "1 - 10 ug/g lung",
  d$BMDL < 100 ~ "10 - 100 ug/g lung",
  d$BMDL < 1000 ~ "100 - 1000 ug/g lung",
  d$BMDL < 10000 ~ "1000 - 10000 ug/g lung"
)
d$kOOM <- as.factor(d$kOOM)
#table(d$kOOM)


# to drop later:
# Surface_reactivity (all missing), Surface_modifications (all but 1 missing)

#material, struct form, diameter, sa, pp size, crystal type, length, zeta, density,
#crystal struct, material category, scale, impurity indicator, solubility, mmad,
# agglom ind, funct type, modificaiton, impurity amount, purification type, surface charge

s <- d %>% group_by(material) %>% summarize(tally=n())
s

s <- d %>% group_by(Material_Category) %>% summarize(tally=n())
s

s <- d %>% group_by(material, Material_Category) %>% summarize(tally=n())
s

s <- d %>% group_by(Structural_Form_rev) %>% summarize(tally=n())
s

s <- d %>% group_by(Shape) %>% summarize(tally=n())
s
#qc <- d %>% filter(is.na(Shape))

s <- d %>% group_by(material, Material_Category, Structural_Form_rev) %>% summarize(tally=n())
print(s, n=nrow(s))

s <- d %>% group_by(material, Material_Category, Structural_Form_rev, Shape) %>% summarize(tally=n())
print(s, n=nrow(s))


s <- d %>% group_by(material, Material_Category, Scale_rev) %>% summarize(tally=n())
print(s, n=nrow(s))

s <- d %>% group_by(material, Material_Category, Scale_rev, Structural_Form_rev) %>% summarize(tally=n())
print(s, n=nrow(s))

s <- d %>% group_by(material, Material_Category, Crystal_Structure_rev, Crystal_Type_rev) %>% summarize(tally=n())
print(s, n=nrow(s))

#t <- filter(d, material=="Silica")
#names(d)




s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Diameter),
                                                               med=median(Diameter),
                                                               maximum=max(Diameter),
                                                               tally=n())
s
#qc <- d %>% filter(material=="ZnO")

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Surface_Area),
                                                               med=median(Surface_Area),
                                                               maximum=max(Surface_Area),
                                                               tally=n())
s

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(PP_size_nm_rev),
                                                               med=median(PP_size_nm_rev),
                                                               maximum=max(PP_size_nm_rev),
                                                               tally=n())
s

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Length_rev),
                                                               med=median(Length_rev),
                                                               maximum=max(Length_rev),
                                                               tally=n())
s

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Density),
                                                               med=median(Density),
                                                               maximum=max(Density),
                                                               tally=n())
s

# Anderson is a graphite dust, so -99 for Length is appropriate
#qc <- d %>% filter(material=="Graphene")

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Zeta_Potential),
                                                               med=median(Zeta_Potential),
                                                               maximum=max(Zeta_Potential),
                                                               tally=n())
s

s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Median_Aerodynamic_Diameter),
                                                               med=median(Median_Aerodynamic_Diameter),
                                                               maximum=max(Median_Aerodynamic_Diameter),
                                                               tally=n())
s
#qc <- d %>% filter(material=="TiO2" & Median_Aerodynamic_Diameter>100)

s <- d %>% filter(Route %in% c("Inh", "inhalation", "Inhalation", "nose only inhalation", "whole body inhalation")) %>%
  group_by(material, Material_Category) %>% 
  summarize(minimum=min(Median_Aerodynamic_Diameter),
                                                               med=median(Median_Aerodynamic_Diameter),
                                                               maximum=max(Median_Aerodynamic_Diameter),
                                                               tally=n())
s


s <- d %>% group_by(material, Material_Category) %>% summarize(minimum=min(Surface_Charge),
                                                               med=median(Surface_Charge),
                                                               maximum=max(Surface_Charge),
                                                               tally=n())
s
table(d$Surface_Charge) #2 values

table(d$Diameter)

table(d$Structure)
table(d$Surface_reactivity)
table(d$Surface_modifications)
table(d$Route)

saveRDS(d, file=paste0(pathout,"full_data.RDS"))

names(d)

#remove earlier variable versions, unused variables
d_trim <- d %>% select(-Scale, -Structural_Form, -Crystal_Structure_, -Crystal_Type,
                       -Length, -Surface_Charge, -Surface_reactivity, -Surface_modifications,
                       -PP_size_nm, -cluster.Complete, -cluster.Ward, -cluster.OOM,
                       -rand)

saveRDS(d_trim, file=paste0(pathout,"trimmed_data.RDS"))

write.csv(d_trim, file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2024/data4_and_clusters_and_pchem_trimmed.csv")
