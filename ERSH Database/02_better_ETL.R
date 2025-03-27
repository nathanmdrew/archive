# ERSH Database
# Example of reading the Abrin file and conforming values into the template

library(dplyr)
library(readxl)

fpath <- "C:/Users/vom8/OneDrive - CDC/ERSH Database/"

# read in the template, original data file, and formatted data file
template1 <- read_excel(path=paste0(fpath, "TEMPLATE.ERSH.DB.9.13.2024.xlsx"),
                        sheet="Data",
                        col_names=TRUE)


abrin1 <- read_excel(path=paste0(fpath, "WORKING.ALL.AGENTS.ERSH.DB.DATA.LIST.SEPT.2024.xlsx"),
                     sheet="Formatted chemicals",
                     col_names=TRUE)

abrin2 <- abrin1 %>% filter(agent=="ABRIN")

goal.Abrin <- read_excel(path=paste0(fpath, "Abrin.ERSH.DB.DATA.FORMATTED.9.4.24.xlsx"),
                         sheet="data",
                         col_names=TRUE)

template1 <- template1 %>% rename(field_id=`field\r\n_id`,
                                  data_id=`data\r\n_id`,
                                  display_order=`display\r\n_order`,
                                  `fname (doc name)`=`fname\r\n(doc name)`,
                                  note1=...13,
                                  note2=...14,
                                  note3=...15)

# some template fixes as seen in goal.Abrin
template1[3,5] <- "Trade Names"
template1[4,5] <- "Agent"

abrin2 <- abrin2 %>% rename(`display name`=`current content`,
                            grouping2=grouping,
                            grouping=field_id,
                            field_id=display_name)

#get the current agent
current_agent_name=unique(abrin2$agent)
if(length(current_agent_name) > 1) warning("This data file contains more than 1 agent.")
current_agent_id=unique(abrin2$agent_id)

#str(abrin2)
#str(template1)
#str(goal.Abrin)

#bring in Agent ID
template2 <- template1 %>% mutate(agent_id=as.numeric(agent_id)) %>% 
  mutate(agent_id=current_agent_id)

template3 <- left_join(template2, abrin2, by="field_id")

template3 <- template3 %>% rename(content_rules=content,
                                  URL_rules=URL)

# let content come from recommendation 1, url from recommendation 2
template4 <- template3
template4$content <- if_else(template4$`ATL Recommendation 1`=="*This grouping was missing in the original ERSH-DB received from NIOSH.",
                             template4$URL_1,
                             template4$`ATL Recommendation 1`)
template4$URL <- template4$`ATL Recommendation 2`

QCtemplate <- template4 %>% select(data_id, field, field_id, `display name.x`,
                                   grouping.x, display_order, content, 
                                   agent_id.x, ref_id, URL, `fname (doc name)`,
                                   org)
#output for inspection
write.csv(QCtemplate, 
          file="C:/Users/vom8/OneDrive - CDC/ERSH Database/QCtemplate.csv",
          row.names=F)

qc <- filter(template4, display_order==60)
