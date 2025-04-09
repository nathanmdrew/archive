# Databricks notebook source
# MAGIC %md
# MAGIC ### BertTopic
# MAGIC This code contains implementation of topic modeling (BERTopic) for public comments to government documents.
# MAGIC
# MAGIC [Instruction Manual](https://adb-1881246389460182.2.azuredatabricks.net/editor/notebooks/690124723433616?o=1881246389460182#command/1904172122827472)
# MAGIC
# MAGIC - [Example](https://maartengr.github.io/BERTopic/algorithm/algorithm.html#code-overview)
# MAGIC - [Supported Language Models](https://www.sBERT_net/docs/pretrained_models.html)
# MAGIC - [Download comments at regulations.gov](https://www.regulations.gov/)

# COMMAND ----------

# MAGIC %pip install bertopic==0.15
# MAGIC %pip install gensim==4.3.2
# MAGIC %pip install spacy
# MAGIC !python -m spacy download en_core_web_sm
# MAGIC %pip install nltk==3.9.1
# MAGIC %pip install numpy==2.1

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

import os  # Operating system interfaces
os.environ["TOKENIZERS_PARALLELISM"] = "false"  # Disable parallelism for tokenizers
from pathlib import Path
import yaml
import re  # Regular expressions
import string  # String operations
import numpy as np  # Numerical operations
np.random.seed(15)  # Set the random seed for NumPy to ensure reproducibility
from datetime import datetime

import pandas as pd  # Data manipulation

from IPython.core.interactiveshell import InteractiveShell  # IPython shell
# InteractiveShell.ast_node_interactivity = "all"  # Show all outputs

import builtins
import matplotlib.pyplot as plt  # Plotting

from pyspark.sql.functions import *  # Import all functions from pyspark.sql.functions

# import gensim.corpora as corpora  # Gensim corpora
# from gensim.models.coherencemodel import CoherenceModel  # Topic coherence

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1 - Load Data

# COMMAND ----------

app_dir = Path.cwd()

# COMMAND ----------

# Get the current date in 'YYYY-MM-DD' format
current_datetime = datetime.now().strftime('%Y-%m-%d')
print("Current Date:", current_datetime)

# Define the base output path
output_path = "output_directory/"  # Replace with your base directory
output_path = os.path.join(output_path, current_datetime)  # Append the date to the path

# Print the final output path
print("Output Path:", output_path)

# COMMAND ----------

config_path = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/config/config.yaml'

# Read the config file
with open(config_path, 'r') as file:
    config = yaml.safe_load(file)

# Create variables based on the items in the config file
for key, value in config.items():
    globals()[key] = value

# Example: Print the variables
for key in config.keys():
    print(f"{key} = {globals()[key]}")

# COMMAND ----------

source_path = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfs_rfi_comments.csv'
data_dir = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/'
output_path = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output'
attachments_path = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/attachments'

# COMMAND ----------

# Load the CSV file into a Spark DataFrame
df = spark.read.format('csv').options(
    header='true',  # First line of the file is a header
    inferSchema='true',  # Infer the schema of the CSV file
    multiline='true',  # Allow multiline fields
    escape="\""  # Escape character for quotes
).load(f'{source_path}')  # Load the CSV file from the specified path

# COMMAND ----------

doc_all = df.toPandas()  # Convert Spark DataFrame to Pandas DataFrame
doc_all.columns = doc_all.columns.str.replace(' ', '_')  # Replace spaces with underscores in column names
# doc_all.head(1)  # Display the first row of the DataFrame

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2 - Pre-Processing

# COMMAND ----------

df = doc_all[["Document_ID", "Comment"]]  # Select only the Document_ID and Comment columns from the DataFrame
df.shape  # Get the shape of the DataFrame

# COMMAND ----------

def clean_text(text): #substitute some words
    text = text.lower()  # Convert text to lowercase
    text = re.sub("^\s+|\s+$", "", text, flags=re.UNICODE)  # Remove leading and trailing whitespace
    text = " ".join(re.split("\s+", text, flags=re.UNICODE))  # Replace multiple spaces with a single space
    text = re.sub(r'http\S+', '', text)  # Remove URLs
    for r in (("covid-19","covid"), ("covid19","covid"), ("\n",""), ("&","and")):  # Replace specific substrings
        text = text.replace(*r)  # Apply replacements
    return text  # Return cleaned text

# COMMAND ----------

