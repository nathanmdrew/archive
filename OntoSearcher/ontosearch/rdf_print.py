#!/usr/bin/env python

"""
RDF_PRINT.PY defines functions to print RDF using match data from OntoSearch
and relational structure from imported csv, as well as providing manual
curation functions
"""

import os
import errno
import pandas as pd
from rdflib import URIRef, Literal


# function to load CSV into pandas dataframe
def table_loader(tbl_path, printing=False):
    """
    this loads a csv file into a pandas dataframe

    Parameters:
        tbl_path(str): the path to a target csv file
        printing(bool): if True funciton will print helpful readout
                        of contents of results
    Returns:
        table(df): pandas dataframe of the csv
        tail(str): the filename of the csv
    """

    path = os.path.abspath(tbl_path)

    if not os.path.exists(path):
        raise FileNotFoundError(
          errno.ENOENT, os.strerror(errno.ENOENT), path
          )

    if os.path.isfile(path):

        head, tail = os.path.split(tbl_path)
        table = pd.read_csv(tbl_path)

        if printing is True:
            print(
                "RETURNING 3 OBJECTS:\n"
                "[0] pandas dataframe of CSV\n"
                "[1] tail of file path\n\n"
                "it is reccomended you use the tail of"
                "file path as table name if reasonable"
                )
    return table, tail


def table_from_file(table_dir):
    """
    this loads a all csvs in a filepath into pandas dataframes,
    by applying table_loader() to every file in a given filepath

    Parameters:
        tbl_path(str): the path to a directory with target csv(s)
        printing(bool): if True funciton will print helpful readout
                        of contents of results

    Returns:
        table(df): pandas dataframe(s) of the csv(s)
        tail(str): the filename(s) of any of the csv(s)
    """
    path = os.path.abspath(table_dir)

    df_store = {}

    if not os.path.exists(path):
        raise FileNotFoundError(
          errno.ENOENT, os.strerror(errno.ENOENT), path
          )

    if os.path.isdir(path):
        for filename in os.listdir(table_dir):
            tbl, tbl_name = table_loader(os.path.join(table_dir, filename))
            df_store[tbl_name] = tbl
        return df_store


def term_lookup(match_dict, term, mode='local'):
    """
    this looks up wether a term exists within the match dictionary,
    and returns all the info associated with the match, if present

    Parameters:
        match_dict(dict): dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI,
                          owlterm, LVD, col, tbl]}}}}
        term(str): term to search for in match_dict

    Returns:
        termlist(ls): a list of the information associated with search term
    """
    if mode == 'local':
        # for ontology key
        for ontokey in match_dict.keys():
            # for sa key
            for sa in match_dict[ontokey].keys():
                # for tbl key
                for tbl in match_dict[ontokey][sa].keys():
                    # if the column name is in the
                    # matched term table keys (columns)
                    for column in match_dict[ontokey][sa][tbl].keys():
                        # look through all the lists of matched terms and IRIs
                        for termlist in match_dict[ontokey][sa][tbl][column]:
                            if term.lower() == termlist[0].lower():
                                return termlist
                    else:
                        pass
    else:
        # if the column name is in the matched term table keys (columns)
        for key in match_dict.keys():
            # look through all the lists of matched terms and IRIs
            for termlist in match_dict[key]:
                if term.lower() == termlist[0][0].lower():
                    return termlist
        else:
            pass


