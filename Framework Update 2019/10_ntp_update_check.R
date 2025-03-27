library(dplyr)

# Dated 10/29/2019
h1 <- read.delim(file="C:\\Users\\vom8\\Downloads\\HISTOPATHOLOGY_NTP\\HISTOPATHOLOGY_NTP\\HISTOPATHOLOGY_NTP.txt", header=T)

# Believe this is dated 3/15/2018
o1 <- readRDS(file="C:\\Users\\vom8\\Desktop\\WFH\\NTP\\histopathology.rds")

oldkey <- o1 %>% distinct(ACCESSION_NUMBER)
newkey <- h1 %>% distinct(ACCESSION_NUMBER)

str(oldkey)
str(newkey)

oldkey$ind_old <- rep(1, nrow(oldkey))
newkey$ind_new <- rep(1, nrow(newkey))

keys <- left_join(newkey, oldkey)

summary(keys)

keys[is.na(keys$oldkey)] <- 0

#new not old
new.notold <- keys %>% filter(is.na(ind_old))

newstudies <- select(new.notold, ACCESSION_NUMBER)

new1 <- merge(h1, newstudies)
#qc <- new1 %>% distinct(ACCESSION_NUMBER)

chems <- new1 %>% distinct(ACCESSION_NUMBER, CHEMICAL_NAME, CAS_NUMBER)
chems2 <- filter(chems, CAS_NUMBER != "None")

#most seem to be liquids or pharma
# hematite and sulfolane are at least solids

new2 <- new1 %>% filter(ACCESSION_NUMBER %in% c("002-01578-0002-0000-5","002-03276-0004-0000-4",
                                                "002-03276-0005-0000-5","002-03276-0006-0000-6"))

new3 <- new2 %>% filter(ORGAN=="Lung")
#only hematite, only 1 infl.