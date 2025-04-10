#!/usr/bin/env python

"""
ONTO_API.py is a script that handles calls to the BioAnnotator API
taking a list of terms as input and returning a reccomendation of the
most fitting ontologies.
"""

import requests
from time import perf_counter
from random import sample
from ontosearch.clean import termsorter


def dict_samp(onto_dict):
    """
    takes a random sample of 1/10 of the terms
    in each column of the results dictionary,
    unless it is less than ten terms, in which
    case just 1 sample, and more than 40 terms,
    in which case 4. it isn't elegant but returns
    reasonable results

    Parameters:
        onto_dict(dict): makes a random sample of terms
                         from the unmatched terms structure

    Returns:
        sample_list(ls): list of randomly sampled terms(str)
    """
    sample_ls = []
    for owl in onto_dict.keys():
        for column in onto_dict[owl]:
            list_len = len(onto_dict[owl][column])

            if list_len > 0:
                if list_len/10 >= 1 and list_len < 40:
                    sample_size = round(list_len/10)
                elif list_len >= 40:
                    sample_size = 4
                else:
                    sample_size = 1
                col_sample = sample(onto_dict[owl][column], sample_size)
                sample_ls.extend(col_sample)
            else:
                pass
    sample_list = [str(item) for item in sample_ls
                   if str(item).lower() != 'nan'
                   and str(item).lower() != 'na'
                   and type(item) is not int]

    sample_list = list(set(sample_list))
    if len(sample_list) > 20:
        sample_list = sample(sample_list, 20)
    return sample_list


def bioportal_sample(terms_sample, API_KEY, em=False):
    """
    this function makes a call to the BioPortal API /search using a random
    sample of the list of terms submitted

    Parameters:
        terms_sample(ls): list of terms(str)
        APIKEY(str): unique APIKEY user must recieve by creating
                     bioportal account. Once created, API KEY will
                     be listed on users account info page
                     link: https://bioportal.bioontology.org/accounts/new
        em(bool): True means bioportal exact match search, false
                 means not exact match search

    Returns:
        results_dict(dict): dictioanry of term results from the bioportal API

    """
    t0 = perf_counter()
    terms = terms_sample

    results_dict = {}

    for term in terms:
        params = dict(
                      apikey=API_KEY,
                      q=term
                      )

        if em is True:
            params = dict(
                          apikey=API_KEY,
                          q=term,
                          require_exact_match="true"
                          )

        req_url = ("http://data.bioontology.org/search")
        response = requests.get(req_url, params=params)
        collection = response.json()['collection']
        results_dict[term] = collection

    t1 = perf_counter()
    print(f"time elapsed: {t1-t0}")

    return results_dict


def bio_summary(bio_results, mode='top'):
    """
    this function accepts bioportal results and returns a printout of
    summary statistics on hits by ontology

    Parameters:
        bio_results(dict): dictionary of bioportal search results for terms
        mode(str): 'top' prints just top 5 ontologies, in orde with counts.
                    otherwise, every ontology with a hit is printed nect to
                    its total hit count

    Returns:
        results_dict(dict): dictioanry of term results from the bioportal API

    """

    summary = {}

    for bp_key in bio_results.keys():
        if mode == 'top':
            if bio_results[bp_key]:
                tophit = bio_results[bp_key][0]
                if tophit['links']['ontology'] not in summary.keys():
                    summary[tophit['links']['ontology']] = 1
                else:
                    summary[tophit['links']['ontology']] += 1

        else:
            for bp_dict in bio_results[bp_key]:
                print(bp_dict)
                if bio_results[bp_key]:
                    if bp_dict['links']['ontology'] not in summary.keys():
                        summary[bp_dict['links']['ontology']] = 1
                else:
                    summary[bp_dict['links']['ontology']] += 1

    summary = sorted(
                    list(
                        summary.items()), key=lambda key: key[1], reverse=True)

    summary = {ele[0]: ele[1] for ele in summary}

    return summary


def bioportal_search(terms_dict, API_KEY, em=False, mode='all', num_hits=1):
    """
    this function makes a call to the BioPortal API /search using a random
    sample of the list of terms submitted

    Parameters:
        terms_dict(dict): dictionary of terms to serch bioportal with
        APIKEY(str): unique APIKEY user must recieve by creating
                     bioportal account
        em(bool): True means bioportal exact match search, false
                 means not exact match search
        mode(str): 'all' means every single term is searched in bioportal API
        num_hits(int): this number determines the amount of bioportal search
                       hits are reported

    Returns:
        results_dict(dict): dictionary of term results from the bioportal API

    """
    t0 = perf_counter()
    terms = []
    if mode == 'all':
        for tbl in terms_dict.keys():
            for key in terms_dict[tbl].keys():
                terms.append(key)
                # eliminating same label with dif IRI and parents?
                terms_dict[tbl][key] = termsorter(terms_dict[tbl][key])

                for item in terms_dict[tbl][key]:
                    terms.append(item)
    elif mode == 'col':
        print("Running search in column mode")
        for tbl in terms_dict.keys():
            for key in terms_dict[tbl].keys():
                terms.append(str(key))
    else:
        print("Error: either do not input mode,"
              " or input valid modes, 'all' or 'col'")

    results_dict = {}

    for term in terms:
        params = dict(
                      apikey=API_KEY,
                      q=term
                      )

        if em is True:
            params = dict(
                          apikey=API_KEY,
                          q=term,
                          require_exact_match="true"
                          )

        req_url = ("http://data.bioontology.org/search")
        response = requests.get(req_url, params=params)
        results_dict[term] = []
        collection = response.json()['collection']

        if len(collection) < num_hits:
            for i in range(len(collection)-1):
                results_dict[term].append([term,
                                          collection[i]['@id'],
                                          collection[i]['links']['ontology'],
                                          collection[i]['links']['parents']]
                                          )
        else:
            for i in range(0, num_hits):
                results_dict[term].append([term,
                                          collection[i]['@id'],
                                          collection[i]['links']['ontology'],
                                          collection[i]['links']['parents']]
                                          )

    t1 = perf_counter()
    print(f"time elapsed: {t1-t0}")

    return results_dict


