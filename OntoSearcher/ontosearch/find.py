#!/usr/bin/env python

"""
FIND.PY contains all search algorithm definitions,
the 'find' functions which deploy them,
and the matcher functions which deploy those
"""

from rapidfuzz import process
from rapidfuzz.fuzz import ratio
from ontosearch.clean import allclean, termsorter
from time import perf_counter

# SEARCH ALGORITHMS


def exact_binary(xs, target):
    """
    Find and return the index and item that
    matches target in sequence xs

    Parameters:
        xs(ls): list of terms(str) to search against
        target(str): term to look for in xs

    Returns:
        item_at_mid(str): term match
        100(int): value representing the levenshteind
                  distance number, which is always 100
                  for exact matches
    """
    lb = 0
    ub = len(xs)
    while True:
        if lb == ub:   # means entire list searched without match
            return -1, -1
        # split list in half each cycle
        mid_index = (lb + ub) // 2
        # examine item at middle position
        item_at_mid = xs[mid_index]
        # compare this item to target string
        if item_at_mid == target:
            # if item_at_mid in target:
            return item_at_mid, 100
        # if not a match, adjust window according to sort order
        if item_at_mid < target:
            lb = mid_index + 1
        else:
            ub = mid_index


def fuzz_linear(xs, target, threshold=90, fuzzmode='ratio'):
    """
    Find all fuzzy matches above threshold,
    and return best match. Linear search.

    Parameters:
        xs(ls): list of terms to search against
        target(str): term to search xs for
        threshold(int): LVD value above which two terms
                        are considered a match
        fuzzmode(str): mode of fuzzy matching, 'ratio' which
                       is an unodified LVD calculation, 'partial ratio'
                       which splits calculations across words in a string
                       and  'WRatio', which runs all LVD-style calcs and
                       returns highest value
    Returns:
        term(str): matched term
        lvd(int): LVD score
    """
    if fuzzmode == 'WRatio':
        match = process.extractOne(
            target, xs, score_cutoff=threshold
            )
    else:
        match = process.extractOne(
            target, xs, scorer=ratio, score_cutoff=threshold
            )
    if match is not None:
        term, lvd, index = match
        return term, lvd
    else:
        return -1, -1

# FINDER


