# NAME

RDF::LDF - Linked Data Fragments client

# SYNOPSIS

    use RDF::LDF;

    my $client = RDF::LDF ->new(url => 'http://fragments.dbpedia.org/2014/en');

    my $iterator = $client->get_statements($subject, $predicate, $object);

    while (my $statement = $iterator->()) {
        # $model is a RDF::Trine::Statement
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

- get\_pattern ($bgp);

    Returns a stream object of all bindings matching the specified graph pattern.

# AUTHOR

Patrick Hochstenbach, `patrick.hochstenbach at ugent.be`
