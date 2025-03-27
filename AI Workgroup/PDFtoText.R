# Install and load the fs package
library(fs)
library(pdftools)
library(tesseract)

setwd('C:/Users/oph6/OneDrive - CDC/DSI-ETB/AI and public comments/PDF reader test')

# Define the directory path where attachments are downloaded
directory_path <- "C:/Users/oph6/OneDrive - CDC/DSI-ETB/AI and public comments/PDF reader test"

# List all files with a specific extension, e.g., ".txt"
pdf_files <- dir_ls(directory_path, regexp = "\\.pdf$")

subset_dat$Attachment.Text <- NA
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

subset_dat$Comment_with_Attachment <- paste(subset_dat$Comment, subset_dat$Attachment.Text, sep = " PDF Text:")


