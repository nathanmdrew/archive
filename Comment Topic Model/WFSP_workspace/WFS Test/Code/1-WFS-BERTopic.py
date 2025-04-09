# Databricks notebook source
# MAGIC %md
# MAGIC ##### BertTopic
# MAGIC This code contains implementation of topic modeling (BERTopic) for public comments to government documents. 
# MAGIC
# MAGIC - [Example](https://maartengr.github.io/BERTopic/algorithm/algorithm.html#code-overview)
# MAGIC - [Supported Language Models](https://www.sbert.net/docs/pretrained_models.html)
# MAGIC - [Download comments at regulations.gov](https://www.regulations.gov/)

# COMMAND ----------

# # Section commented out because libraries have been installed to cluster. Uncomment to run on a different location that lacks these libraries.

%pip install bertopic==0.15
%pip install gensim==4.3.2
%pip install spacy
!python -m spacy download en_core_web_sm
%pip install nltk==3.9.1
%pip install numpy==2.1
dbutils.library.restartPython()



# COMMAND ----------

from bertopic import BERTopic  # Topic modeling
from umap import UMAP  # Dimensionality reduction
from hdbscan import HDBSCAN  # Clustering
from sentence_transformers import SentenceTransformer  # Sentence embeddings
from sklearn.feature_extraction.text import CountVectorizer  # Text vectorization
from bertopic.representation import KeyBERTInspired  # KeyBERT representation
from bertopic.vectorizers import ClassTfidfTransformer  # Class-based TF-IDF
import pandas as pd  # Data manipulation
import numpy as np  # Numerical operations

import builtins
import matplotlib.pyplot as plt
from datetime import datetime
import os

# Get the current date as a string in the format 'YYYYMMDD'
current_date = datetime.now().strftime('%Y%m%d')

import gensim.corpora as corpora  # Gensim corpora
from gensim.models.coherencemodel import CoherenceModel  # Topic coherence
from IPython.core.interactiveshell import InteractiveShell  # IPython shell
# InteractiveShell.ast_node_interactivity = "all"  # Show all outputs
pd.set_option('display.max_colwidth', None)  # Shows full text

import nltk  # Natural Language Toolkit
from nltk import word_tokenize  # Tokenization
from nltk.stem import WordNetLemmatizer  # Lemmatization
import nltk  # Natural Language Toolkit
nltk.download('stopwords')  # Download stopwords
nltk.download('punkt')  # Download punkt tokenizer
nltk.download('wordnet')  # Download wordnet
nltk.download('omw-1.4')  # Download wordnet data
import matplotlib.pyplot as plt  # Plotting
import re  # Regular expressions
import string  # String operations
import os  # Operating system interfaces
os.environ["TOKENIZERS_PARALLELISM"] = "false"  # Disable parallelism for tokenizers
from transformers import pipeline  # Transformers pipeline
from transformers import AutoModelForSequenceClassification, AutoTokenizer, TextClassificationPipeline  # Transformers for sequence classification
from pyspark.sql.functions import *  # Import all functions from pyspark.sql.functions

# COMMAND ----------

np.random.seed(15)  # Set the random seed for NumPy to ensure reproducibility

# COMMAND ----------

# MAGIC %md
# MAGIC #### 1 - Load data

# COMMAND ----------

# Set the source data file to be loaded - not the full path, just the file name
datafile = 'b_reader_processed.csv'

current_datetime = datetime.now().strftime('%Y-%m-%d')

print("Current Date and Time:", current_datetime)
output_dir = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output"
output_path = os.path.join(output_dir, current_datetime)

print(output_path)

# COMMAND ----------

# Check if folder exists and handle versioning
if os.path.exists(output_path):
    version = 1
    while os.path.exists(os.path.join(output_path, f"{current_datetime}({version})")):
        version += 1
    output_path = os.path.join(output_path, f"{current_datetime}({version})")

os.makedirs(output_path, exist_ok=True)
print(f"Directory created: {output_path}")


# COMMAND ----------

# Load the CSV file into a Spark DataFrame
df = spark.read.format('csv').options(  # Specify the format as CSV and set options
    header='true',  # First line of the file is a header
    inferSchema='true',  # Infer the schema of the CSV file
    multiline='true',  # Allow multiline fields
    escape="\""  # Escape character for quotes
).load(f'dbfs:/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/{datafile}')  # Load the CSV file from the specified path

