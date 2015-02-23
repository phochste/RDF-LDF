# NAME

RDF::LDF - Linked Data Fragments client

# SYNOPSIS

    use RDF::LDF ;

    my $client = RDF::LDF ->new(url => 'http://fragments.dbpedia.org/2014/en');

    my $iterator = $client->get_statements($subject, $predicate, $object);

    while (my $statement = $iterator->()) {
        # $model is a RDF::Trine::Statement
    } 

    my $iterator = $client->get_sparql(<<EOF);
    PREFIX dbpedia: <http://dbpedia.org/resource/>
    SELECT * WHERE { dbpedia:Arthur_Schopenhauer ?predicate ?object . }
    EOF

    while (my $binding = $iterator->()) {
        # $binding is a hashref of all the bindings in the SPARQL
    }

# DESCRIPTION

The RDF::LDF  module is a basic implementation of a Linked Data Fragment client. For details see:
<http://linkeddatafragments.org/>.

# STATUS

THIS IS ALPHA CODE! The implementation is unreliable and the interface is subject to change.

# CONFIGURATION

- url

    URL to retrieve RDF from.

# METHODS

- get\_statements($subject,$predicate,$object)

    Return an iterator for every RDF::Trine::Statement served by the LDF server.

- get\_sparql($sparql)

    Return an iterator for everty binding in the SPARQL query. For now the support is very basic.
    Only select queries are supported without union, sorting or limits with a form like:

        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX : <http://dbpedia.org/resource/>
        PREFIX dbpedia2: <http://dbpedia.org/property/>
        PREFIX dbpedia: <http://dbpedia.org/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX dbo: <http://dbpedia.org/ontology/>
        SELECT *
        WHERE {
          ?car <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Luxury_vehicles> .
          ?car foaf:name ?name .
          ?car dbo:manufacturer ?man .
          ?man foaf:name ?manufacturer
        }

# AUTHOR

Patrick Hochstenbach, `patrick.hochstenbach at ugent.be`