empty_comments = df[df['Comment'].isnull()] # In case there are empty comments
df = df.dropna(subset=['Comment']) # Drop na/empty comments
df.Comment = df.Comment.astype(str)  # Change to string
# df.shape

# COMMAND ----------

df.loc[:, "Comment"] = df.loc[:, "Comment"].apply(clean_text) # Run function for each comment

# COMMAND ----------

df.columns = df.columns.str.replace(' ', '_')  # Replace spaces in column names with underscores
display(df.head(2))  # Display the first 2 rows of the dataframe

# COMMAND ----------

# False = marks every single duplicate
duplic_comments = df.loc[df['Comment'].duplicated(keep = False), :].sort_values('Comment', ascending=False)  # Find all duplicates and sort by Comment in descending order
duplic_comments.shape  # Get the shape of the dataframe containing duplicates

# COMMAND ----------

# Keep only first of the duplicates in df  # Drop duplicates based on 'Comment' column, keeping the first occurrence
# Note that I keep first duplicated to inform topic modeling but then will place all duplicates in a sep group  # Reset index and drop the old index column
df = df.drop_duplicates(subset = "Comment", keep = "first").reset_index().drop(columns = 'index')  # Get the shape of the dataframe after dropping duplicates
# df.shape  # Display the shape of the dataframe

duplicated_ids = duplic_comments["Document_ID"].to_list()  # Convert Document_ID column to a list of duplicated IDs
def check_duplicate(value):  # Define a function to check if a value is in the list of duplicated IDs
    return value in duplicated_ids  # Return True if the value is in the list, otherwise False

df['Is_Duplicated'] = df['Document_ID'].apply(lambda x: check_duplicate(x))  # Marks first duplicate as true in a list of unique docs
# df.head(2)
# df[df['Is_Duplicated'] == True].shape  # Counts N of unique messages that are duplicates will be used in TM

# COMMAND ----------

# Convert 'Comment', 'Document_ID', and 'Is_Dubplicated' to lists

docs = df.Comment.values.tolist()  # Convert 'Comment' column to list
ids = df.Document_ID.values.tolist()  # Convert 'Document_ID' column to list
is_duplicated = df.Is_Duplicated.values.tolist()  # Convert 'Is_Duplicated' column to list
len(docs)  # Get the length of the 'docs' list

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3 - BERTopic Setup

# COMMAND ----------

from bertopic import BERTopic  # Topic modeling
from sklearn.feature_extraction.text import CountVectorizer  # Text vectorization
from umap import UMAP  # Dimensionality reduction
from hdbscan import HDBSCAN  # Clustering
from bertopic.vectorizers import ClassTfidfTransformer  # Class-based TF-IDF
from bertopic.representation import KeyBERTInspired  # KeyBERT representation
from sentence_transformers import SentenceTransformer  # Sentence embeddings
from transformers import pipeline  # Transformers pipeline
from transformers import AutoModelForSequenceClassification, AutoTokenizer, TextClassificationPipeline  # Transformers for sequence classification

import gensim.corpora as corpora  # Gensim corpora
from gensim.models.coherencemodel import CoherenceModel  # Topic coherence

# COMMAND ----------

# MAGIC %md
# MAGIC #### Stopwords

# COMMAND ----------

import nltk  # Natural Language Toolkit
from nltk import word_tokenize  # Tokenization
from nltk.stem import WordNetLemmatizer  # Lemmatization

# Download necessary NLTK resources
nltk.download(['stopwords', 'punkt', 'punkt_tab', 'wordnet', 'omw-1.4'])

# Load the CSV file into a Spark DataFrame
BERT_sw_file = spark.read.format('csv').options(  # Specify the format as CSV and set options
    header='true',  # First line of the file is a header
    inferSchema='true',  # Infer the schema of the CSV file
    multiline='true',  # Allow multiline fields
    escape="\""  # Escape character for quotes
).load(f'dbfs:/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/stopwords/{BERT_stopwords_path}')

BERT_stopwords = nltk.corpus.stopwords.words('english')  # Stopwords are used after clustering

# Convert the Spark DataFrame to a list
BERT_stopwords_file = BERT_sw_file.select(BERT_sw_file.columns[0]).rdd.flatMap(lambda x: x).collect()
# print(stopwords_file)

BERT_stopwords_file = []
BERT_stopwords_list = ['cdc', 'NIOSH', 'fire', 'smoke']

