#!/usr/bin/env python

""" ONTO.PY defines functions that import or manipulate ontology data
in practice it is the set of functions needed to produce the final
ontoTerms object- a dictionary of ontology file names, with a list
of entity labels and IRIs from each ontology"""

import os
import errno
from owlready2 import World
import rdflib
from rdflib import URIRef, Graph
from time import perf_counter


def ontoprep(onto_data):
    """
    function to take list of rdflib.URI and rdflib.Literal and return
    sorted list of tuples of unique (literals, rdflib.URI)

    Parameters:
        onto_data(ls): list of tuples of format (term(str), IRI(str))

    Returns:
        onto_prepped(ls): alphabetically sorted list of lowercase strings
                          with no duplicates
    """

    for i in range(len(onto_data)):
        onto_data[i] = list(onto_data[i])
        for iri in range(len(onto_data[i])):
            if iri != 'None':
                if type(onto_data[i][iri]) == rdflib.term.URIRef:
                    onto_data[i][iri] = onto_data[i][iri].toPython()
                if type(onto_data[i][iri]) == rdflib.term.Literal:
                    onto_data[i][iri] = onto_data[i][iri].toPython().lower()
                else:
                    onto_data[i][iri] = onto_data[i][iri]
                    # sorted(list(set(onto_data)))
    return onto_data


def ontograb(onto_path, mode='label'):
    """
    this function reads an OWL file and executes a SPARQL query
    based on any common label/title/synonym style predicates it
    has. Using python os module to normalize file paths

    Parameters:
        onto_file(str): the path to an ontology OWL file
                        or the IRI(url) for an OWL file
    Returns:
        owlTerms(list): a sorted list of all of the terms and their
                        IRIs retrieved from the SPARQL Query of the
                        OWL file
    """
    t0 = perf_counter()

    world = World()

    onto_file = os.path.abspath(onto_path)

    if not os.path.exists(onto_file):
        raise FileNotFoundError(
          errno.ENOENT, os.strerror(errno.ENOENT), onto_file
          )

    if os.path.isfile(onto_file):
        if 'http' in onto_file:
            onto = world.get_ontology(onto_file)
            onto.load()
            graph = world.as_rdflib_graph()
            # JS: use os.path().join() instead!!!!
        elif '.ttl' in onto_file:
            graph = Graph()
            graph.parse(onto_file, format="turtle")
        else:
            owlfile = onto_file
            onto = world.get_ontology(owlfile)
            onto.load()
            graph = world.as_rdflib_graph()

        print(f'RUN: {onto_file}')

        # empty list to add query results into
        owlTerms = []

        # predicates
        if mode == 'context':
            rdfs_subclass = URIRef('http://www.w3.org/2000/01/'
                                   'rdf-schema#subClassOf')
            rdfs_subprop = URIRef('http://www.w3.org/2000/01/'
                                  'rdf-schema#subPropertyOf')

            preds = [rdfs_subclass, rdfs_subprop]

        else:
            rdfslabs = URIRef('http://www.w3.org/2000/01/'
                              'rdf-schema#label')
            oboexact = URIRef('http://www.geneontology.org/formats/'
                              'oboInOwl#hasExactSynonym')
            oborelated = URIRef('http://www.geneontology.org/formats/'
                                'oboInOwl#hasRelatedSynonym')
            obobroad = URIRef('http://www.geneontology.org/formats/'
                              'oboInOwl#hasBroadSynonym')
            ncitp90 = URIRef('http://ncicb.nci.nih.gov/xml/owl/EVS/'
                             'Thesaurus.owl#P90')
            npopref = URIRef('http://purl.bioontology.org/ontology/'
                             'npo#preferred_Name')
            skosmatch = URIRef('http://www.w3.org/2004/02/skos/'
                               'core#exactMatch')
            skosalt = URIRef('http://www.w3.org/2004/02/skos/core#'
                             'altLabel')
            skospref = URIRef('http://www.w3.org/2004/02/skos/core#'
                              'prefLabel')
            dctitle = URIRef('http://purl.org/dc/elements/1.1/title')

            meosyn = URIRef('http://purl.jp/bio/11/meo/hasExactSynonym')

            preds = [rdfslabs, oboexact, oborelated, obobroad, ncitp90,
                     npopref, dctitle, skosmatch, skosalt, skospref, meosyn]

        # checking the graph for different predicate types
        # that suit our purpose- rdfs:label, and the different obo:Synonyms
        for predicate in preds:
            if (None, predicate, None) in graph:
                labTerms = list(graph.query("""
                    SELECT DISTINCT ?s ?o WHERE {{

                    ?s <{0}> ?o

                    }}""".format(predicate.toPython())))

                queryTerms = []
                for item in labTerms:
                    triple = list(item)
                    triple.append(predicate.toPython())
                    queryTerms.append(triple)

                owlTerms = owlTerms + queryTerms
            else:
                print(f"{predicate} not present in {onto_file}")

        t1 = perf_counter()

        print(
                f'  TIME ELAPSED: {t1-t0}s'
                )
        return ontoprep(owlTerms)


