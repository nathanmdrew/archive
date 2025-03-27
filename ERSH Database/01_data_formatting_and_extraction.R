# ERSH Database
# Example of reading the Abrin file and conforming values into the template

library(dplyr)
library(readxl)

# read in the template, original data file, and formatted data file
template1 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/ERSH Database/TEMPLATE.ERSH.DB.9.13.2024.xlsx",
                        sheet="Data",
                        col_names=TRUE)


abrin1 <- read_excel(path="C:/Users/vom8/OneDrive - CDC/ERSH Database/example_Abrin.xlsx",
                     sheet="Sheet1",
                     col_names=TRUE)

goal.Abrin <- read_excel(path="C:/Users/vom8/OneDrive - CDC/ERSH Database/Abrin.ERSH.DB.DATA.FORMATTED.9.4.24.xlsx",
                         sheet="data",
                         col_names=TRUE)

# some variables differ in type, TODO resolve
#str(abrin1)
#str(template1)
#str(goal.Abrin)


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

abrin1 <- abrin1 %>% rename(`display name`=`current content`,
                            grouping2=grouping,
                            grouping=field_id,
                            field_id=display_name)

#get the current agent
current_agent_name=unique(abrin1$agent)
if(length(current_agent_name) > 1) warning("This data file contains more than 1 agent.")
current_agent_id=unique(abrin1$agent_id)

#bring in Agent ID
template2 <- template1 %>% mutate(agent_id=as.numeric(agent_id)) %>% 
                           mutate(agent_id=current_agent_id)

template3 <- left_join(template2, abrin1, by="field_id")

template3 <- template3 %>% rename(content_rules=content,
                                  URL_rules=URL)

#output for inspection
write.csv(template3, 
          file="C:/Users/vom8/OneDrive - CDC/ERSH Database/template3.csv",
          row.names=F)

#check for column name consistency
qc <- template3 %>% filter(`display name.x` != `display name.y`)
qc <- template3 %>% filter(`grouping.x` != `grouping.y`) %>% 
                    select(field_id, grouping.x, grouping.y)
                    #7 differences; keep grouping.x 

# let content come from recommendation 1, url from recommendation 2
template4 <- template3
template4$content <- template4$`ATL Recommendation 1`
template4$URL <- template4$`ATL Recommendation 2`

names(template4)

QCtemplate <- template4 %>% select(data_id, field, field_id, `display name.x`,
                                   grouping.x, display_order, content, 
                                   agent_id.y, ref_id, URL, `fname (doc name)`,
                                   org)
#output for inspection
write.csv(QCtemplate, 
          file="C:/Users/vom8/OneDrive - CDC/ERSH Database/QCtemplate.csv",
          row.names=F)

###### notes on how the original data file compares to the template
# EXAMPLE display_name = TEMPLATE field_id
# EXAMPLE current content = TEMPLATE display name
# EXAMPLE field_id = TEMPLATE grouping
# EXAMPLE agent_id = TEMPLATE agent_id
# EXAMPLE ATL Recommendation 1 = TEMPLATE content
# EXAMPLE URL_1 = TEMPLATE URL

###### URLs
#nih.gov -> NIH
#doi.org -> TOCHECK, could be CDC
#epa.gov -> EPA
#osha.gov -> OSHA
#nist.gov -> OSHA
#energy.gov -> EDMS
#dot.gov -> DOT
#ojp.gov -> DOJ
#no url -> NO REFERENCE
#any other web address -> !MANUAL CHECK!

#output columns
# [1] "data\r\n_id"         "field"               "field\r\n_id"        "display name"       
# [5] "grouping"            "display\r\n_order"   "content"             "agent_id"           
# [9] "ref_id"              "URL"                 "fname\r\n(doc name)" "org"  

# [1] not used?             from template         from template         from template
# [5] from template         from template         from DATAFILE         from DATAFILE
# [9] not used?             FROM DATAFILE         not used?             from DATAFILE


##########################
##########################
# qc
names(template1) #some names have unicode characters
names(goal.Abrin) #some names have unicode characters
names(abrin1) #names look okay, 7 are nameless and are given ...## names

temp1 <- select(template1, `field\r\n_id`) %>% rename(field_id=`field\r\n_id`)
temp2 <- select(goal.Abrin, `field\r\n_id`) %>% rename(field_id=`field\r\n_id`)
temp3 <- merge(temp1, temp2, by="field_id") #field 79 duplicated 3 times in template