def relational_rdf(dframe, table_name, match_dict, graph, mode='local'):
    """
    this loads RDF relationships into an RDF graph datastore
    that reflect the relationships between rows, columns, and data
    in the original csv. The basic structure is achieved by assinging
    every row in the dataframe a unique "example.org/tablename/rownumber"
    IRI. Then columns are matched to IRIs if present in match dictionary,
    and used as predicates for data, which is also matched to IRIs if
    present in match dictionary

    Parameters:
        dframe(df): the path to a directory with target csv(s)
        tablename(str): if True funciton will print helpful readout
                        of contents of results
        match_dict(dict): dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI,
                          owlterm, LVD, col, tbl]}}}}
        graph(rdflib.Graph): Graph triplestore created with rdflib package
        mode(str): 'local' mode

    Returns:
        table(df): pandas dataframe(s) of the csv(s)
        tail(str): the filename(s) of nay of the csv(s)
    """
    # for each column
    for col_name in dframe.columns:
        # find column match, if in match dicitonary
        column_info = term_lookup(match_dict, col_name, mode)
        if column_info:
            if mode == 'local':
                # create <column_iri>
                column_iri = URIRef(column_info[1])
            else:
                column_iri = URIRef(column_info[0][1])
        else:
            column_iri = Literal(col_name)
            print(f" IMPORTANT: {col_name} needs manual curation")
        # for each row of this column
        for ind in dframe.index:
            # CODE: create <unique_row_iri>
            row_iri = URIRef(
                        "http://example.org/" + table_name + "/" + str(ind)
                        )
            # identify row data object
            row_data = str(dframe[col_name][ind]).lower()
            # find row data match, if match in dictionary
            data_info = term_lookup(match_dict, row_data, mode)

            if data_info:
                if mode == 'local':
                    # create <data_iri>
                    data_iri = URIRef(data_info[1])
                else:
                    data_iri = URIRef(data_info[0][1])
            else:
                # create data literal
                data_iri = Literal(row_data)
            # add (<unique_row_iri> <column_iri> <data_iri>)
            # to RDF graph
            graph.add((row_iri, column_iri, data_iri))


def basic_rdf(match_dict, graph, mode='local'):
    if mode == 'local':
        # for ontology key
        for ontokey in match_dict.keys():
            # for sa key
            for sa in match_dict[ontokey].keys():
                # for tbl key
                for tbl in match_dict[ontokey][sa].keys():
                    # for column in table
                    for column in match_dict[ontokey][sa][tbl].keys():
                        # create RDF for each term's basic info
                        for termlist in match_dict[ontokey][sa][tbl][column]:

                            termlabel = Literal(termlist[0])
                            termiri = URIRef(termlist[1])
                            termpredicate = URIRef(termlist[2])
                            # add to graph
                            graph.add(
                                (
                                    termiri,
                                    termpredicate,
                                    termlabel),
                                )
                            # check for superclass info for term
                            if termlist[4] is not None:
                                term_super_lab = Literal(termlist[3])
                                term_super_iri = URIRef(termlist[4])
                                # add to graph
                                sub_class = (
                                        "https://www.w3.org/2000"
                                        "/01/rdf-schema#subClassOf"
                                        )
                                graph.add(
                                    (
                                        termiri,
                                        URIRef(sub_class),
                                        term_super_iri
                                    )
                                )
                                graph.add(
                                    (
                                        term_super_iri,
                                        URIRef(termlist[2]),
                                        term_super_lab
                                    )
                                )
    else:
        # for column in table
        for term in match_dict.keys():
            # create RDF for each term's basic info
            for termlist in match_dict[term]:
                termlabel = Literal(termlist[0][0][0])
                print(termlist[0][1])
                termiri = URIRef(termlist[0][1])
                termpredicate = URIRef("https://www.w3.org/2000"
                                       "/01/rdf-schema#label")
                # add to graph
                graph.add(
                    (
                        termiri,
                        termpredicate,
                        termlabel),
                    )
                # check for superclass info for term
                if termlist[1] is not None:
                    term_super_lab = Literal(termlist[0][1][0])
                    term_super_iri = URIRef(termlist[0][1][1])
                    # add to graph
                    sub_class = (
                            "https://www.w3.org/2000"
                            "/01/rdf-schema#subClassOf"
                            )
                    graph.add(
                        (
                            termiri,
                            URIRef(sub_class),
                            term_super_iri
                        )
                    )
                    graph.add(
                        (
                            term_super_iri,
                            termpredicate,
                            term_super_lab
                        )
                    )