def find(onto_dict, sql_dict, search_algo,
         context=False, res={}, mode='',
         threshold=90, printing=False):
    """
    Parameters:
        onto_dict(dict): ontology dictionary of format
                        {'ontology.file': ('term', 'IRI')}
        sql_dict(dict): term ditionary of format
                        {'tbl':'col': ('term')}
        search_algo(str): search algorithm to employ,
                          options are 'exact_binary'
                          and 'fuzzy'
        context(bool): True retrieves superclass data,
                       from ontology dict False does not
        threshold(int): LVD threshold to use if fuzzy searching
        printing(bool): determines if matching readout
                        should print or not
    Returns:
        result(dict): dictionary of terms and matched IRIs,
                      with table and column information presrved
                      {'owl.file': 'tbl': 'col':
                        [term, termiri, csvterm, col, tbl, lvd]}
        unmatched(dict): dictionary of unmatched terms
                         same structure as sql_dict
    """
    result = res
    unmatched = {}

    match_count = 0
    unmatched_count = 0

    for tbl in sql_dict.keys():
        tbl_ls = []
        tbl_ls.append(str(tbl))

        for column in sql_dict[tbl]:
            left = sql_dict[tbl][column]

            if tbl not in tbl_ls:
                left.append(str(tbl))
            left.append(str(column))
            left = allclean(termsorter(left))
            start_len = len(left)

            print(f'\nnumber unmatched terms in {column}: {start_len}\n')

            ontologies = onto_dict.keys()

            if left:
                for ontology in ontologies:
                    matches = []
                    if context is False:
                        for iri, label, predicate in onto_dict[ontology]:
                            if mode == '':
                                match, lvd = search_algo(left, label)
                            else:
                                match, lvd = search_algo(left, label,
                                                         threshold, mode)
                            if match != -1:
                                matches.append([label, iri, predicate,
                                                match, lvd, tbl, column])
                                match_count += 1
                                try:
                                    left.remove(match)
                                except Exception:
                                    print(f"Error: term '{match}' "
                                          "not removed succesfully")
                                    continue
                    else:
                        for iri, lbl, ciri, clbl, pred in onto_dict[ontology]:
                            if mode == '':
                                match, lvd = search_algo(left, lbl)
                            else:
                                match, lvd = search_algo(left, lbl,
                                                         threshold, mode)
                            if match != -1:
                                matches.append([lbl, iri, pred,
                                                clbl, ciri, match,
                                                lvd, tbl, column])
                                match_count += 1
                                try:
                                    left.remove(match)
                                except Exception:
                                    print(f"Error: term '{match}' "
                                          "not removed succesfully")
                                    continue

                    if tbl in unmatched.keys():
                        if column in unmatched[tbl].keys():
                            unmatched[tbl][column] = left
                        else:
                            unmatched[tbl][column] = left
                    else:
                        unmatched[tbl] = {column: left}

                    print(f"RUN: {ontology} |"
                          f" {search_algo.__name__+' '+ mode}\n"
                          f"matches: {len(matches)}")

                    if threshold:
                        print(f"threshold value: {threshold}")

                    if ontology in result.keys():
                        if search_algo.__name__ in result[ontology].keys():
                            if tbl in (result[ontology]
                                       [search_algo.__name__]).keys():
                                (result[ontology]
                                    [search_algo.__name__ + mode]
                                    [tbl].update({column: matches}))
                            else:
                                (result[ontology]
                                    [search_algo.__name__ + mode][tbl]) = {
                                        column: matches}
                        else:
                            result[ontology][search_algo.__name__ + mode] = ({
                                tbl: {column: matches}})
                    else:
                        result[ontology] = (
                            {
                                search_algo.__name__ + mode: {
                                    tbl: {column: matches}
                                }
                            })

    for tbl in unmatched.keys():
        for key in unmatched[tbl].keys():
            for item in unmatched[tbl][key]:
                unmatched_count += 1

        if printing is True:
            print('________________________\n')
            print(f"number starting term: {start_len}")
            print(f"number unmatched terms: {unmatched_count}")
            print(f"number matched terms: {match_count}")
    print("\n\n---------------------")
    print(f"FINAL MATCHER OUTPUT\n"
          f"    unmatched:{unmatched_count}"
          f"    matched:{match_count}")
    print("---------------------\n\n")

    return result, unmatched

# MATCHER


def matcher(onto_dict, sql_dict, mode='em', context=False, printing=False):
    """
    automation of matching process

    Parameters:
        onto_dict(dict): ontology dictionary of format
                        {'ontology.file': ('term', 'IRI')}
        sql_dict(dict): term ditionary of format
                        {'tbl':'col': ('term')}
        mode(str): search algorithm to employ, options are
                          'em' and anything else is 'fuzzy'
        context(bool): True retrieves superclass data,
                       from ontology dict False does not
        printing(bool): determines if matching readout
                        should print or not

    Returns:
        product(dict): dictionary of terms and matched IRIs,
                      with table and column information presrved
                      {'owl.file': 'tbl': 'col':
                        [term, termiri, csvterm, col, tbl, lvd]}
        unmatched(dict): dictionary of unmatched terms
                         same structure as sql_dict
    """
    # start the timer for the whole search
    t0 = perf_counter()
    # results dictionary
    product = []

    # run a binary search for exact matches
    matches, unmatched = find(onto_dict,
                              sql_dict,
                              exact_binary,
                              context)
    product.append(matches)

    # fuzzy matching
    if mode != 'em':
        matches, unmatched = find(onto_dict, unmatched, fuzz_linear, context,
                                  mode='ratio', threshold=70)
        product.append(matches)

    # fuzz.Wratiocolumns
    # matches, unmatched = find(onto_ls, unmatched, fuzz_linear,
    #                           mode='Wratio', threshold=90)
    # product.update(matches)

    t1 = perf_counter()

    if printing is True:
        print(
            f"\nTotal search time: {t1-t0}\n"
            # f"Total matches: {len(matches)}\n"
            # f"Total unmatched: {len(unmatched)}"
            )

    return product, unmatched
