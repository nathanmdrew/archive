# Databricks notebook source
# MAGIC %md
# MAGIC ## BERTopic Customization

# COMMAND ----------

# MAGIC %md
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

# MAGIC %md
# MAGIC #### Stopwords
# MAGIC
# MAGIC In some of the topics, we can see stop words appearing like he or the.
# MAGIC Stop words are something we typically want to prevent in our topic representations as they do not give additional information to the topic. To prevent those stop words, we can use the stop_words parameter in the CountVectorizer to remove them from the representations:
# MAGIC
# MAGIC Code for defining the stop words for the dog importation example is below:

# COMMAND ----------

stopwords = nltk.corpus.stopwords.words('english')  # Stopwords are used after clustering

# COMMAND ----------

# MAGIC %md
# MAGIC This code imports a generic list of stop words for the English language provided by the natural language toolkit.
# MAGIC
# MAGIC Read more:
# MAGIC
# MAGIC [Python Tutorials: NLTK stop words](https://pythonspot.com/nltk-stop-words/)
# MAGIC
# MAGIC [Tips for Constructing Custom Stop Word Lists](https://kavita-ganesan.com/tips-for-constructing-custom-stop-word-lists/)
# MAGIC
# MAGIC [tf–idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)

# COMMAND ----------

newStopWords = ['cdc', 'rabies', 'vaccination', 'vaccine', 'regulation',
                'vaccinated', 'canine', 'dog', 'importation', 'pet', 'cat',
                'proposed', 'require', 'requirement', 'policy', 'importation',
                'imported', 'rule', 'importing', 'u',
                'law', 'animal', 'ruling', 'wa', 'across', 'already',
                'proposal', 'nprm', 'pas', 'dont', 'v', 'thus',
                'non', 'ha', 'would', 'need', 'others', 'ever', 'doe', 'many', 'united', 'state',
                '1' , '3', '2', '6', 'may', 'one', 'must', 'well', 'please',
                'thing', 'like', 'attached', 'moron', 'anyone', 'also',
                'every', 'without', 'way', 'via', 'really', 'able', '16', 'everyone',
                'sense', 'alright', 'redctaoecalliw', 'fetsko', 'beyond']
stopwords.extend(newStopWords)  # Extend stopwords list with new stopwords

# COMMAND ----------

# MAGIC %md
# MAGIC [BERTopics FAQ](https://maartengr.github.io/BERTopic/faq)

# COMMAND ----------

# MAGIC %md
# MAGIC #### Embedding Batch Size
# MAGIC embedding_batch_size
# MAGIC
# MAGIC Definition: Specifies the size of batches in which documents are passed to the embedding model.
# MAGIC Purpose: Balances memory consumption and computational efficiency during the embedding generation.
# MAGIC Default Behavior: If not set, BERTopic uses a default batch size (typically 32).
# MAGIC Impact on Embedding Generation
# MAGIC Memory Usage:
# MAGIC
# MAGIC Higher Batch Sizes:
# MAGIC Increased memory consumption, faster processing
# MAGIC
# MAGIC Lower Batch Sizes:
# MAGIC Decreased memory consumption, slower Processing

# COMMAND ----------

