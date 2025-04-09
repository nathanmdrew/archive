# Databricks notebook source
import pandas as pd
import re
import numpy as np

# COMMAND ----------

# Set the source data file to be loaded
datafile = 'wfs_rfi_comments_rev1.csv'

# Set the file name to save the output as
outputfile = 'wfs_rfi_comments_rev2.csv'

# COMMAND ----------

df = pd.read_csv('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/test_output_rev1.csv')
df['cluster'] = pd.to_numeric(df['cluster'], errors='coerce').astype('Int64') #convert float into integer

# COMMAND ----------

def clean_comment(text):
    if pd.notna(text):  # Check if the text is not NaN
        text = text.lower()  # Convert text to lowercase
        text = text.replace('\\n', ' ')  # Replace escaped newline characters with a space
        text = text.replace('\n', ' ')  # Replace newline characters with a space
        text = re.sub(r'http\S+', '', text)  # Remove URLs
        text = text.encode('ascii',errors='ignore').decode()  # Remove non-ascii characters
        text = re.sub("^\s+|\s+$", "", text, flags=re.UNICODE)  # Remove leading and trailing whitespace
        text = " ".join(re.split("\s+", text, flags=re.UNICODE))  # Replace multiple spaces with a single space
        text = re.sub(r'[^\w\s]', '', text)  # Remove punctuation
        text = re.sub(r'\d', '', text)  # Remove numbers
    else:
        pass  # Do nothing if text is NaN
    return text  # Return the cleaned text

# COMMAND ----------

# clean text for keyword extraction
df['Clean_comment'] = df['Comment'].apply(clean_comment)

# COMMAND ----------

# Keywords for category 1
keywords1 = [
    # 'altenburger',
    # 'devastating',
    # 'safeguards'
]

# Keywords for category 2
keywords2 = [
    # 'foreign service',
    # 'foreign service officer',
    # 'foreign service officer',
    # 'foreign service employee',
    # 'foreign service employees',
    # 'american foreign service association',
    # 'afsa'
]

# COMMAND ----------

# Custom function to return identified keywords in a separate column
def contains_keywords(text, keywords):
    if pd.notna(text):  # Check if the text is not NaN
        found_keywords = []  # Initialize an empty list to store found keywords
        for keyword in keywords:  # Iterate over each keyword in the list
            if keyword in text:  # Check if the keyword is in the text
                found_keywords.append(keyword)  # Append the keyword to the list if found
        return found_keywords  # Return the list of found keywords
    else:
        pass  # Do nothing if the text is NaN

# COMMAND ----------

# Apply the custom function to identify keywords from category 1 in the 'Clean_comment' columnand store the result in a new column 'OtherW'
df['OtherW'] = df['Clean_comment'].apply(lambda x: contains_keywords(x, keywords1))

# COMMAND ----------

# Apply the custom function to identify keywords from category 2 in the 'Clean_comment' column and store the result in a new column 'ForServ'
df['ForServ'] = df['Clean_comment'].apply(lambda x: contains_keywords(x, keywords2))

# COMMAND ----------

# Recode cluster as 'duplicated_or_empty' based on True values in Is_Duplicated column
recode_value = np.where(df['Is_Duplicated'], 'duplicated_or_empty', df['cluster'])
df['cluster'] = recode_value

# COMMAND ----------

# create group of duplicates within all duplicated comments
df_duplicated = df[df['cluster'] == 'duplicated_or_empty']  # Filter the DataFrame to include only rows where the 'cluster' column is 'duplicated_or_empty'
# df_duplicated.shape  # Get the shape (number of rows and columns) of the filtered DataFrame

# COMMAND ----------

# Select 'Document_ID' and 'Clean_comment' columns from the 'df_duplicated' DataFrame
df_dupl_selCols = df_duplicated.loc[:, ['Document_ID','Clean_comment']]

# COMMAND ----------

# Create a dictionary 'text_to_group' where each unique 'Clean_comment' text is mapped to a unique group number
text_to_group = {text: group_num for group_num, text in enumerate(df_dupl_selCols['Clean_comment'].unique())}

# COMMAND ----------

# Map each 'Clean_comment' to its corresponding group number using 'text_to_group' dictionary and create a new column 'DuplGr'
df_dupl_selCols['DuplGr'] = df_dupl_selCols['Clean_comment'].map(text_to_group)

# COMMAND ----------

#keep only ID and dupl group for merging
df_dupl_selCols.drop('Clean_comment', axis = 1, inplace = True)

# COMMAND ----------

#left join 
df_merged = pd.merge(df, df_dupl_selCols, how='left', left_on=['Document_ID'],right_on=['Document_ID'])  # Perform a left join between df and df_dupl_selCols on 'Document_ID'
df_merged['DuplGr'] = pd.to_numeric(df_merged['DuplGr'], errors='coerce').astype('Int64')  # Convert 'DuplGr' column to numeric, coercing errors, and then to integer type

# COMMAND ----------

#create cluster_labelled column
mapping = {
    0: '0',
    1: '1',
    2: '2',
    3: '3',
    4: '4',
    5: '5',
    6: '6',
    7: '7',
    8: '8',
    9: '9',
    10: '10',
    11: '11',
    12: '12',
    13: '13',
    14: '14',
    'duplicated_or_empty': 'Duplicated/Empty'
}

# COMMAND ----------

# Map the 'cluster' column to the 'mapping' dictionary and create a new column 'cluster_labelled'
df_merged['cluster_labelled'] = df_merged['cluster'].map(mapping)

# COMMAND ----------

# Rename the 'Probability' column to 'Prob' to save space in the dashboard
df_merged.rename(columns = {'Probability': 'Prob'}, inplace = True)

# COMMAND ----------

df_merged['cluster_labelled'] = df_merged['cluster_labelled'].astype(str) # Convert cluster_labelled to string
df_merged['Prob'] = pd.to_numeric(df_merged['Prob']) # Convert Prob to numeric

df_merged['Prob'] = df_merged['Prob'].round(2) # Round Prob to 2 decimal places
df_merged['OtherW'] = df_merged['OtherW'].astype(str) # Convert OtherW to string
df_merged['OtherW'] = df_merged['OtherW'].str.replace('[\[\]]', '') # Remove square brackets from OtherW
df_merged['OtherW'] = df_merged['OtherW'].str.replace("'", '') # Remove single quotes from OtherW

# COMMAND ----------

# Save the DataFrame 'df_merged' to a CSV file named "comments_rev2.csv"
df_merged.to_csv(f'/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/{outputfile}', mode='w', index=False)