# Display the DataFrame
display(df)  # Use display() to show the DataFrame

# COMMAND ----------

doc_all = df.toPandas()  # Convert Spark DataFrame to Pandas DataFrame
doc_all.columns = doc_all.columns.str.replace(' ', '_')  # Replace spaces with underscores in column names
# doc_all.head(1)  # Display the first row of the DataFrame

# COMMAND ----------

# MAGIC %md
# MAGIC #### 2- Pre-Processing

# COMMAND ----------

df = doc_all[["Document_ID", "Comment"]]  # Select only the Document_ID and Comment columns from the DataFrame
df.shape  # Get the shape of the DataFrame

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Text Cleaning

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
df.shape

# COMMAND ----------

df.loc[:, "Comment"] = df.loc[:, "Comment"].apply(clean_text) # Run function for each tweet

# COMMAND ----------

df.columns = df.columns.str.replace(' ', '_')  # Replace spaces in column names with underscores
display(df.head(2))  # Display the first 2 rows of the dataframe

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Create dataframe with duplicate comments

# COMMAND ----------

# False = marks every single duplicate
duplic_comments = df.loc[df['Comment'].duplicated(keep = False), :].sort_values('Comment', ascending=False)  # Find all duplicates and sort by Comment in descending order
duplic_comments.shape  # Get the shape of the dataframe containing duplicates

# COMMAND ----------

# Keep only first of the duplicates in df  # Drop duplicates based on 'Comment' column, keeping the first occurrence
# Note that I keep first duplicated to inform topic modeling but then will place all duplicates in a sep group  # Reset index and drop the old index column
df = df.drop_duplicates(subset = "Comment", keep="first").reset_index().drop(columns = 'index')  # Get the shape of the dataframe after dropping duplicates
df.shape  # Display the shape of the dataframe

# COMMAND ----------

duplicated_ids = duplic_comments["Document_ID"].to_list()  # Convert Document_ID column to a list of duplicated IDs
def check_duplicate(value):  # Define a function to check if a value is in the list of duplicated IDs
    return value in duplicated_ids  # Return True if the value is in the list, otherwise False

# COMMAND ----------

df['Is_Duplicated'] = df['Document_ID'].apply(lambda x: check_duplicate(x))  # Marks first duplicate as true in a list of unique docs
df.head(2)

# COMMAND ----------

df[df['Is_Duplicated'] == True].shape  # Counts N of unique messages that are duplicates will be used in TM

# COMMAND ----------

# MAGIC %md
# MAGIC #### 3 - BERTopic Setup

# COMMAND ----------

docs = df.Comment.values.tolist()  # Convert 'Comment' column to list
ids = df.Document_ID.values.tolist()  # Convert 'Document_ID' column to list
is_duplicated = df.Is_Duplicated.values.tolist()  # Convert 'Is_Duplicated' column to list
# topics = df.Topic.values.tolist()
len(docs)  # Get the length of the 'docs' list

# COMMAND ----------

# Step 1 - Extract embeddings
embedding_model = SentenceTransformer(model_name_or_path = "all-mpnet-base-v2") 

# Step 2 - Reduce dimensionality
umap_model = UMAP(n_neighbors=10, n_components=5, min_dist=0.5, metric='cosine', random_state=42)

# Step 3 - Cluster reduced embeddings
hdbscan_model = HDBSCAN(min_cluster_size=5, metric='euclidean', cluster_selection_method='leaf', prediction_data=True, min_samples=5) 

# Step 4 - Tokenize topics and lemmatize terms (this will happen after clustering)
class LemmaTokenizer:
    def __init__(self):
        self.wnl = WordNetLemmatizer()
    def __call__(self, doc):
        doc = re.sub(r'[^\w\d\s\']+', ' ', doc)  # Remove non-alphanumeric characters
        doc = re.sub('`', ' ', doc)  # Replace backticks with space
        doc = re.sub('\'', ' ', doc)  # Replace single quotes with space
        return [self.wnl.lemmatize(t) for t in word_tokenize(doc)]  # Lemmatize tokens
    
