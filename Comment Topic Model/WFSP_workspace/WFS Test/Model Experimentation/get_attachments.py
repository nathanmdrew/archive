import os
import pandas as pd
import requests
import re
import yaml
import PyPDF2
from pathlib import Path

# Get the current working directory
app_dir = Path(__file__).parent
print(f"Current working directory: {app_dir}")

yaml_path = app_dir / 'config.yaml'
print(f"YAML configuration file path: {yaml_path}")

with open(yaml_path, 'r') as file:
    config = yaml.safe_load(file)

data_dir = Path(config['data_dir'])
print(f"Data directory: {data_dir}")

path = Path(config['path'])
print(f"Path: {path}")

attachments_dir = data_dir / 'attachments'
print(f"Attachments directory: {attachments_dir}")

output_path = data_dir / "output"
print(f"Output directory: {output_path}")

# Attachment download -----------------------------------

# Function to download a file from a URL
def download_file(url, dest_path):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check for HTTP errors
        with open(dest_path, 'wb') as f:
            f.write(response.content)
        print(f"Downloaded {url} to {dest_path}")
    except requests.exceptions.RequestException as e:
        print(f"Error downloading {url}: {e}")
        
# Read the CSV file into a DataFrame
subset_dat = pd.read_csv(path)

# Iterate over the Attachment.Files column and download attachments
for index, attachment_files in subset_dat['Attachment.Files'].iteritems():
    if pd.notna(attachment_files):  # Check if the field is not NaN
        url_list = attachment_files.split(",")  # Split the URL string into individual URLs
        for url in url_list:
            # Extract the filename from the URL
            filename_parts = re.split(r'/', url)
            if len(filename_parts) >= 5:
                filename = f"{filename_parts[4]}_{filename_parts[5]}"
                file_path = os.path.join(attachments_dir, filename)
                
                # Download the file
                download_file(url, file_path)

# Text Extraction -----------------------------------

# List all PDFs in the attachments directory
def list_pdfs_os(attachments_dir):
    return [f for f in os.listdir(attachments_dir) if f.endswith('.pdf')]

fileList = list_pdfs_os(attachments_dir)
print("File List: ", fileList)

file_input = "example.pdf"  # Define the file_input variable
file_name, file_extension = os.path.splitext(file_input)
final_file = os.path.join(attachments_dir, file_name + "_extracted" + file_extension)

print("Final file: ", final_file)

# COMMAND ----------

# initialize a vector of strings to store all of the extracted text from each pdf
allOutputs = empty_string_vector = ['' for _ in range(len(fileList))] 

# loop through each pdf in the directory, extract text from each page, coalesce
for j in range(len(fileList)):
    reader = PyPDF2.PdfReader(attachments_dir + '/' + fileList[j])
    # number of pages
    # initialize string to store extracted text from the current pdf
    output = ''

    # extract each page and coalesce text
    for i in range(count):
        page = reader.pages[i]
        output += page.extract_text()

    allOutputs[j] = output

# COMMAND ----------

# read in the original csv bulk download into a pandas dataframe
df = pd.read_csv(path_input)

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

final_file = os.path.join(directory, "new", file_input)
print(final_file)

# Save the Pandas DataFrame to a CSV file with overwrite option
df2.to_csv(final_file, mode='w', index=False)