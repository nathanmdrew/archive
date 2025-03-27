utils::setRepositories(ind = 0, addURLs = c(CRAN = "https://cran.rstudio.com"))
library(dplyr)
library(readxl)
library(tidyr)

# Get doses for NTP studies
oeb <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/_FINAL_OEBs (120424).xlsx",
                  sheet="D-1 Micro")


# Inflammation

# has index, chem name, duration, species/strain, doses
infl1 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/NTP/_temp_summary.xlsx",
                    sheet="DAX")
infl2 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/NTP/_temp_summary.xlsx",
                    sheet="_temp_summary")
infl3 <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/NTP_infl_noael_loael.xlsx",
                    sheet="FINAL2")

doses1 <- infl2 %>% select(index, DOSE)
doses2 <- doses1 %>% pivot_wider(names_from=index, values_from=DOSE)
doses3 <- as.data.frame(t(doses2))
doses3$index <- seq(1:nrow(doses3))

keys <- infl2 %>% distinct(index, CHEMICAL_NAME, SPECIES_COMMON_NAME, STRAIN, sex2, DOSE_UNIT)
keys <- keys %>% filter(!is.na(DOSE_UNIT))

keys2 <- keys[-c(34,36,38,40,65,67),] #one duplicate in rows 87/88

doses4 <- left_join(keys2, doses3, by="index")
doses4$conc1 <- substr(doses4$V1, start=3, stop=nchar(doses4$V1)-1)
doses5 <- doses4 %>% select(-V1)

temp1 <- infl3 %>% select(index, Duration)

doses6 <- left_join(doses5, temp1, by="index")

write.csv(doses6, file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/ntp_infl_doses.csv")




##### Fibrosis
fib1 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/NTP/fibrosis_trendtest_fisherexact_results.xlsx",
                   sheet="_D8")
doses2 <- fib1 %>% select(index, DOSE) %>% pivot_wider(names_from=index, values_from=DOSE)
doses3 <- as.data.frame(t(doses2))
doses3$index <- seq(1:nrow(doses3))

fib2 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/NTP/fibrosis_study_length_by_index.xlsx",
                   sheet="Sheet1")
fib2 <- fib2 %>% select(index, `Study Length`)
doses4 <- left_join(doses3, fib2, by="index")
doses4$conc1 <- substr(doses4$V1, start=3, stop=nchar(doses4$V1)-1)
doses5 <- doses4 %>% select(-V1)

fib3 <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/fibrosis_noael_loael_20240812.xlsx",
                   sheet="FINAL3")
fib3 <- fib3 %>% select(SPECIES_COMMON_NAME, STRAIN, sex2, CHEMICAL_NAME, index)
doses6 <- left_join(doses5, fib3, by="index")

write.csv(doses6, file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/ntp_fib_doses.csv")





# Neoplasia
neo1 <- read_excel(path="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/NTP_lungneo_noael_loael.xlsx",
                           sheet="FINAL2")
neo3 <- neo1 %>% select(Species, Strain, Sex, Material, Index, Duration) %>% rename(index=Index)

neo2 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/+My_Documents/MyLargeWorkspace Backup/ENM Categories/NTP/_temp_summary_TUMOR.xlsx",
                   sheet="DAX")
doses2 <- neo2 %>% select(index, DOSE) %>% pivot_wider(names_from=index, values_from=DOSE)
doses3 <- as.data.frame(t(doses2))
doses3$index <- seq(1:nrow(doses3))

doses4 <- left_join(neo3, doses3, by="index")
doses4$conc1 <- substr(doses4$V1, start=3, stop=nchar(doses4$V1)-1)
doses5 <- doses4 %>% select(-V1)

write.csv(doses5, file="//cdc.gov/project/NIOSH_NanoBMD/OEB Updates 2023 (catOEL DB)/ntp_neo_doses.csv")