def relational_rdf_loader(rdb_df_dict, match_obj, graph, mode='local'):
    """
    this loads RDF relationships into an RDF graph datastore
    using the relational_rdf() function. However, this function
    does this process on a dictionary of dataframes, allowing
    for a efficient application of the function to multiple
    relational data files at once

    Parameters:
        rdb_df_dict(dict): dictionary of dataframes
        match_obj(dict):  dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI,
                          owlterm, LVD, col, tbl]}}}}
        graph(rdflib.Graph): Graph triplestore created with rdflib package
        mode(str): 'local' vs 'API' mode

    Returns:
        no objects- just modification to the rdf Graph
    """
    if mode == 'local':
        for csv_name in rdb_df_dict.keys():
            relational_rdf(
                            rdb_df_dict[csv_name],
                            csv_name[:-4],
                            match_obj, graph
                            )
    else:
        for csv_name in rdb_df_dict.keys():
            relational_rdf(
                            rdb_df_dict[csv_name],
                            csv_name[:-4],
                            match_obj,
                            graph,
                            mode='API'
                            )


# manual column curator
def term_curator(match_dict, mode='local'):
    """
    function which allows the user to manually curate term-IRI associations
    in match_dict with relative ease, with a UI via the python input()
    function

    Parameters:
        match_dict(dict): dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI, owlterm, LVD, col, tbl]}}}}
        mode(str): 'local' mode

    Returns:
        rermlist(ls):

    """
    print("IMPO: to apply this function, user must have ther term label, \n"
          "term IRI, and if possible, term superclass label and IRI.\n\n"
          "WARNING: if term has no superclass IRI/label, input None\n"
          "below, term information- as is"
          )
    lookup_val = str(input("Enter the name (string literal) of the term you want to manually identify"))
    if mode == 'local':
        # for ontology key
        for ontokey in match_dict.keys():
            # for sa key
            for sa in match_dict[ontokey].keys():
                # for tbl key
                for tbl in match_dict[ontokey][sa].keys():
                    # if the column name is in the
                    # matched term table keys (columns)
                    for column in match_dict[ontokey][sa][tbl].keys():
                        # look through all the lists of matched terms and IRIs
                        for termlist in match_dict[ontokey][sa][tbl][column]:
                            if lookup_val.lower() == termlist[0].lower():
                                replace_iri = input("Enter the new Int'l Resource Identifier (IRI) for the \n"
                                                    "rdfs:label of the term\n")
                                termlist[1] = replace_iri
                                replace_sc_iri = input("Enter the new Int'l Resource Identifier (IRI) for the \n"
                                                    "rdfs:subClassOf (superclass) of the term\n")
                                termlist[3] = replace_sc_iri
                                replace_sc_lab = input("Enter the new name (string literal) for the \n"
                                                    "rdfs:label (superclass) of the term\n")
                                termlist[4] = replace_sc_lab
                            else:
                                pass
        return termlist
    else:
        # if the column name is in the matched term table keys (columns)
        for key in match_dict.keys():
            # look through all the lists of matched terms and IRIs
            for termlist in match_dict[key]:
                if term.lower() == termlist[0].lower():
                    replace_iri = input("Enter the new Int'l Resource"
                                        " Identifier (IRI) for the \n"
                                        "rdfs:label of the term\n")
                    termlist[1] = replace_iri
                    replace_sc_iri = input("Enter the new Int'l Resource"
                                           " Identifier (IRI) for the \n"
                                           "rdfs:subClassOf (superclass) "
                                           "of the term\n")
                    termlist[3] = replace_sc_iri
                    replace_sc_lab = input("Enter the new name (string literal"
                                           ") for the \n rdfs:label "
                                           "(superclass) of the term\n")
                    termlist[4] = replace_sc_lab
                else:
                    pass
        return termlist


