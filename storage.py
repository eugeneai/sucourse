from rdflib import (Namespace, RDFS, RDF, FOAF,
                    Dataset, BNode, URIRef, Graph, Literal, DCTERMS,
                    DC, PROV)
from rdflib.plugins.stores.sparqlstore import SPARQLUpdateStore
import urllib.error
from uuid import uuid1

# Store and retrieve from data for a record in a SPARQL store

STORE_URL = "http://irnok.net:8890/sparql"


def binds(g):
    g.bind('wpdb', WPDB)
    g.bind('wpdd', WPDD)
    g.bind('idb', IDB)
    g.bind('idd', IDD)
    g.bind('libdb', LIBDB)
    g.bind('libdd', LIBDD)
    g.bind('dbr', DBR)
    g.bind('schema', SCH)
    g.bind('cnt', CNT)
    g.bind('bibo', BIBO)
    g.bind('bf', BIBFRAME)


WPDB = Namespace("http://irnok.net/ontologies/database/isu/workprog#")
WPDD = Namespace("http://irnok.net/ontologies/isu/workprog#")
DBR = Namespace("http://dbpedia.org/resource/")
IDB = Namespace("http://irnok.net/ontologies/database/isu/studplan#")
IDD = Namespace("http://irnok.net/ontologies/isu/studplan#")
SCH = Namespace("https://schema.org/")
CNT = Namespace("http://www.w3.org/2011/content#")

LIBDB = Namespace("http://irnok.net/ontologies/database/isu/library#")
LIBDD = Namespace("http://irnok.net/ontologies/isu/library#")
BIBO = Namespace("http://purl.org/ontology/bibo/")
BIBFRAME = Namespace("http://id.loc.gov/ontologies/bibframe/")
L = Graph(identifier=str(IDB.library))

DS = Dataset(store="SPARQLUpdateStore",
             default_graph_base=L)

DS.open(STORE_URL)


def defaultprovision(DS):
    """Adds binds and subgraphs if they do not exist """
    binds(DS)
    s = DS.store
    for kgname in [
            'departments', 'disciplines', 'references', 'standards', 'library'
    ]:
        try:
            s.add_graph(Graph(identifier=IDB[kgname]))
            s.commit()
        except urllib.error.HTTPError:
            s.rollback()
            pass # Already added


def genid(NS):
    u = uuid1()
    return NS[str(u)]



def storeref(ref):
    """Store a ref represented as dict"""

    g = DS
    s = DS.store

    refid = ref["ref_id"]

    # first query graph if it exists
    # if it does, then skip operation TODO: replace functionality

    for s in g.subjects(DCTERMS.identifier, Literal(refid)):
        return

    R = genid(LIBDB)
    g.add((R, DCTERMS.identifier, Literal(refid), L))
    g.add((R, RDF.type, BIBO.Document, L))
    RS = IDB.ReferenceSanitizerLaTeXSyllabusV1
    g.add((R, PROV.wasGeneratedBy, RS, L))
    g.add((RS, RDFS.label, Literal("LaTeX-Syllabus V1"), L))
    g.add((R, DC.title, Literal(ref["issue"]), L))
    C = genid(LIBDB)
    g.add((C, RDF.type, FOAF.Person, L))
    g.add((C, RDFS.label, Literal(", ".join(ref["author"])), L))
    g.add((R, DC.creator, C, L))
    UDC = genid(LIBDB)
    g.add((UDC, RDF.type, BIBFRAME.ClassificationUdc, L))
    g.add((UDC, RDFS.label, Literal(ref["UDC"]), L))
    g.add((R, BIBFRAME.classification, UDC, L))
    for isbn in ref.get("ISBN", []):
        g.add((R, BIBO.isbn, Literal(isbn), L))
    # TODO: Rubrics
    # TODO: keywords
    g.add((R, BIBFRAME["count"], Literal(ref["count"]), L))
    s.commit()


defaultprovision(DS)
