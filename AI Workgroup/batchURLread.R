library('xlsx')
library('readr')
library('curl')
library('stringr')

setwd('C:/Users/oph6/OneDrive - CDC/DSI-ETB/AI and public comments/PDF reader test')

subset_dat <- read.csv('test_comments_200rows.csv', header = TRUE)

## file path of the directory to download all attachments to
dest_dir <- 'C:/Users/oph6/OneDrive - CDC/DSI-ETB/AI and public comments/PDF reader test/'

for(i in c(1:length(subset_dat$Attachment.Files))){
  if(nchar(subset_dat$Attachment.Files[i]) > 0){
    url_str <- subset_dat$Attachment.Files[i] ## entire URL string from Attachment.Files variable
    url_split <- str_split(url_str, pattern = ",") ## makes a list containing each URL in a separate string
    for(j in c(1:length(url_split[[1]]))){ ## downloading each URL
      url <- url_split[[1]][j]
      filename_split <- str_split(url, pattern = "/")
      filename <- paste0(filename_split[[1]][4],sep = "_",filename_split[[1]][5]) ## creating file name from comment ID & attachment number (e.g. CDC-2023-0051-0054_attachment_1)
      file <- paste0(dest_dir,filename)
      curl_download(url,file)
    }
  }
  
}

###################################################################################