def term_editor(unmatch_dict, match_dict, lookup_val,
                new_iri, new_sc_lab=None, new_sc_iri=None):
    """
    function to take ldictionary of unmatched terms, dictionary of matched terms,
    a specific term to look for, the IRI match defined by the user, and superclass
    label and IRI if provided. Changes match dictionary in-place. No UI.

    Parameters:
        unmatch_dict(dict): dictionary of terms sorted by {tbl:{col:[terms]}}
        match_dict(dict): dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI,
                           owlterm, LVD, col, tbl]}}}}
        lookup_val(str): term user is assigning an IRI to
        new_IRI(str): the user-definied correct IRI for the term
        new_sc_lab(str): label for superclass of entitity (optional)
        new_sc_iri(str): IRI for superclass of entity (optional)

    """
    # for tbl key
    for tbl in unmatch_dict.keys():
        # if the column name is in the matched term table keys (columns)
        for column in unmatch_dict[tbl].keys():
            # look through all the lists of unmatched terms and IRIs
            for term in unmatch_dict[tbl][column]:
                if term.lower() == lookup_val.lower():
                    term_info = [tbl, column, term]
                    # loop into match dictionary
                    # for ontology key
                    for ontokey in match_dict.keys():
                        # for sa key
                        for sa in match_dict[ontokey].keys():
                            # for tables
                            new_terminfo = [
                                term, new_iri,
                                'http://www.w3.org/2000/01/rdf-schema#label',
                                new_sc_lab, new_sc_iri, term,
                                "manual", column, tbl
                                ]
                            if match_dict[ontokey][sa][tbl][column] == []:
                                match_dict[ontokey][sa][tbl][column].append(
                                                                    new_terminfo)
                            else:
                                for item in match_dict[ontokey][sa][tbl][column]:
                                    if item[0].lower() == lookup_val.lower() and new_iri.lower() != item[1].lower():
                                        match_dict[ontokey][sa][tbl][column].remove(item)
                                        match_dict[ontokey][sa][tbl][column].append(
                                                                        new_terminfo)
                                    else:
                                        pass

# define a function that can accept an input of multiple
# manual matches and apply them all at once


def multi_editor(unmatch_dict, match_dict, list_matches):
    """
    function that takes a list of (term, IRI) tuples
    and optional (term, IRI, term_sc, term_sc_IRI) tuples
    and rolls the termeditor function over them

    Parameters:
        unmatch_dict(dict): dictionary of terms sorted by {tbl:{col:[terms]}}
        match_dict(dict): dictionary of terms sorted by
                          {owl:{sa:{tbl:{col:
                          [term, IRI, superclass, scIRI,
                          owlterm, LVD, col, tbl]}}}}
        list_matches(ls): list of new matches to assert, form of
                          [('match', 'IRI'), ('match', 'IRI')]
    Returns:
        nothing, changes match dictionary in-place
    """
    for edits in list_matches:
        if len(edits) == 2:
            term_editor(unmatch_dict, match_dict, edits[0], edits[1])
        if len(edits) == 4:
            term_editor(unmatch_dict, match_dict,
                        edits[0], edits[1], edits[2], edits[3])


# function to make a 'primary' node- a node directly under the row_id node