stopwords = nltk.corpus.stopwords.words('english')  # Stopwords are used after clustering
# newStopWords = ['cdc', 'rabies', 'vaccination', 'vaccine', 'regulation',
#                 'vaccinated', 'canine', 'dog', 'importation', 'pet', 'cat',
#                 'proposed', 'require', 'requirement', 'policy', 'importation',
#                 'imported', 'rule', 'importing', 'u',
#                 'law', 'animal', 'ruling', 'wa', 'across', 'already',
#                 'proposal', 'nprm', 'pas', 'dont', 'v', 'thus',
#                 'non', 'ha', 'would', 'need', 'others', 'ever', 'doe', 'many', 'united', 'state',
#                 '1' , '3', '2', '6', 'may', 'one', 'must', 'well', 'please',
#                 'thing', 'like', 'attached', 'moron', 'anyone', 'also',
#                 'every', 'without', 'way', 'via', 'really', 'able', '16', 'everyone',
#                 'sense', 'alright', 'redctaoecalliw', 'fetsko', 'beyond']
newStopWords = ['cdc', 'NIOSH', 'fire', 'smoke']
stopwords.extend(newStopWords)  # Extend stopwords list with new stopwords
vectorizer_model = CountVectorizer(lowercase=True, stop_words=stopwords, tokenizer=LemmaTokenizer(),  
                                   ngram_range=(1, 1))  # Initialize CountVectorizer with custom tokenizer and stopwords

# Step 5 - Create topic representation
ctfidf_model = ClassTfidfTransformer()  # Initialize ClassTfidfTransformer

# COMMAND ----------

# MAGIC %md
# MAGIC #### 4- Run Multiple Topic Solutions Simultaneously
# MAGIC
# MAGIC * Note that the outliers cluster (labeled as "-1") seems to be in each topic solution. Thus, if you want to start with an actual 2 topic solution in addition to 'outliers' cluster', you need to specify 3-topic solution as a starting point.

# COMMAND ----------

import nltk
nltk.download('punkt_tab')

# COMMAND ----------

all_models = []

for n in range(3,32):  # Range of 3,32 gives 2 to 30 topic solutions plus a cluster with outliers
    topic_model = BERTopic(nr_topics=n,
                        embedding_model = embedding_model,        # Step 1 - Extract embeddings
                        umap_model=umap_model,                    # Step 2 - Reduce dimensionality
                        hdbscan_model=hdbscan_model,              # Step 3 - Cluster reduced embeddings
                        vectorizer_model=vectorizer_model,        # Step 4 - Tokenize topics
                        ctfidf_model=ctfidf_model,                # Step 5 - Extract topic words
                        calculate_probabilities=True,             # Calculate probabilities for doc in top
                        top_n_words=20,                           # Shows top N words in the outputs
                        min_topic_size=8,
                        n_gram_range=(1, 3),
                        )                                         # Specify min size of docs in the cluster
    topics, probs = topic_model.fit_transform(docs)  # Fits the model & predicts documents
    new_topics = topic_model.reduce_outliers(docs, topics, probabilities=probs, strategy="embeddings")  # Reduce outliers using embeddings strategy
    topic_model.update_topics(docs, topics=new_topics, vectorizer_model=vectorizer_model, ctfidf_model=ctfidf_model, top_n_words = 18)  # Update topics with new topics and models
    d = {
        "n_topics":n,  # Number of topics
        "model": topic_model,  # Topic model
        "topics":topics,  # Topics
        "doc_ids":ids,  # Document IDs
        "probs":probs,  # Probabilities
        "is_duplicated":is_duplicated  # Is duplicated flag
    }

    all_models.append(d)  # Append dictionary to all_models list

# COMMAND ----------

