# oebs 2023
# 
# oebs were already calculated in most of these spreadsheets
# recalculate and combine results for summary
#
# Adjustments
#    Duration < 28d = do not use
#    Duration 28-89 days = / 3
#    Duration 90+ = no adjustmetn
#
#    LOAEL only = / 10
#
#    Units must be in ug/m3



library(dplyr)
library(readxl)

pathin  <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/02_raw_data"
pathout <- "C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/Framework Update 2023/02_output"

files <- dir(path=pathin)
files

#read in Excel files
d1.1 <- read_excel(path=paste0(pathin, "/NanoSilver PoDs.xlsx"),
                   sheet=1)
d2.1 <- read_excel(path=paste0(pathin, "/Additional OEB Data.xlsx"),
                   sheet=1)

################# NanoSilver
# Divide by 3 if duration is between 28-89 days
# The one instance of NA is a combined 12w/90d dataset, so "worst case" is assumed
d1.1$duration_adjustment <- case_when(d1.1$Duration=="90d" ~ 1,
                                      d1.1$Duration=="12w" ~ 3,
                                      is.na(d1.1$Duration) ~ 3
)

d1.1$adjusted_NOAEL <- d1.1$NOAEL / d1.1$duration_adjustment
d1.1$adjusted_LOAEL <- d1.1$LOAEL / 10 / d1.1$duration_adjustment
d1.1$adjusted_BMDL <- d1.1$BMDL / d1.1$duration_adjustment

d1.1$OEB_NOAEL <- case_when(d1.1$unit=="ng/g" ~ "No band",
                            is.na(d1.1$adjusted_NOAEL) ~ "No band",
                            d1.1$adjusted_NOAEL == Inf ~ "No band",
                            d1.1$adjusted_NOAEL > 30000 ~ "band A",
                            d1.1$adjusted_NOAEL > 3000  ~ "band B",
                            d1.1$adjusted_NOAEL > 300   ~ "band C",
                            d1.1$adjusted_NOAEL > 30    ~ "band D",
                            d1.1$adjusted_NOAEL <= 30    ~ "band E")

d1.1$OEB_LOAEL <- case_when(d1.1$unit=="ng/g" ~ "No band",
                            is.na(d1.1$adjusted_LOAEL) ~ "No band",
                            d1.1$adjusted_LOAEL == Inf ~ "No band",
                            d1.1$adjusted_LOAEL > 30000 ~ "band A",
                            d1.1$adjusted_LOAEL > 3000  ~ "band B",
                            d1.1$adjusted_LOAEL > 300   ~ "band C",
                            d1.1$adjusted_LOAEL > 30    ~ "band D",
                            d1.1$adjusted_LOAEL <= 30    ~ "band E")

d1.1$OEB_BMDL <- case_when(d1.1$unit=="ng/g" ~ "No band",
                            is.na(d1.1$adjusted_BMDL) ~ "No band",
                           d1.1$adjusted_BMDL == Inf ~ "No band",
                            d1.1$adjusted_BMDL > 30000 ~ "band A",
                            d1.1$adjusted_BMDL > 3000  ~ "band B",
                            d1.1$adjusted_BMDL > 300   ~ "band C",
                            d1.1$adjusted_BMDL > 30    ~ "band D",
                            d1.1$adjusted_BMDL <= 30    ~ "band E")


####################### Additional OEB Data

d2.1$rownum <- seq(from=1, to=nrow(d2.1), by=1)

#check inhalation exposure regimen
d2.1.durations <- d2.1 %>% distinct(Exp_duration_hr, Exp_duration_d, Exp_duration_wk) #all 6 hr

d2.1.durations <- d2.1 %>% distinct(Exp_duration_d, Exp_duration_wk) 
d2.1.durations$num_days <- d2.1.durations$Exp_duration_d * d2.1.durations$Exp_duration_wk

d2.1.durations$duration_adjustment <- case_when(d2.1.durations$num_days<28 ~ 0,
                                                d2.1.durations$num_days<90 ~ 3,
                                                d2.1.durations$num_days>=90 ~ 1)

d2.2 <- merge(d2.1, d2.1.durations)
d2.2 <- arrange(d2.2, rownum)

d2.2$PE_Duration_unit[is.na(d2.2$PE_Duration_unit)] <- "days"


# deal with the odd structure
# first 2 studies have a different NOAEL/LOAEL identification structure
names(d2.2)

d2.2$NOAEL[d2.2$Study_ID!=253 | d2.2$Study_ID!=31118618] <- if_else(d2.2$Exp_conc_mean!=0 & d2.2$NOEL.LOEL_label=="NOEL", 
                                                                    d2.2$Exp_conc_mean, 
                                                                    -99)

d2.2$LOAEL[d2.2$Study_ID!=253 | d2.2$Study_ID!=31118618] <- if_else(d2.2$Exp_conc_mean!=0 & d2.2$NOEL.LOEL_label=="LOEL", 
                                                                    d2.2$Exp_conc_mean, 
                                                                    -99)
d2.2$NOAEL[d2.2$Study_ID==253] <- -99
d2.2$LOAEL[d2.2$Study_ID==253] <- 2

d2.2$NOAEL[d2.2$Study_ID==31118618] <- -99
d2.2$LOAEL[d2.2$Study_ID==31118618] <- 30


temp <- d2.2[d2.2$Study_ID==253, ]

temp2 <- d2.2 %>%
         group_by(Source, Study_ID, Author_Year, Material_Treatment, Species, Sex, ROE, 
                  Exp_conc_units, PE_duration_d, PE_Duration_unit, Endpoint, Organ,
                  num_days, duration_adjustment, Exp_duration_hr, Exp_duration_d, Exp_duration_wk) %>%
         summarize(maxNOEL=max(NOAEL),
                   maxLOEL=max(LOAEL))

qc <- temp2 %>% filter(maxNOEL > maxLOEL & maxLOEL != -99)


################### QC Fixes

#missing PE duration units in d2.2
unique(d2.2$PE_Duration_unit) #months, days, or weeks
qc <- d2.2 %>% filter(is.na(PE_Duration_unit))

#any multi-species/sex/material studies in d2.2?
qc <- d2.2 %>% distinct(Study_ID, Material_Treatment, Species, Sex)
#yes, multi-material
#some muti-species, some multi-sex, none with multi-species&sex