print('Stop words from file: ', BERT_sw_file)
print(BERT_sw_file)

print('newStopWords_input: ', BERT_stopwords_list)
print(BERT_stopwords_list)

BERT_all_stopwords = BERT_stopwords + BERT_stopwords_file + BERT_stopwords_list
print('All stop words:', BERT_all_stopwords)

# COMMAND ----------

print(BERT_calculate_probabilities)
print(BERT_cluster_selection_method)
print(BERT_coherence)
print(BERT_hdbscan_metric)
print(BERT_min_cluster_size)
print(BERT_min_components)
print(BERT_min_dist)
print(BERT_min_samples)
print(BERT_min_topic_size)
print(BERT_model_name)
print(BERT_n_components)
print(BERT_n_neighbors)
print(BERT_nr_topics)
print(BERT_ngram_range_max)
print(BERT_ngram_range_min)
print(BERT_top_n_words)
print(BERT_umap_metric)

# COMMAND ----------

BERT_calculate_probabilities = True
BERT_cluster_selection_method = "eom"
BERT_coherence = "u_mass"
BERT_hdbscan_metric = "euclidean"
BERT_min_cluster_size = 10.0
BERT_min_components = 5.0
BERT_min_dist = 0.5
BERT_min_samples = 1.0
BERT_min_topic_size = 10.0
BERT_model_name = "all-mpnet-base-v2"
BERT_n_components = 5.0
BERT_n_neighbors = 10.0
BERT_nr_topics = 5.0
BERT_ngram_range_max = 3.0
BERT_ngram_range_min = 1.0
BERT_top_n_words = 20.0
BERT_umap_metric = "cosine"

# COMMAND ----------

# Step 1 - Extract embeddings
embedding_model = SentenceTransformer(model_name_or_path = BERT_model_name) 

# Step 2 - Reduce dimensionality
umap_model = UMAP(n_neighbors=BERT_n_neighbors, n_components=BERT_n_components, min_dist=BERT_min_dist, metric=BERT_umap_metric, random_state=42)

# Step 3 - Cluster reduced embeddings
hdbscan_model = HDBSCAN(min_cluster_size=BERT_min_cluster_size, metric=BERT_hdbscan_metric, cluster_selection_method=BERT_cluster_selection_method, prediction_data=True, min_samples=BERT_min_samples) 

# Step 4 - Tokenize topics and lemmatize terms (this will happen after clustering)
class LemmaTokenizer:
    def __init__(self):
        self.wnl = WordNetLemmatizer()
    def __call__(self, doc):
        doc = re.sub(r'[^\w\d\s\']+', ' ', doc)  # Remove non-alphanumeric characters
        doc = re.sub('`', ' ', doc)  # Replace backticks with space
        doc = re.sub('\'', ' ', doc)  # Replace single quotes with space
        return [self.wnl.lemmatize(t) for t in word_tokenize(doc)]  # Lemmatize tokens
    
vectorizer_model = CountVectorizer(lowercase=True,
                                   stop_words=BERT_all_stopwords,
                                   tokenizer=LemmaTokenizer(),  
                                   ngram_range=(BERT_ngram_range_min, BERT_ngram_range_max))  # Initialize CountVectorizer with custom tokenizer and stopwords

# Step 5 - Create topic representation
ctfidf_model = ClassTfidfTransformer()  # Initialize ClassTfidfTransformer

# COMMAND ----------

# seed_topic_list = [['exposures'],
#                    ['controls'],
#                    ['equity'],
#                    ['hazards'],
#                    ['mental health'],
#                    ['PPE'],
#                    ['research needs'],
#                    ['constituents'],
#                    ['general']]

# seed_topic_list = [item if isinstance(item, list) else [item] for sublist in seed_topic_list for item in (sublist if isinstance(sublist, list) else [sublist])]

# assert all(isinstance(topic, list) for topic in seed_topic_list), "Each seed topic should be a list."
# assert all(all(isinstance(word, str) for word in topic) for topic in seed_topic_list), "Each seed topic should contain strings."

# COMMAND ----------

seed_topic_list = []

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4 - Run Multiple Topic Solutions Simultaneously
# MAGIC
# MAGIC * Note that the outliers cluster (labeled as "-1") seems to be in each topic solution. Thus, if you want to start with an actual 2 topic solution in addition to 'outliers' cluster', you need to specify 3-topic solution as a starting point.

