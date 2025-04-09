# Databricks notebook source
# csv from Regulations.gov
subset_dat <- read.csv("/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_original_comments.csv", header = TRUE)

## file path of the directory to download all attachments to
dest_dir <- "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_attachments/"


# COMMAND ----------

require('xlsx')
require('readr')
require('curl')
require('stringr')

# COMMAND ----------

# download all PDFs from the Regulations.gov bulk download csv (subset_dat) into the destination
# directory (dest_dir)

for(i in c(1:length(subset_dat$Attachment.Files)))
{
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

# COMMAND ----------

# List all files with a specific extension, e.g., ".txt"
dir_ls(dest_dir, regexp = "\\.pdf$")
