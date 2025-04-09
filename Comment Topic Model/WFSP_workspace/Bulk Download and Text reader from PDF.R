library('xlsx')
library('readr')
library('curl')
library('stringr')

setwd('insert working directory filepath here')

subset_dat <- read.csv('test_comments_200rows.csv', header = TRUE)

## file path of the directory to download all attachments to
dest_dir <- 'insert filepath for location of downloaded files here'

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


##########################################################################################################
##########################################################################################################

## portion to individually convert each PDF in directory to text & append to full data frame of comments

library(fs)
library(pdftools)
library(tesseract)

# Define the directory path where attachments are downloaded
directory_path <- "filepath where PDFs are located"

# List all files with a specific extension, e.g., ".txt"
pdf_files <- dir_ls(directory_path, regexp = "\\.pdf$")

subset_dat$Attachment.Text <- NA ## creating blank variable to insert PDF text
### read in each PDF as text and append to subset_dat data frame
for(i in c(1:length(pdf_files))){
  pdfname <- pdf_files[i]
  
  asOCR  <- pdftools::pdf_ocr_text(pdfname)
  
  ## combines into single string if PDF has multiple pages
  asOCR <- paste0(asOCR, collapse = " ")
  
  ## replace new line characters with string
  asOCR.2 <- gsub("\n", " ", asOCR)
  
  ## Volha's preprocessing
  asOCR.3 <- tolower(asOCR.2)
  
  asOCR.3 <- gsub('(f|ht)tp\\S+\\s*', " ", asOCR.3)
  
  asOCR.3 <- gsub("[[:punct:]]", " ", asOCR.3)
  
  asOCR.3 <- gsub("`", " ", asOCR.3)
  
  asOCR.3 <- gsub("'", " ", asOCR.3)
  
  asOCR.3 <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", asOCR.3, perl = TRUE)
  
  ### getting commentID to match to Document ID variable in full CSV
  pdfname_split <- str_split(pdfname, pattern = "/")
  fileName <- pdfname_split[[1]][length(pdfname_split[[1]])]
  commentID <- str_split(fileName, pattern = "_")[[1]][1]
  
  subset_dat$Attachment.Text[which(commentID == subset_dat$Document.ID)] <- asOCR.3
}

## creating combined variable with comment + any text from PDF attachment(s) with " PDF Text:" in between
subset_dat$Comment_with_Attachment <- paste(subset_dat$Comment, subset_dat$Attachment.Text, sep = " PDF Text:")
