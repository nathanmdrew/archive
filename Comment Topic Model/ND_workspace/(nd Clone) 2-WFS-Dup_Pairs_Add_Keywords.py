# Databricks notebook source
import pandas as pd
import re
import numpy as np
from pyspark.sql.functions import *  # Import all functions from pyspark.sql.functions

# COMMAND ----------

# Load the CSV file into a Spark DataFrame
#df = spark.read.format('csv').options(  # Specify the format as CSV and set options
#   header='true',  # First line of the file is a header
#    inferSchema='true',  # Infer the schema of the CSV file
#    multiline='true',  # Allow multiline fields
#    escape="\""  # Escape character for quotes
#).load('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/comments_rev1_pandas.csv')  # Load the CSV file from the specified path

df = pd.read_csv('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/comments_rev1_pandas.csv')

display(df)

# Display the DataFrame
#display(df)  # Use display() to show the DataFrame

# COMMAND ----------


df['cluster'] = pd.to_numeric(df['cluster'], errors='coerce').astype('Int64') #convert float into integer
df.head(2)

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

display(df)

# COMMAND ----------

type(df['Comment'])  # Check the type of the 'Comment' column in the DataFrame
# pyspark.sql.column.Column  # The type of the 'Comment' column is a PySpark Column

# clean text for keyword extraction
df['Clean_comment'] = df['Comment'].apply(clean_comment)
df.head(5)

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

# Apply the custom function 'contains_keywords' to the 'Comment' column of the DataFrame 'df'
# The function checks for the presence of keywords from the 'keywords1' list in each comment
# The result is stored in a new column 'OtherW'
from pyspark.sql.functions import udf
from pyspark.sql.types import BooleanType

# Define the UDF
contains_keywords_udf = udf(lambda x: contains_keywords(x, keywords1), BooleanType())

# Apply the UDF to the 'Comment' column
df = df.withColumn('OtherW', contains_keywords_udf(df['Comment']))

# Display the DataFrame
display(df)

# COMMAND ----------

from pyspark.sql.functions import udf
from pyspark.sql.types import BooleanType

# Define the UDF (User Defined Function) to check for keywords in the 'Comment' column
contains_keywords_udf = udf(lambda x: contains_keywords(x, keywords2), BooleanType())

# Apply the UDF to create a new column 'ForServ' that indicates the presence of keywords from 'keywords2' in the 'Comment' column
df = df.withColumn('ForServ', contains_keywords_udf(df['Comment']))

# Display the DataFrame with the new 'ForServ' column
display(df)

# COMMAND ----------

from pyspark.sql.functions import when

# Recode cluster as 'duplicated_or_empty' based on True values in Is_Duplicated column
df = df.withColumn('cluster', when(df['Is_Duplicated'], 'duplicated_or_empty').otherwise(df['cluster']))

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
df_merged.to_csv("15_cl_duplpairs.csv")