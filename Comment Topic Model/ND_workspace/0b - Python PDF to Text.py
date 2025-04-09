# Databricks notebook source
# MAGIC %pip install PyPDF2

# COMMAND ----------

import PyPDF2
import os

#list all pdfs in the directory
def list_pdfs_os(directory):
    return [f for f in os.listdir(directory) if f.endswith('.pdf')]

directory = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_attachments'

fileList = list_pdfs_os(directory)


# COMMAND ----------

# initialize a vector of strings to store all of the extracted text from each pdf
allOutputs = empty_string_vector = ['' for _ in range(len(fileList))] 

# loop through each pdf in the directory, extract text from each page, coalesce
for j in range(len(fileList)):
    reader = PyPDF2.PdfReader(directory + '/' + fileList[j])
    # number of pages
    count = len(reader.pages)

    # initialize string to store extracted text from the current pdf
    output = ''

    # extract each page and coalesce text
    for i in range(count):
        page = reader.pages[i]
        output += page.extract_text()

    allOutputs[j] = output


# COMMAND ----------

import numpy as np
import pandas as pd
pd.set_option('display.max_colwidth', None)  # Shows full text
import re

# read in the original csv bulk download into a pandas dataframe
df = pd.read_csv('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_original_comments.csv')

# combine directory list with the extracted text
toAppend = np.column_stack((fileList, allOutputs))

#add column names to toAppend
toAppend2 = pd.DataFrame(toAppend, columns=['PDF Files', 'Extracted Text'])

# add a new column called Attachment Files to toAppend2
toAppend2['Attachment Files'] = "https://downloads.regulations.gov/" + toAppend2['PDF Files']

# the attachment file string doesn't quite match the original link
def replaceSubstr(text):
    text = re.sub("_attachment", "/attachment", text)
    return text

toAppend2.loc[:, "Attachment Files"] = toAppend2.loc[:, "Attachment Files"].apply(replaceSubstr) 

# merge df and toAppend2 by `Attachment Files`
df2 = pd.merge(df, toAppend2, on='Attachment Files', how='left')

# combine pre-existing comment with the extracted text.
df2['Comment'] = df2['Comment'] + df2['Extracted Text']




# COMMAND ----------

# Save the Pandas DataFrame to a CSV file with overwrite option
df2.to_csv(f'/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_original_comments_withExtractedText.csv', mode='w', index=False)