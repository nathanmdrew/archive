# Databricks notebook source
import pandas as pd
import re
import numpy as np

# COMMAND ----------

datafile = 'wfs_rfi_comments_rev1_TBuse.csv'

csv_file_path = f'/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/{datafile}' # Provide the correct path to the CSV file

df = pd.read_csv(csv_file_path)
df['cluster'] = pd.to_numeric(df['cluster'], errors='coerce').astype('Int64') #convert float into integer
display(df.head(2))

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
# df.head(5)

# COMMAND ----------

# Keywords for category 1
keywords1 = [
    'altenburger',
    'devastating',
    'safeguards'
]

# Keywords for category 2
keywords2 = [
    'foreign service',
    'foreign service officer',
    'foreign service officer',
    'foreign service employee',
    'foreign service employees',
    'american foreign service association',
    'afsa'
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

# Apply the custom function to identify keywords from category 1 in the 'Clean_comment' column and store the result in a new column 'OtherW'
df['OtherW'] = df['Clean_comment'].apply(lambda x: contains_keywords(x, keywords1))

# COMMAND ----------

# Apply the custom function to identify keywords from category 2 in the 'Clean_comment' column and store the result in a new column 'ForServ'
df['ForServ'] = df['Clean_comment'].apply(lambda x: contains_keywords(x, keywords2))

# COMMAND ----------

# Recode cluster as 'duplicated_or_empty' based on True values in Is_Duplicated column
recode_value = np.where(df['Is_Duplicated'], 'duplicated_or_empty', df['cluster'])
df['cluster'] = recode_value

df.tail(6)  # Display the last 6 rows of the DataFrame

# COMMAND ----------

# create group of duplicates within all duplicated comments
df_duplicated = df[df['cluster'] == 'duplicated_or_empty']  # Filter the DataFrame to include only rows where the 'cluster' column is 'duplicated_or_empty'
df_duplicated.shape  # Get the shape (number of rows and columns) of the filtered DataFrame

# COMMAND ----------

# Select 'Document_ID' and 'Clean_comment' columns from the 'df_duplicated' DataFrame
df_dupl_selCols = df_duplicated.loc[:, ['Document_ID','Clean_comment']]

# Display the first 2 rows of the 'df_dupl_selCols' DataFrame
df_dupl_selCols.head(2)

# COMMAND ----------

# Create a dictionary 'text_to_group' where each unique 'Clean_comment' text is mapped to a unique group number
text_to_group = {text: group_num for group_num, text in enumerate(df_dupl_selCols['Clean_comment'].unique())}

# COMMAND ----------

# Map each 'Clean_comment' to its corresponding group number using 'text_to_group' dictionary and create a new column 'DuplGr'
df_dupl_selCols['DuplGr'] = df_dupl_selCols['Clean_comment'].map(text_to_group)

# Display the first 6 rows of the updated 'df_dupl_selCols' DataFrame
df_dupl_selCols.head(6)

# COMMAND ----------

# Get the counts of each unique group number in the 'DuplGr' column
df_dupl_selCols['DuplGr'].value_counts()

# COMMAND ----------

#keep only ID and dupl group for merging
df_dupl_selCols.drop('Clean_comment', axis = 1, inplace = True)
df_dupl_selCols.head(2)

# COMMAND ----------

#left join 
df_merged = pd.merge(df, df_dupl_selCols, how='left', left_on=['Document_ID'],right_on=['Document_ID'])  # Perform a left join between df and df_dupl_selCols on 'Document_ID'
df_merged['DuplGr'] = pd.to_numeric(df_merged['DuplGr'], errors='coerce').astype('Int64')  # Convert 'DuplGr' column to numeric, coercing errors, and then to integer type

# COMMAND ----------

# Print the shape of the merged DataFrame
print(df_merged.shape)

# Display the first 4 rows of the merged DataFrame
df_merged.head(4)

# COMMAND ----------

#create cluster_labelled column
mapping = {
0: '0_partSupport_support',
1: '1_againstRule_homeless',
2: '2_govWorkers_varDocs',
3: '3_breeders',
4: '4_govWorkers_burden',
5: '5_rescue',
6: '6_saveDogs_short',
7: '7_govWorkers_short',
8: '8_fairTreat_animals',
9: '9_rescue_cdc_opinions',
10: '10_doNot_kill_short',
11: '11_animal_experiment',
12: '12_petOwners_except',
13: '13_doNot_kill_redTape',
14: '14_otherArguments',
'duplicated_or_empty':'duplicated_or_empty'
}

# COMMAND ----------

# Map the 'cluster' column to the 'mapping' dictionary and create a new column 'cluster_labelled'
df_merged['cluster_labelled'] = df_merged['cluster'].map(mapping)

# COMMAND ----------

# Rename the 'Probability' column to 'Prob' to save space in the dashboard
df_merged.rename(columns = {'Probability': 'Prob'}, inplace = True)

# COMMAND ----------

df_merged.head(2)

# COMMAND ----------

# Save the DataFrame 'df_merged' to a CSV file named "15_cl_duplpairs.csv"
df_merged.to_csv('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/comments_rev2.csv')