# MAGIC %md
# MAGIC #### 5- Calculate Topic Coherence
# MAGIC
# MAGIC To calculate topic coherence, you need the following inputs:
# MAGIC
# MAGIC * **dictionary**: gives unique ID to each lemmatized token; universal accross different model i.e., not model-specific.
# MAGIC
# MAGIC * **corpus**: **list of lists of tuples** of (token_id, token_count for a given topic); counts lemmatized tokens accross all documents **in each topic**. Converts each document into the bag-of-words (BoW) format and produces tuples for each topic. For instance, a token with id 0 may appear in each topic and will be shown in multiples tuples in different lists as (0, 4); (0;18); (0;25) if observed 4;8;25 times in each topic respectively.
# MAGIC
# MAGIC * **texts**: **list of lists** where each list incorporates all (not unique but lemmatized) tokens for each topic; needed for coherence models that use sliding window based probability estimator; varies for each model solution.
# MAGIC
# MAGIC * **topics**: **list of lists of unique lemmatized top tokens** for each topic; note that these are taken from BERTopic from the list of most representative tokens for each topic; if you want to have more tokens as inputs for coherence calculation, you need to increase the parameter *top_n_words* in Bertopic function. This input will vary for each model solution. Note the **substraction of 1**; it has been done to drop representative words for topic labeled as '-1' as it conceptually does not represent a topic and it is an outlier group of documents & their respective words.
# MAGIC
# MAGIC * **coherence**: type of coherence such as: 'c_v'; 'u_mass','c_uci', 'c_npmi'. See link to the paper below for more details about each coherence measure. C_V seems like a promising measure due to its correlation with human annotations (see original paper below of topic coherences by Roder)
# MAGIC
# MAGIC **Other Notes**: 
# MAGIC
# MAGIC * General intuition: topics input is checked against *dictionary* and *corpus*.
# MAGIC * Note that *vectorizer* is used directly from bertopic model to create dictionary; corpus, tokens
# MAGIC * Coherence is a proxy for a topic model's performance; it is not a ground truth. It is important to look at the topics and see if they make sense.
# MAGIC
# MAGIC [Link to code sources to calculate coherence, suggested by BERTopic developer](https://github.com/MaartenGr/BERTopic/issues/90)
# MAGIC
# MAGIC [Link to paper that explains different types of coherences](http://svn.aksw.org/papers/2015/WSDM_Topic_Evaluation/public.pdf)
# MAGIC

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
# MAGIC #### 6 - Plot Coherence for Various Topic Models

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

import builtins
import numpy as np
import matplotlib.pyplot as plt

plt.plot(topic_n, coherence_scores)  # Plot coherence scores against number of topics
plt.legend(['coherence'])  # Add legend to the plot
plt.xticks(np.arange(builtins.min(topic_n), builtins.max(topic_n) + 1))  # Set x-ticks from min to max number of topics
plt.xticks(rotation=90)  # Rotate x-ticks by 90 degrees
plt.xlabel('Number of Clusters')  # Label x-axis
plt.ylabel('Score')  # Label y-axis

# Save the plot to the specified folder
plt.savefig(f'{output_path}/coherence_plot.png')
plt.close()  # Close the figure to free memory

# COMMAND ----------

# MAGIC %md
# MAGIC #### 7 - Human Judgement Steps: Check Vaious Models of Interest

# COMMAND ----------

import plotly.io as pio  # Import plotly.io for saving figures

def get_model(all_models, n_topics):
    for model in all_models:  # Iterate through all models
        if model["n_topics"] == n_topics:  # Check if the number of topics matches
            return model  # Return the matching model

interest_model_info = get_model(all_models, 16)  # Select model of interest with N topics

# Save the bar chart visualization
fig_barchart = interest_model_info["model"].visualize_barchart(
    n_words=40, width=250, height=1200, top_n_topics=45
)
fig_barchart.write_html(f'{output_path}/bertopic_barchart.html')
# fig_barchart.write_image(f'{output_path}/bertopic_barchart.png')

# Save the hierarchy visualization
fig_hierarchy = interest_model_info["model"].visualize_hierarchy(custom_labels=True)
fig_hierarchy.write_html(f'{output_path}/bertopic_hierarchy.html')
# fig_hierarchy.write_image(f'{output_path}/bertopic_hierarchy.png')

# Save the topics visualization
# fig_topics = interest_model_info["model"].visualize_topics()
# fig_topics.write_html(f'{output_path}/bertopic_topics.html')
# fig_topics.write_image(f'{output_path}/bertopic_topics.png')

# Optional: Save the heatmap visualization if needed
# fig_heatmap = interest_model_info["model"].visualize_heatmap()
# fig_heatmap.write_html(f'{output_path}/bertopic_heatmap.html')
# fig_heatmap.write_image(f'{output_path}/bertopic_heatmap.png')

# COMMAND ----------

interest_model_info = get_model(all_models, 16)  # Select model of interest with a N serving as a topic solution
# Note that I need to add +1 compared to plot values as there is an empty cluster with outliers

# COMMAND ----------

interest_model_info["model"].visualize_barchart(n_words=40, width = 250, height = 1200, top_n_topics=45)  # Visualize the top 45 topics with a bar chart, showing 40 words per topic, with specified width and height

# COMMAND ----------

interest_model_info["model"].get_topic_freq()  # Get the frequency of each topic in the model

