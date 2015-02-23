# NAME

RDF::LDF - Linked Data Fragments client

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

The RDF::LDF  module is a basic implementation of a Linked Data Fragment client. For details see:
<http://linkeddatafragments.org/>.

This a low level module to implement the Linked Data Fragment protocol. You probably want to
use [RDF::Trine::Store::LDF](https://metacpan.org/pod/RDF::Trine::Store::LDF).

# CONFIGURATION

- url

    URL to retrieve RDF from.

# METHODS

- get\_statements( $subject, $predicate, $object )

    Return an iterator for every RDF::Trine::Statement served by the LDF server.

- get\_pattern( $bgp );

    Returns a stream object of all bindings matching the specified graph pattern.

# AUTHOR

Patrick Hochstenbach, `patrick.hochstenbach at ugent.be`

# LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of either: 
the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
