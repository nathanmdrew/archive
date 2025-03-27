library(dplyr)


d1 <- read.csv(file="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/DB/skeleton_and_physiochemical_16may2016.csv",
               header=T)


n <- as.data.frame(x=names(d1))
# columns >= 32 are pchem

d2 <- d1[,1:31]

s1 <- d2 %>% group_by(study_key, StudyRef, material, material_type, Species, Strain, Gender, exp_d, 
                      PE_d, administered_dose, dose_unit, dep_dose_amount2, dep_dose_unit2) %>%
      summarize(mean_pmn = mean(SampPMNPer),
                sd_pmn   = sd(SampPMNPer),
                n_pmn    = n())


s2 <- s1 %>% filter(PE_d < 4)
# should end up with 32 associations as in 2017 paper

# copy and relabel controls 
controls <- s2 %>% ungroup %>%
  filter(material_type %in% c("control","control1","control2","control3","control4","control5","control6","control7","control8","controlColloid1", "controlIonized1"))





############################################################
#############   QC Stuff 
############################################################

qc <- s2 %>% ungroup %>% 
  distinct(study_key, material, material_type, PE_d) %>% 
  filter(!material_type %in% c("control","control1","control2","control3","control4","control5","control6","control7","control8","controlColloid1", "controlIonized1"))
#cool

#one Xia "control" that is not control
qc <- d2 %>% filter(material_type=="control" & administered_dose>0)
# some at other doses/post exposures

qc2 <- d2 %>% filter(StudyRef=="Xia2011") %>% distinct(material, material_type, administered_dose)
#easy route - probably not resolvable, just omit
#original data are the same way