def ontocontext(onto_path):
    """
    this function reads an OWL file and executes a SPARQL query
    based on any common label/title/synonym style predicates it
    has, and will also retrieve all superclass term/IRI data.

    os module for path normalization.

    Parameters:
        onto_file(str): the path to an ontology OWL file
                        or the IRI(url) for an OWL file
    Returns:
        owlTerms(list): a sorted list of all of the terms and their
                        IRIs retrieved from the SPARQL Query of the
                        OWL file
    """
    t0 = perf_counter()

    onto_file = os.path.abspath(onto_path)

    if not os.path.exists(onto_file):
        raise FileNotFoundError(
          errno.ENOENT, os.strerror(errno.ENOENT), onto_file
          )

    if os.path.isfile(onto_file):

        world = World()

        if 'http' in onto_file:
            onto = world.get_ontology(onto_file)
            onto.load()
            graph = world.as_rdflib_graph()
            # JS: use os.path().join() instead!!!!
        elif '.ttl' in onto_file:
            graph = Graph()
            graph.parse(onto_file, format="turtle")
        else:
            owlfile = onto_file
            onto = world.get_ontology(owlfile)
            onto.load()
            graph = world.as_rdflib_graph()

        print(f'RUN: {onto_file}')

        # predicates

        rdfslabs = URIRef('http://www.w3.org/2000/01/'
                          'rdf-schema#label')
        oboexact = URIRef('http://www.geneontology.org/formats/'
                          'oboInOwl#hasExactSynonym')
        oborelated = URIRef('http://www.geneontology.org/formats/'
                            'oboInOwl#hasRelatedSynonym')
        obobroad = URIRef('http://www.geneontology.org/formats/'
                          'oboInOwl#hasBroadSynonym')
        ncitp90 = URIRef('http://ncicb.nci.nih.gov/xml/owl/EVS/'
                         'Thesaurus.owl#P90')
        npopref = URIRef('http://purl.bioontology.org/ontology/'
                         'npo#preferred_Name')
        skosmatch = URIRef('http://www.w3.org/2004/02/skos/'
                           'core#exactMatch')
        skosalt = URIRef('http://www.w3.org/2004/02/skos/core#'
                         'altLabel')
        skospref = URIRef('http://www.w3.org/2004/02/skos/core#'
                          'prefLabel')
        dctitle = URIRef('http://purl.org/dc/elements/1.1/title')

        meosyn = URIRef('http://purl.jp/bio/11/meo/hasExactSynonym')

        preds = [rdfslabs, oboexact, oborelated, obobroad, ncitp90, npopref,
                 dctitle, skosmatch, skosalt, skospref, meosyn]

        # checking the graph for different predicate types
        # that suit our purpose- rdfs:label, and the different obo:Synonyms
        queryTerms = []

        for predicate in preds:
            if (None, predicate, None) in graph:
                result = list(graph.query("""
                                SELECT DISTINCT ?s ?o ?osc ?osc_lab WHERE {{

                                ?s <{0}> ?o

                                OPTIONAL{{?s rdfs:subClassOf ?osc.
                                          ?osc <{0}> ?osc_lab}}
                                }}""".format(predicate.toPython())))
                for index in range(len(result)):
                    result[index] = list(result[index])
                    result[index].append(predicate)

                queryTerms.extend(result)

            else:
                print(f"{predicate} not present in {onto_file}")

        t1 = perf_counter()

        print(
                f'  TIME ELAPSED: {t1-t0}s'
                )
        return ontoprep(queryTerms)


def ontolister(ontofunc=ontograb, onto_dir=[], onto_iris=[], order=[]):
    """
    this functions accepts a directory of local OWL files and/or a list of
    online OWL files, and then runs custom SPARQL queries on them to retrieve
    all string literals associated with label/title/synonym and similar
    predicates (using the ontograb function). os module for path normalization.

    Parameters:
        onto_func(func): ontograb for just label SPARQL query, and ontocontext
                        for label and superclass query
        onto_dir (str): path to local directory of OWL files (optional),
                        default is list so if no input, it fails
                        an if conditional
        onto_iris (ls): list of IRIs (urls) of ontologies
        order (ls): optional list of ontology file names to set desired
                run order (lowest to highest priority)

    Returns:
        ontoTerms(dict) of format {ontology: [terms, IRI]}
    """
    time_start = perf_counter()

    ontologies = []

    if onto_dir:
        onto_file = os.path.abspath(onto_dir)

        if not os.path.exists(onto_file):
            raise FileNotFoundError(
              errno.ENOENT, os.strerror(errno.ENOENT), onto_file
              )

        if os.path.isdir(onto_file):
            for _, _, files in os.walk(onto_dir):
                ontologies = files

    if order:
        for priority in order:
            if priority in ontologies:
                ontologies.pop(ontologies.index(priority))
                ontologies.insert(0, priority)
            if priority in onto_iris:
                onto_iris.pop(onto_iris.index(priority))
                onto_iris.insert(0, priority)

    ontoTerms = {}

    for ontology in ontologies:
        t0 = perf_counter()
        ontoTerms[ontology] = ontofunc((onto_dir + ontology))
        t1 = perf_counter()
        print(f"\n{ontology} load time: {t1-t0}\n")

    for ontology in onto_iris:
        t0 = perf_counter()
        ontoTerms[ontology] = ontofunc(ontology)
        t1 = perf_counter()
        print(f"\n{ontology} load time: {t1-t0}\n")

    time_end = perf_counter()
    print(
        f'Ontologies in Dictionary (keys): {ontoTerms.keys()}'
        f'TOTAL TIME: {time_end - time_start}'
        )

    return ontoTerms
