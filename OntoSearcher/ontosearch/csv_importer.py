#!/usr/bin/env python

"""
CSV_IMPORTER.PY conains functions to import and format CSV data
"""

import errno
import os

import pandas as pd


def load_data(path):
    '''
    Accepts file path of single table or directory containing multiple tables.

    Directories must contain only

    Parameters:
        path(str): Path to file or directory containing csv-like data

    Returns:
        tables(dict): Dictionary of tables of columns of terms
          {table_name: {column_name: [terms]}, ... }
    '''

    path = os.path.abspath(path)
    tables = {}

    if not os.path.exists(path):
        raise FileNotFoundError(
          errno.ENOENT, os.strerror(errno.ENOENT), path
          )

    if os.path.isfile(path):
        table_name = os.path.basename(path).split('.')[0]
        # table_terms = load_table(path)
        tables = {table_name: load_table(path)}

    elif os.path.isdir(path):
        _, _, files = next(os.walk(path))

        for file in files:
            table_name = file.split('.')[0]
            tables[table_name] = load_table(os.path.join(path, file))

    return tables


def load_table(file):
    '''
        Takes file path and returns dictionary
    Some logging that might be nice
    shape = table_df.shape
    print(f"Reading Table {os.path.basename(file)}"
           "with {shape[0]} terms and {shape[1]} columns")

    '''
    return pd.read_csv(file).to_dict(orient='list')