def unpack_superclass(bp_results, api_key):
    """
    function to accept bioportal results and call to BioAPI again to retrieve
    the superclass information for each term, label and IRI

    for example, user sends ('pencil','example.com/pencil')
    recieves: [('pencil','example.com/writing/pencil',
                'writing utensils', 'example.org/writing')]

    Parameters:
        bp_results(dict): dictioanry of term results from the bioportal API
        APIKEY(str): unique APIKEY user must recieve by creating
                     bioportal account

    Returns:
        match_dict(dict): dictionary of term results from the bioportal API,
                          with superclass information
    """
    match_dict = {}

    for term_key in bp_results.keys():
        for index in range(len(bp_results[term_key])):
            try:
                url = bp_results[term_key][index][3]

                params = dict(
                              apikey=api_key,
                              )

                try:
                    response = requests.get(url, params)
                    data = response.json()
                    parent_info = []

                    try:
                        parent_info.append(data[0]['prefLabel'])
                    except Exception:
                        parent_info.append("no label")
                    try:
                        parent_info.append(data[0]['@id'])
                    except Exception:
                        parent_info.append("no label")
                    if term_key not in match_dict.keys():
                        match_dict[term_key] = []
                        match_dict[term_key].append(
                            [bp_results[term_key][index], parent_info]
                            )
                    else:
                        match_dict[term_key].append(
                            [bp_results[term_key][index], parent_info]
                            )

                except Exception:
                    print("couldn't connect this one")

            except Exception:
                print("no parent doc on this one")

    return match_dict


def bio_parse(bpmatches):
    """
    this function accepts a list of matches and prints all
    of the yet unmatched columns

    Parameters:
        bpmatches(dict): dictioanry of term matches from the bioportal API


    Returns:
        bpunmatched(dict): dictionary of unmatched terms from BioAPI
    """
    i = 0
    bp_unmatched = {}
    for key in bpmatches.keys():
        if bpmatches[key] == []:
            i += 1
            bp_unmatched.update({key: []})
    return bp_unmatched


def simple_search(terms, API_KEY, em=False, num_hits=1):
    """
    this function makes a call to the BioPortal API for a list of terms
    of any length

    Parameters:
        terms(ls): dictionary of terms to serch bioportal with
        APIKEY(str): unique APIKEY user must recieve by creating
                     bioportal account
        em(bool): True means bioportal exact match search, false
                 means not exact match search
        num_hits(int): this number determines the amount of bioportal search
                       hits are reported

    Returns:
        results_dict(dict): dictionary of term results from the bioportal API

    """

    terms = []

    results_dict = {}

    for term in terms:
        params = dict(
                      apikey=API_KEY,
                      q=term
                      )

        if em is True:
            params = dict(
                          apikey=API_KEY,
                          q=term,
                          require_exact_match="true"
                          )

        req_url = ("http://data.bioontology.org/search")
        response = requests.get(req_url, params=params)
        results_dict[term] = []
        collection = response.json()['collection']

        if len(collection) < num_hits:
            for i in range(len(collection)-1):
                results_dict[term].append([term,
                                          collection[i]['@id'],
                                          collection[i]['links']['ontology'],
                                          collection[i]['links']['parents']]
                                          )
        else:
            for i in range(0, num_hits):
                results_dict[term].append([term,
                                          collection[i]['@id'],
                                          collection[i]['links']['ontology'],
                                          collection[i]['links']['parents']]
                                          )
    return results_dict


# Future Dev Notes
    # - make a timer function (throttle) to limit BioAPI calls
    #   to under 15 hits / second
    # - make BioPortal search general function that is a more
    #   straightforward call to search single or small lists of terms
    #   (useful in column matching workflow)
    #   (attempt above: simple_search())
    # - sampling system inelegant and no mathmatical or theoretical
    #   basis, purely chosen by trial and error for sufficient results
    # - if possible, reporting ontology file size would be very useful
    #   as users should prioritize small ontologies over large ontologies
    #   where possible