def primenode(prime_col, rdfgraph, matchset, primename=None):
    """
    function which makes subset of relational dataframe into its own
    node. User defines a column to be primary node, which the rest of the
    columns in the subset are then related to. The primary node will be by
    default a literal or lookup of this primary node column name, however the
    user can (and should) explicitly define an IRI for this node.

    Parameters:
        prime_col(str): the first column in the group- all other columns are
                     indetified by this column and describe the object in
                     this column.
        rdfgraph(triplestore): graph to remove old triples and add new ones
        matchset(dict): matches to lookup if column has IRI in dictionary
        primename(str): name of primenode for unique IRI generation
    """

    # designate primename as name of primecol
    # if no user-identified primename
    if primename is None:
        primename = str(prime_col)

    tl = term_lookup(matchset, prime_col)

    if (None, Literal(prime_col), None) in rdfgraph:
        for s, p, o in rdfgraph.triples((None, Literal(prime_col), None)):

            # create base node
            #    ex. <nikc/42/parameter>
            node = URIRef(s + "/" + primename)
            # print(node)

            # add in new triples
            # asserting the node as a subPropertyOf the basenode
            #    ex. <nikc/42/parameter/description> <sPO> <nikc/42/parameter>
            rdfgraph.add((
                        node,
                        URIRef(
                            'http://www.w3.org/2000/01/rdf-schema#subPropertyOf'
                            ),
                        s))

            # and the triple of <subnode> <column> <data>
            rdfgraph.add((
                        node,
                        URIRef(tl[1]),
                        o))

            # remove old direct triples
            rdfgraph.remove((s, p, o))
    else:
        for s, p, o in rdfgraph.triples((None, URIRef(tl[1]), None)):

            # create base node
            #    ex. <nikc/42/parameter>
            node = URIRef(s + "/" + primename)
            # print(node)

            # add in new triples
            # asserting the node as a subPropertyOf the basenode
            #    ex. <nikc/42/parameter/description> <sPO> <nikc/42/parameter>
            rdfgraph.add((
                        node,
                        URIRef(
                            'http://www.w3.org/2000/01/rdf-schema#subPropertyOf'
                            ),
                        s))

            # and the triple of <subnode> <column> <data>
            rdfgraph.add((
                        node,
                        URIRef(tl[1]),
                        o))

            # remove old direct triples
            rdfgraph.remove((s, p, o))


# function to add single relations to a prexisting primary node

def node_one(prime_col, node_col, rdfgraph, matchset, primename=None):
    """
    function which makes subset of relational dataframe into its own
    node. User defines a column to be primary node, which the rest of the
    columns in the subset are then related to. The primary node will be by
    default a literal or lookup of this primary node column name, however
    the user can (and should) explicitly define an IRI for this node.

    Parameters:
        prime_col(str): the first column in the group- all other columns are
                     indetified by this column and describe the object in
                     this column.
        node_col(str): column to be made a sub node of the prime node
        rdfgraph(triplestore): graph to remove old triples and add new ones
        matchset(dict): matches to lookup if column has IRI in dictionary
        primename(str): string name of prime node for IRI generation
    """

    # designate primename as name of primecol
    # if no user-identified primename
    if primename is None:
        primename = str(prime_col)

    tl = term_lookup(matchset, node_col)

    if (None, Literal(node_col), None) in rdfgraph:
        for s, p, o in rdfgraph.triples((None, Literal(node_col), None)):

            # create base node
            if primename == "":
                node = s
            else:
                node = URIRef(s + "/" + primename)
            # print(node)

            # and the triple of <node> <column_iri> <data>
            rdfgraph.add((
                        node,
                        URIRef(tl[1]),
                        o))

            # remove old direct triples
            rdfgraph.remove((s, p, o))
    else:
        for s, p, o in rdfgraph.triples((None, URIRef(tl[1]), None)):
            # create base node
            if primename == "":
                node = s
            else:
                node = URIRef(s + "/" + primename)
            # print(node)

            # and the triple of <node> <column_iri> <data>
            rdfgraph.add((
                        node,
                        URIRef(tl[1]),
                        o))

            # remove old direct triples
            rdfgraph.remove((s, p, o))


