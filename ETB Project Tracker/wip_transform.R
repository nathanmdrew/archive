library(dplyr)
library(readxl)
library(stringr)

fpath <- "C:/Users/vom8/CDC/NIOSH-DSI-ETB - General/"
fname <- "ETB_Project_Tracker_2025-03-18.xlsx"
savepath <- "C:/Users/vom8/OneDrive - CDC/ETB/Project Tracker/"

# read in milestone tracker
wip1 <- read_excel(path=paste0(fpath, fname),sheet="Tracker WIP",col_name=T,
                   skip=3)

wip1$rownum <- seq(1:nrow(wip1))

# trim off gant chart, other columns
wip2 <- wip1[,c(1:12,62)]

# fix names with special characters like new line, returns, etc.
# fix date formats
wip2 <- wip2 %>% rename(`ACTUAL DATE OF COMPLETION`=`ACTUAL \r\nDATE OF COMPLETION`,
                        `EXPECTED DATE OF COMPLETION`=`EXPECTED \r\nDATE OF COMPLETION`)
wip2$`START DATE` <- as.Date(wip2$`START DATE`)
wip2$`EXPECTED DATE OF COMPLETION` <- as.Date(wip2$`EXPECTED DATE OF COMPLETION`)
wip2$`ACTUAL DATE OF COMPLETION` <- as.Date(wip2$`ACTUAL DATE OF COMPLETION`)

# list of projects
projects <- wip2 %>% filter(is.na(Column1) & !is.na(`PROJECT MILESTONES`))

# find projects with no milestones
noMilestone <- vector(mode="numeric", length=nrow(projects))
for (kk in 2:nrow(projects)) {
  current_rownum <- projects[kk,13]
  previous_rownum <- projects[kk-1,13]
  
  if(previous_rownum+1 == current_rownum) noMilestone[kk-1]=previous_rownum
  
}
noMilestone <- unlist(noMilestone)

projects2 <- projects %>% filter(!(rownum %in% noMilestone))

# remove last row ("DO NOT USE ROW"), remove project name rows
wip3 <- wip2[1:nrow(wip2)-1,] %>% filter(!is.na(Column1))
wip3$`PROJECT NAME` <- "NAMEHERE"
wip3$`PROJECT OFFICER` <- "OFFICERHERE"

# add project names, project officer to corresponding milestone rows
jj <- 0 #initialize project row counter
for (ii in 1:nrow(wip3)) {
  
  if(wip3[ii,4]=="1") jj=jj+1
  
  wip3[ii,14] = projects2[jj,5]
  wip3[ii,15] = projects2[jj,7]
                          
}

qc <- wip3 %>% select(Column1, `PROJECT NAME`)

# bring it all together
projects$`PROJECT NAME` <- projects$`PROJECT MILESTONES`
projects$`PROJECT OFFICER` <- projects$ASSIGNEE
wip4 <- rbind(wip3, projects) %>% arrange(rownum)

# add some metric stuff
wip4$`EXPECTED WEEKS REMAINING` <- if_else(wip4$STATUS!="Completed",
                                           difftime(time1=wip4$`EXPECTED DATE OF COMPLETION`,
                                                    time2=Sys.Date(),
                                                    units="weeks"),
                                           NA)


wip4$`DURATION (# OF WEEKS)` <- if_else(is.na(wip4$`START DATE`), NA, wip4$`DURATION (# OF WEEKS)`)

reviewMilestones <- c("Branch Final review",
                      "DSI OD review",
                      "NIOSH OD review",
                      "Draft paper completed and submitted to branch review",
                      "NIOSH OD review  completed",
                      "Branch Review")

wip4$indReview <- if_else(wip4$`PROJECT MILESTONES` %in% reviewMilestones | wip4$STATUS %in% c("NIOSH OD Review", "DSI OD Review"), 1, 0)

wip4$`WEEKS ELAPSED` <- if_else(wip4$STATUS != "Completed",
                                difftime(time1=Sys.Date(),
                                         time2=wip4$`START DATE`,
                                         units="weeks"),
                                NA)

# save outputs
write.csv(wip4, file=paste0(savepath, "wip", Sys.Date(), ".csv"), row.names=F)
saveRDS(wip4, file=paste0(savepath, "wip", Sys.Date(), ".RDS"))




#################################################
### QC shit
#################################################

# this metric should probably be reported
qc <- wip4 %>% filter(STATUS=="Completed" & is.na(`ACTUAL DATE OF COMPLETION`))

# could measure time remaining, time overdue
qc <- wip4 %>% filter(STATUS=="DSI OD Review" & is.na(`ACTUAL DATE OF COMPLETION`) & !is.na(Column1))

qc <- wip4 %>% filter(STATUS=="NIOSH OD Review" & is.na(`ACTUAL DATE OF COMPLETION`) & !is.na(Column1))

# could also count # with no start date
qc <- wip4 %>% filter(STATUS=="In Progress" & is.na(`ACTUAL DATE OF COMPLETION`) & !is.na(Column1))

qc$`START DATE` <- as.Date(qc$`START DATE`)
str(qc$`START DATE`)

table(wip4$STATUS)

qc <- data.frame(milestone=unique(wip4$`PROJECT MILESTONES`))

str_view(string=qc$milestone, pattern="review")
str_view(string=qc$milestone, pattern="Review")


