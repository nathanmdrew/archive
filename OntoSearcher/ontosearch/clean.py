#!/usr/bin/env python

"""
CLEAN.PY is a script containing all the functions that remove,
modify, or otherwise edit the lists of strings derived from
CSV input
"""

import re


def termsorter(termlist):
    """
    - remove leading and trailing spaces
    - lowercase
    - unique list from a set operation
    - sorted alphabetically
    - make a string
    """
    lowterms = []
    for term in termlist:
        lowterms.append((str(term).lower()).strip())
    return sorted(list(set(lowterms)))


def num_clean(termlist):
    """
    removes all pure numeric strings, + or -
    """
    termclean = [term for term in termlist
                 if re.match('^-[0-9.-]|^[0-9.-]*$', term)
                 is None]
    return termclean


def doi_clean(termlist):
    """
    function to remove as many DOIs as possible
    in a list of strings
    """
    termclean = termlist[:]
    for term in termlist:
        if re.search(r'(10.(\d)+/(\S)+)', term):
            termclean.remove(term)
    return termclean


def unit_clean(termlist):
    """
    function to remove all numerical range units notation from termlist
    percent, nanometers, grams, etc.
    """
    termclean = termlist[:]

    for term in termlist:
        if re.search('^<?>? ?[0-9.]+-[0-9.]+ percent', term):
            termclean.remove(term)
    # similar but ranges of any unit ending in meters
    for term in termlist:
        if re.search('^<?>? ?[0-9]+-[0-9]+ .*meter', term):
            termclean.remove(term)
    # and with grams
    for term in termlist:
        if re.search('^<?>? ?[0-9]+-[0-9]+ .*grams', term):
            termclean.remove(term)
    # and with hours
    for term in termlist:
        if re.search('^<?>? ?[0-9]+-[0-9]+ .*hours', term):
            termclean.remove(term)
    return termclean


def alphanums_clean(termlist):
    """
    clean out meaningless alphanumeric codes.
    specific requirements: 1-2 numbers, 1-2 letters, 1-3 numbers
    """
    termclean = termlist[:]

    for term in termlist:
        if re.search('^[0-9]{1,2}[a-z]{1,2}[0-9]{1,3}', term):
            termclean.remove(term)
    return termclean


def longnums_clean(termlist):
    termclean = termlist[:]

    for term in termlist:
        if re.search(r"\d{7}", term):
            termclean.remove(term)
    return termclean


def longtext_clean(termlist):
    """
    removes any temr containing greater than 120 characters

    note: concern over long chemical names?
    """
    termclean = termlist[:]

    for term in termlist:
        if len(term) > 120:
            termclean.remove(term)
    return termclean


def scinot_clean(termlist):
    """
    function to remove all scientific notation strings
    """
    termclean = termlist[:]

    for term in termlist:
        if re.search(r'^10\^', term):
            termclean.remove(term)
    return termclean


def leadzero_clean(termlist):
    """
    function to remove all terms with leading zeros
    """
    termclean = termlist[:]

    for term in termlist:
        if re.search('^0', term):
            termclean.remove(term)
    return termsorter(termclean)


def allclean(termlist):
    termlist = alphanums_clean(leadzero_clean(doi_clean(
                unit_clean(scinot_clean(longnums_clean(
                    num_clean(longtext_clean(
                        termlist))))))))
    return termlist