# COMMAND ----------

all_models = []

# for n in range(3,32):  # Range of 3,32 gives 2 to 30 topic solutions plus a cluster with outliers
for n in range(3,32):  # Start from the number of seed topics
    topic_model = BERTopic(
                            nr_topics = n,
                            embedding_model = embedding_model,          # Step 1 - Extract embeddings
                            umap_model = umap_model,                    # Step 2 - Reduce dimensionality
                            hdbscan_model = hdbscan_model,              # Step 3 - Cluster reduced embeddings
                            vectorizer_model = vectorizer_model,        # Step 4 - Tokenize topics
                            ctfidf_model = ctfidf_model,                # Step 5 - Extract topic words
                            calculate_probabilities = BERT_calculate_probabilities,             # Calculate probabilities for doc in top
                            top_n_words = BERT_top_n_words,                  # Shows top N words in the outputs
                            min_topic_size = BERT_min_topic_size,            # Specify min size of docs in the cluster
    )

    topics, probs = topic_model.fit_transform(docs)                     # Fits the model & predicts documents
    
    new_topics = topic_model.reduce_outliers(
                                            docs, topics,
                                            probabilities = probs,
                                            strategy = "embeddings"
                                            )                           # Reduce outliers using embeddings strategy
    
    topic_model.update_topics(
                                docs,
                                topics = new_topics,
                                vectorizer_model = vectorizer_model,
                                ctfidf_model = ctfidf_model,
                                top_n_words = top_n_words
                            )                                           # Update topics with new topics and models
    
    d = {
        "n_topics":n,                       # Number of topics
        "model":topic_model,               # Topic model
        "topics":topics,                    # Topics
        "doc_ids":ids,                      # Document IDs
        "probs":probs,                      # Probabilities
        "is_duplicated":is_duplicated       # Is duplicated flag
    }

    all_models.append(d)    # Append dictionary to all_models list

# COMMAND ----------

# MAGIC %md
# MAGIC ### 5 - Calculate Topic Coherence

# COMMAND ----------

for i, d in enumerate(all_models):
    topic_model = d["model"]  # Extract topic model from dictionary
    topics = d["topics"]  # Extract topics from dictionary
    documents = pd.DataFrame({"Comment": docs,  # Create DataFrame with comments, IDs, and topics
                          "ID": ids,
                          "Topic": topics})  # Create DataFrame with comments, IDs, and topics

    # All docs combined into its relevant topic; e.g., 19 long documents for 19-topic model
    documents_per_topic = documents.groupby(['Topic'], as_index=False).agg({'Comment': ' '.join})

    # List of clean docs; length of 19 items/topics in the list
    cleaned_docs = topic_model._preprocess_text(documents_per_topic.Comment.values)  # Some basic preprocessing suggested before next steps

    # Extract vectorizer and analyzer from BERTopic; we want to make sure tokens are counted consistently
    vectorizer = topic_model.vectorizer_model  # Counts token (also removes stopwords & lemmatizes tokens)
    analyzer = vectorizer.build_analyzer()  # Handles tokenization below & allows for n-gram tokenization

    # Extract features for Topic Coherence evaluation
    words = vectorizer.get_feature_names()  # Gives a list of all unique words in the whole df in alphabetical order
    tokens = [analyzer(doc) for doc in cleaned_docs]  # List of lists; each list consists of all tokens in one big document representing the whole topic; note that tokens are not unique but they are lemmatized & stopwords are removed.

    dictionary = corpora.Dictionary(tokens)  # Initialize a dictionary to map assign pre-defined dictionary IDs to lemmatized words; input parameter for coherence function

    # Converts document into the bag-of-words (BoW) format = list of `(token_id, token_count for a given topic)`
    corpus = [dictionary.doc2bow(token) for token in tokens]  # For each non-unique but lemmatized token in each of the lists, assign ID to the token; uses token ID instead of actual token in the output; input parameter for coherence function

    # List of lists of unique (lemmatized) top tokens for each topic
    topic_words = [[words for words, _ in topic_model.get_topic(topic) if words != ''] 
                for topic in range(len(set(topics))-1)] 

    coherence_model = CoherenceModel(topics=topic_words,  # Lists of unique lemmatized (top) tokens for each topic
                                    texts=tokens,         # Non-unique lemmatized tokens for each topic w stopwords removed
                                    corpus=corpus,        # Token counts per topic
                                    dictionary=dictionary, # Tokens with uniquely assigned ids
                                    coherence='c_v')    # Coherence methods: u_mass', 'c_v', 'c_uci', 'c_npmi'
    topic_coherence = coherence_model.get_coherence()  # Calculate coherence score
    d["topic_words"] = topic_words  # Add topic words to dictionary
    d["coherence"] = topic_coherence  # Add coherence score to dictionary
    all_models[i] = d  # Update all_models list with new dictionary

