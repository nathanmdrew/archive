library(dplyr)
library(readxl)

fpath <- "C:/Users/vom8/CDC/NIOSH-DSI-ETB - General/"
fname <- "ETB_Project_Tracker_2025-03-18.xlsx"
savepath <- "C:/Users/vom8/OneDrive - CDC/ETB/Project Tracker/"

# read in milestone tracker
wip1 <- read_excel(path=paste0(fpath, fname),sheet="Tracker WIP",col_name=T,
                   skip=3)

wip1$rownum <- seq(1:nrow(wip1))

# trim off gant chart, other columns
wip2 <- wip1[,c(1:12,62)]

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

# save outputs
write.csv(wip4, file=paste0(savepath, "wip", Sys.Date(), ".csv"), row.names=F)
saveRDS(wip4, file=paste0(savepath, "wip", Sys.Date(), ".RDS"))