# function to add a node under a primary node
def node_two(sub_col, primename, rdfgraph, matchset, subiri, subname=None):
    """
    function which makes a column into a subnode, this function is for columns
    that express thre pieces of information, such as "parameterUncertaintyType"
    where there must be a <example/parameter> node, and a
    <example/parameter/uncertainty> node, and then a
    <example/parameter/uncertainty> <type> "data" triple.

    Parameters:
        sub_col(str): the column to turn into a subnode
        primename(str): name of subnode for IRI generation
        rdfgraph(triplestore): graph to remove old triples and add new ones
        matchset(dict): matches to lookup if column has IRI in dictionary
        subiri(str): IRI that has 'subject' relationship to new  prime node.
                      match dict should have IRI association for node that
                      describes its relationship to the data, like "type"
                      or "text"
        subname: string name to use for subnode IRI

    """

    # designate primename as name of primecol
    # if no user-identified primename
    if subname is None:
        subname = str(sub_col)

    for s, p, o in rdfgraph.triples((None, Literal(sub_col), None)):
        tl = term_lookup(matchset, sub_col)

        # create base node
        if primename == "":
            node = s
        else:
            node = URIRef(s + "/" + primename)
        # print(node)

        # create sub node
        subnode = URIRef(node + "/" + subname)
        # print(node)

        # and the triple of <node> <column_iri> <data>
        rdfgraph.add((
                    subnode,
                    URIRef(
                        'http://www.w3.org/2000/01/rdf-schema#subPropertyOf'
                        ),
                    node))

        # and the triple of <node> <column_iri> <data>
        rdfgraph.add((
                    subnode,
                    URIRef(tl[1]),
                    o))

        # define the subject of the subnode
        rdfgraph.add((
                    subnode,
                    URIRef(
                        'http://www.w3.org/1999/02/22-rdf-syntax-ns#subject'
                        ),
                    URIRef(subiri)))

        # remove old direct triples
        rdfgraph.remove((s, p, o))


# create a node from scratch, based off a column of user chice
def create_node(newnodename, node_iri, ref_col_name, rdfgraph):
    """
    this is a general node creation function, made for flexible use
    and generating nodes that may not be in the dataframe
    """

    # designate primename as name of primecol
    # if no user-identified primename
    ref_col = str(ref_col_name)

    for s, p, o in rdfgraph.triples((None, Literal(ref_col), None)):

        # create base node
        node = URIRef(s + "/" + nodename)

        # add node subject
        rdfgraph.add((
                    node,
                    URIRef('http://www.w3.org/1999/02/22-rdf-syntax-ns#subject'),
                    URIRef(node_iri)
                    ))

        # and the triple of <node> <column_iri> <data>
        rdfgraph.add((
                    node,
                    URIRef('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'),
                    s))

# using "bag" function


def bagmaker(rdfgraph, node, bag):
    """
    this function creates a rdf bag for a set of columns in a CSV
    that are related descriptors of a central entity

    it should take something of the form, say a part of a csv with columns:
    | parameter value | parameter smybol | parameter id  |
    |    2.5          |       >          |    42         |

    <example.com/36> <parameter> [
                                <has_value> 2.5 ;
                                <symbol> ">" ;
                                <parameter id> 42 .
                                ]

    Parameters:
        rdfgraph(triplestore): graph to remove old triples and add new ones
        node: IRI for relationship of row to bag
        bag: list of tuples, of form (column, IRI), the column name
        will be used to read the csv and extract data, IRI for semantics

    """
    # list of predicates to put in bag for particle diameter bag
    diameter_vars = [
                    (URIRef('rdf:value'), Literal(2.5)),
                    (URIRef('http://www.example.org/unit'), Literal('mg/L')),
                    (URIRef('http://www.example.org/approx'), Literal('<')),
                    (URIRef('http://www.NCIT.org/unit'), Literal('standard deviation')),
                    (URIRef('http://www.eNanoMapper.org/low'), Literal('6'))
                    ]

    bag = BNode()

    testGraph.add((
                URIRef('http://www.example.com/siler_nanoparticle'),
                URIRef('http://www.example.org/diameter'),
                bag))

    for predicate, obj in diameter_vars:
        testGraph.add((
                bag,
                predicate,
                obj
                ))