# COMMAND ----------

# MAGIC %md
# MAGIC ### 6 - Plot Coherence for Various Topic Models

# COMMAND ----------

topic_n = []  # Initialize list to store number of topics
coherence_scores = []  # Initialize list to store coherence scores

for d in all_models:
    topic = d["n_topics"] - 1  # Note how subtraction happens here to understand real N of groups
    coherence = d["coherence"]  # Extract coherence score

    coherence_scores.append(coherence)  # Append coherence score to list
    topic_n.append(topic)  # Append number of topics to list

# COMMAND ----------

display(pd.DataFrame({"Topic Numbers": topic_n}))  # Display topic numbers
display(pd.DataFrame({"Coherence Scores": coherence_scores}))  # Display coherence scores

# COMMAND ----------

plt.plot(topic_n, coherence_scores)  # Plot coherence scores against number of topics
plt.legend(['coherence'])  # Add legend to the plot
plt.xticks(np.arange(builtins.min(topic_n), builtins.max(topic_n) + 1))  # Set x-ticks from min to max number of topics
plt.xticks(rotation=90)  # Rotate x-ticks by 90 degrees
plt.xlabel('Number of Clusters')  # Label x-axis
plt.ylabel('Score')  # Label y-axis

# COMMAND ----------

# MAGIC %md
# MAGIC ### 7 - Human Judgement Steps: Check Vaious Models of Interest

# COMMAND ----------

def get_model(all_models, n_topics):
    for model in all_models:  # Iterate through all models
        if model["n_topics"] == n_topics:  # Check if the number of topics matches
            return model  # Return the matching model

# COMMAND ----------

interest_model_info = get_model(all_models, 16)  # Select model of interest with a N serving as a topic solution
# Note that I need to add +1 compared to plot values as there is an empty cluster with outliers

# COMMAND ----------

interest_model_info["model"].visualize_barchart(n_words=40, width = 250, height = 1200, top_n_topics=45)  # Visualize the top 45 topics with a bar chart, showing 40 words per topic, with specified width and height

# COMMAND ----------

interest_model_info["model"].get_topic_freq()  # Get the frequency of each topic in the model

# COMMAND ----------

# Get the BERTopic model we're interested in
model = interest_model_info["model"]

# Get topic information
topic_info = model.get_topic_info()

# Display the top words for each topic
for index, row in topic_info.iterrows():
    topic_id = row['Topic']
    if topic_id != -1:  # Exclude the outlier topic
        top_words = model.get_topic(topic_id)
        print(f"\nTopic {topic_id}:")
        for word, score in top_words[:20]:  # Limit to top 10 words for readability
            print(f"  {word:<20} ({score:.4f})")

# COMMAND ----------

# Hierarchical Clustering Dendogram
interest_model_info["model"].visualize_hierarchy(custom_labels=True)  # Visualize the topic hierarchy with custom labels

# COMMAND ----------

# MAGIC %md
# MAGIC ### 8 - Create Final DF

# COMMAND ----------

# Start creating final df
all_docs_allCols = interest_model_info["model"].get_document_info(docs)  # With mix of all docs per cluster
rel_cols = all_docs_allCols[["Document", "Topic", "Probability"]]  # Select relevant columns
rel_cols["ID"] = df["Document_ID"].values  # Add Document_ID column
rel_cols["Is_Duplicated"] = df["Is_Duplicated"].values  # Add Is_Duplicated column

# COMMAND ----------

all_docs_allCols.shape  # Get the shape of the DataFrame

# COMMAND ----------

sorted_df = rel_cols.groupby('Topic').apply(lambda x: x.sort_values('Probability', ascending=False))  # Group by 'Topic' and sort within each group by 'Probability' in descending order
sorted_df.reset_index(drop=True, inplace=True)  # Reset index and drop the old index
sorted_df[sorted_df['Topic']== 0].head(10)  # Filter for 'Topic' equal to 0 and display the first 10 rows

