# NAME

RDF::LDF - Linked Data Fragments client

# STATUS
[![Build Status](https://travis-ci.org/phochste/RDF-LDF.svg)](https://travis-ci.org/phochste/RDF-LDF)
[![Coverage Status](https://coveralls.io/repos/phochste/RDF-LDF/badge.svg)](https://coveralls.io/r/phochste/RDF-LDF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/RDF-LDF.png)](http://cpants.cpanauthors.org/dist/RDF-LDF)

# SYNOPSIS

    use RDF::Trine::Store::LDF;
    use RDF::Trine::Store;

    my $store = RDF::Trine::Store->new_with_config({
            storetype => 'LDF',
            url => $url
    });

    my $it = $store->get_statements();

    while (my $st = $it->next) {
        # $st is a RDF::Trine::Statement
        print "$st\n";
    }

    # Or the low level modules themselves

    use RDF::LDF;

    my $client = RDF::LDF->new(url => 'http://fragments.dbpedia.org/2014/en');

    my $iterator = $client->get_statements($subject, $predicate, $object);

    while (my $statement = $iterator->()) {
        # $model is a RDF::Trine::Statement
    } 

# DESCRIPTION

RDF::LDF implements a basic [Linked Data Fragment](http://linkeddatafragments.org/) client.

This a low level module to implement the Linked Data Fragment protocol. You probably want to
use [RDF::Trine::Store::LDF](https://metacpan.org/pod/RDF::Trine::Store::LDF).

# CONFIGURATION

- url

    URL to retrieve RDF from. 

    Experimental: more than one URL can be provided separated by a space for federated searches

# METHODS

- get\_statements( $subject, $predicate, $object )

    Return an iterator for every RDF::Trine::Statement served by the LDF server.

- get\_pattern( $bgp );

    Returns a stream object of all bindings matching the specified graph pattern.

# CONTRIBUTORS

Patrick Hochstenbach, `patrick.hochstenbach at ugent.be`

Gregory Todd Williams, `greg@evilfunhouse.com`

Jacob Voss, `voss@gbv.de`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