# COMMAND ----------

interest_model_info["model"].visualize_hierarchy(custom_labels=True)  # Visualize the topic hierarchy with custom labels

# COMMAND ----------

# topic_model.visualize_topics(k=min(topic_model.topics_, len(topic_model.c_tf_idf)))

# COMMAND ----------

# Now call the visualize_heatmap function
# topic_model.visualize_heatmap()

# COMMAND ----------

# topic_model.visualize_topics_per_class(topics_per_class)

# COMMAND ----------

print(df)

# COMMAND ----------

# Select model of interest
interest_model_info = get_model(all_models, 16)  # Example with 16 topics

# Step 2: Prepare the `topics_per_class` DataFrame
docs = df['Comment'].tolist()  # Assuming 'Comment' is the column with text data
topics, probs = interest_model_info["model"].fit_transform(docs)

# Use a valid class column (categorical/grouping variable)
classes = df['Comment']  # Example: Replace 'AfterAug25' with the relevant column

# Create the basic topics_per_class DataFrame
topics_per_class = pd.DataFrame({
    "Topic": topics,
    "Class": classes
})

# Get topic frequency details (required for better visualizations)
topic_info = interest_model_info["model"].get_topic_info()

# Merge topic word info for labeling
topics_per_class = topics_per_class.merge(topic_info[['Topic', 'Name']], on='Topic', how='left')

# Rename 'Name' to 'Words' (optional for visualization clarity)
topics_per_class.rename(columns={'Name': 'Words'}, inplace=True)

# Revalidate Frequencies across Topic-Class if error persists:
topics_per_class['Frequency'] = topics_per_class.groupby(['Class', 'Topic'])['Topic'].transform('count')

# Visualize topics per class
fig = interest_model_info["model"].visualize_topics_per_class(topics_per_class)
fig.show()
fig.write_html(f'{output_path}/topics_per_class.html')


# COMMAND ----------

# MAGIC %md
# MAGIC #### 8 - Create Final DF
# MAGIC * add duplicates to the topic modeling file

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

# # Add variable for date being after August 25 (per customer's request)
# df_merged['FormattedDate'] = pd.to_datetime(df_merged['Posted_Date'])  # Convert 'Posted_Date' to datetime
# df_merged['FormattedDate'] = df_merged['FormattedDate'].dt.strftime('%Y-%m-%d')  # Format datetime to 'YYYY-MM-DD'
# df_merged['FormattedDate'] = pd.to_datetime(df_merged['FormattedDate'])  # Convert formatted date back to datetime
# specific_date = pd.to_datetime('2023-08-26')  # Define the specific date
# df_merged['AfterAug25'] = df_merged['FormattedDate'].apply(lambda x: 'Before' if x < specific_date else 'After')  # Apply condition to check if date is before or after specific date
# df_merged.head(2)  # Display the first 2 rows of the dataframe

# COMMAND ----------

# MAGIC %md
# MAGIC #### 9 - Change Some Spark Settings for Saving 

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

from IPython.display import display

display(final_df)  # Displays the DataFrame in a table format

# COMMAND ----------

# from pyspark.sql.functions import split, expr, concat_ws

# # Assuming the column containing the topics is named 'topic'
# # Split the topic column into words
# split_col = split(final_df['Topics'], ' ')

# # Select the first 3 words and concatenate them back into a single string
# final_df = final_df.withColumn('first_3_words', concat_ws(' ', split_col[0], split_col[1], split_col[2]))

# # Display the DataFrame with the new column
# display(final_df.select('first_3_words'))

# COMMAND ----------

import os

# Remove the .csv extension
datafile_no_ext = datafile.rsplit('.csv', 1)[0]
pandas_df = final_df.toPandas()

# Define the initial save path
save_file = os.path.join(output_path, f'{datafile_no_ext}_rev1.csv')

# Check if the file already exists
if os.path.exists(save_file):
    # Find the next available file name by appending a version number
    version = 1
    while os.path.exists(os.path.join(output_path, f'{datafile_no_ext}_rev1({version}).csv')):
        version += 1
    # Update save_file with the new unique filename
    save_file = os.path.join(output_path, f'{datafile_no_ext}_rev1({version}).csv')

# Save the DataFrame to the file with the (new) unique filename
pandas_df.to_csv(save_file, mode='w', index=False)

print(f"File saved as: {save_file}")