# COMMAND ----------

sorted_df = sorted_df.rename(columns={'Topic': 'cluster'})  # Rename 'Topic' column to 'cluster'
sorted_df.shape  # Get the shape of the DataFrame

# COMMAND ----------

# Bring back variables of interest to original document
sorted_df = sorted_df.drop(['Document'], axis=1)  # Optional
df_merged = pd.merge(doc_all, sorted_df, how='left', left_on=['Document_ID'], right_on=['ID'])  # Merge doc_all with sorted_df on Document_ID and ID

# COMMAND ----------

df_merged.loc[df_merged['Is_Duplicated'].isna(), 'Is_Duplicated'] = True  # Add True for 'Is_Duplicated' where it is NaN

# COMMAND ----------

df_merged.to_csv(f'{output_path}/df_merged.csv', mode='w', index=False)

# COMMAND ----------

# Group by Topics and take the top 3 words for each topic
top_words <- final_df %>%
  group_by(Topics) %>%
  slice_head(n = 3) %>%
  summarise(Top_Words = str_c(Words, collapse = ", "))

print(top_words)

# COMMAND ----------

# # Add variable for date being after August 25 (per customer's request)
# df_merged['FormattedDate'] = pd.to_datetime(df_merged['Posted_Date'])  # Convert 'Posted_Date' to datetime
# df_merged['FormattedDate'] = df_merged['FormattedDate'].dt.strftime('%Y-%m-%d')  # Format datetime to 'YYYY-MM-DD'
# df_merged['FormattedDate'] = pd.to_datetime(df_merged['FormattedDate'])  # Convert formatted date back to datetime
# specific_date = pd.to_datetime('2023-08-26')  # Define the specific date
# df_merged['AfterAug25'] = df_merged['FormattedDate'].apply(lambda x: 'Before' if x < specific_date else 'After')  # Apply condition to check if date is before or after specific date
# df_merged.head(2)  # Display the first 2 rows of the dataframe

# COMMAND ----------

# MAGIC %md
# MAGIC ### 9 - Change Some Spark Settings for Saving 

# COMMAND ----------

import pyspark.sql.functions as F  # Import functions from pyspark.sql
from pyspark.sql.types import NullType  # Import NullType from pyspark.sql.types
from pyspark.sql.types import ArrayType  # Import ArrayType from pyspark.sql.types

df2 = spark.createDataFrame(df_merged)  # Create a Spark DataFrame from df_merged

df3 = df2.select([
    F.lit(None).cast('string').alias(i.name)  # Cast NullType columns to string and alias with column name
    if isinstance(i.dataType, NullType)  # Check if column data type is NullType
    else i.name  # Otherwise, keep the column name as is
    for i in df2.schema  # Iterate over the schema of df2
])

# COMMAND ----------

arr_col = [  # List of array columns
    i.name  # Column name
    for i in df3.schema  # Iterate over the schema of df3
    if isinstance(i.dataType, ArrayType)  # Check if column data type is ArrayType
]

final_df  = df3.select([  # Select columns from df3
    F.concat_ws(',', c)  # Concatenate array elements with comma
    if c in arr_col  # If column is in array columns
    else F.col(c)  # Otherwise, select the column as is
    for c in df3.columns  # Iterate over columns of df3
])

# COMMAND ----------

# Convert Spark DataFrame to Pandas DataFrame
pandas_df = final_df.toPandas()

output_filename = f"{filename}_rev1.csv"

# COMMAND ----------

def save_csv_with_unique_name(df, output_path, output_filename):
    # Ensure output_filename has .csv extension
    if not output_filename.endswith('.csv'):
        output_filename += '.csv'

    # Extract the base name (without extension) and the extension
    base_name, ext = os.path.splitext(output_filename)
    full_path = os.path.join(output_path, output_filename)

    # Increment file name if it already exists
    counter = 1
    while os.path.exists(full_path):
        full_path = os.path.join(output_path, f"{base_name}({counter}){ext}")
        counter += 1

    # Save the DataFrame to the final path
    df.to_csv(full_path, mode='x', index=False)  # mode='x' ensures file must not exist
    print(f"File saved as: {full_path}")
    return full_path

# COMMAND ----------

# Save the Pandas DataFrame to a CSV file with overwrite option
pandas_df.to_csv(f'{output_path}/{output_filename}', mode='w', index=False)