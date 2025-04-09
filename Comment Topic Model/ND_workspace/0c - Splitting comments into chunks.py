# Databricks notebook source
# MAGIC %md
# MAGIC Import necessary libraries

# COMMAND ----------

import os
import numpy as np
import pandas as pd
pd.set_option('display.max_colwidth', None)  # Shows full text
import re

# COMMAND ----------

# MAGIC %md
# MAGIC Import the comments file, which includes the PDF extractions

# COMMAND ----------

# read in the original csv bulk download into a pandas dataframe
df = pd.read_csv('/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfsh_rfi_original_comments_withExtractedText.csv')

df.head(1)