# MAGIC %md
# MAGIC #### Seed Topics
# MAGIC seed_topics
# MAGIC
# MAGIC _Purpose of Seed Topics_
# MAGIC
# MAGIC - Guidance: Seed topics help steer the model to focus on particular areas of interest, ensuring that these topics are identified and well-represented in the results.
# MAGIC - Incorporate Domain Knowledge: By providing seed words, you leverage your expertise or prior understanding of the data to improve the quality and relevance of the topics generated.
# MAGIC - Improve Interpretability: Seed topics can enhance the clarity and meaningfulness of the topics by aligning them with known concepts or categories.
# MAGIC
# MAGIC _How Seed Topics Work in BERTopic_
# MAGIC
# MAGIC When you specify a seed_topic_list, BERTopic uses these seed words during the clustering process:
# MAGIC
# MAGIC - Initialization: The seed words are used to initialize clusters in the HDBSCAN clustering algorithm.
# MAGIC - Document Assignment: Documents containing the seed words are more likely to be assigned to the corresponding seed topics.
# MAGIC - Topic Representation: The seed words influence the selection of top words for each topic, making them appear prominently in the topic descriptions.
# MAGIC
# MAGIC _Considerations When Using Seed Topics_
# MAGIC
# MAGIC - Choose words that are representative and distinctive of the topics you want to model.
# MAGIC - Ensure the seed words are relevant to the content of your documents.
# MAGIC - While seed topics can improve focus, over-specifying them might limit the model's ability to discover new or unexpected topics.
# MAGIC - Aim for a balance that allows the model to explore the data while being guided by your specified topics.
# MAGIC - Ensure that the seed topics cover the main areas of interest without overwhelming the model.
# MAGIC - Avoid adding too many seed topics, which might dilute their effectiveness.
# MAGIC
# MAGIC _Benefits of Using Seed Topics_
# MAGIC
# MAGIC - Customization: Tailor the topic modeling process to focus on specific areas relevant to your analysis.
# MAGIC - Improved Coherence: Seed topics can enhance the coherence of topics by anchoring them with meaningful seed words.
# MAGIC - Domain-Specific Insights: Allows for the extraction of topics that are particularly pertinent to your field or area of study.
# MAGIC
# MAGIC _Limitations_
# MAGIC
# MAGIC - Potential Bias: Seed topics may introduce bias, causing the model to overlook other significant topics present in the data.
# MAGIC - Dependence on Seed Words: The effectiveness of seed topics depends on the quality and representativeness of the chosen seed words.
# MAGIC - Overfitting: There's a risk that the model might overfit to the seed topics, reducing its generalization capabilities.
# MAGIC
# MAGIC _Best Practices_
# MAGIC
# MAGIC - Careful Selection: Spend time selecting seed words that are both specific and broadly representative of the topics.
# MAGIC - Testing and Validation: Experiment with and without seed topics to evaluate their impact on the results.
# MAGIC - Monitor Model Output: Analyze the topics generated to ensure that the inclusion of seed topics leads to meaningful improvements.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC #### Calculate Topic Coherence
# MAGIC To calculate topic coherence, you need the following inputs:
# MAGIC
# MAGIC ##### Dictionary
# MAGIC
# MAGIC Gives unique ID to each lemmatized token; universal accross different model i.e., not model-specific.
# MAGIC
# MAGIC ##### Corpus
# MAGIC List of lists of tuples of (token_id, token_count for a given topic); counts lemmatized tokens accross all documents in each topic. Converts each document into the bag-of-words (BoW) format and produces tuples for each topic. For instance, a token with id 0 may appear in each topic and will be shown in multiples tuples in different lists as (0, 4); (0;18); (0;25) if observed 4;8;25 times in each topic respectively.
# MAGIC
# MAGIC ##### Texts
# MAGIC
# MAGIC List of lists where each list incorporates all (not unique but lemmatized) tokens for each topic; needed for coherence models that use sliding window based probability estimator; varies for each model solution.
# MAGIC
# MAGIC ##### Topics
# MAGIC
# MAGIC List of lists of unique lemmatized top tokens for each topic; note that these are taken from BERTopic from the list of most representative tokens for each topic; if you want to have more tokens as inputs for coherence calculation, you need to increase the parameter top_n_words in Bertopic function. This input will vary for each model solution. Note the substraction of 1; it has been done to drop representative words for topic labeled as '-1' as it conceptually does not represent a topic and it is an outlier group of documents & their respective words.
# MAGIC
# MAGIC ##### Coherence
# MAGIC
# MAGIC Type of coherence such as: 'c_v'; 'u_mass','c_uci', 'c_npmi'. See link to the paper below for more details about each coherence measure. C_V seems like a promising measure due to its correlation with human annotations (see original paper below of topic coherences by Roder)
# MAGIC
# MAGIC ##### Other Notes
# MAGIC
# MAGIC General intuition: topics input is checked against dictionary and corpus.
# MAGIC Note that vectorizer is used directly from bertopic model to create dictionary; corpus, tokens
# MAGIC Coherence is a proxy for a topic model's performance; it is not a ground truth. It is important to look at the topics and see if they make sense.
# MAGIC Link to code sources to calculate coherence, suggested by BERTopic developer
# MAGIC
# MAGIC Link to paper that explains different types of coherences

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Human Judgement Steps: Check Vaious Models of Interest
# MAGIC
# MAGIC Visual Exploration of Model(s) of Interest: Plots of Most Representative Words
# MAGIC
# MAGIC First, you can check most representative words for each topic solution.
# MAGIC * need to channge numerical value in **get_model** function when creating variable **interest_model_info**
# MAGIC * note that you may need to adjust **top_n_topics=50** to see a higher number of topics if needed
# MAGIC * note that the N of topics returned in the barchart will include **n-1** topics (e.g., 9 instead of 10) as it drops the topic with outliers

# COMMAND ----------

# MAGIC %md
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC