use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use RDF::LDF;


my $client = RDF::LDF->new(url => 'http://fragments.dbpedia.org/2014/en');

ok $client , 'got a client to http://fragments.dbpedia.org/2014/en';

ok $client->is_fragment_server , 'this server is a ldf server';

{
	my $sparql =<<EOF;
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
SELECT * WHERE { ?s ?o ?p}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'?s'};
	ok $binding->{'?o'};
	ok $binding->{'?p'};
}

{
	my $sparql =<<EOF;
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
SELECT * WHERE {
	<http://dbpedia.org/resource/Willie_Duncan> <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	is int(keys %$binding) , 0 , 'binding is empty';
}

{
	my $sparql =<<EOF;
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
SELECT * WHERE {
	?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'?musician'};
}

{
	my $sparql =<<EOF;
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
SELECT * WHERE { 
	 ?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
     ?musician foaf:name ?name .
}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'?musician'};
	ok $binding->{'?name'};
}

{
	my $sparql =<<EOF;
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
SELECT *
WHERE {
   ?p a <http://dbpedia.org/ontology/Artist> .
   ?p <http://dbpedia.org/ontology/birthPlace> ?c .
   ?c <http://xmlns.com/foaf/0.1/name> "York"\@en .
}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'?p'};
	ok $binding->{'?c'};

	ok !defined($it->()) , 'got only one result';
}

{
	my $sparql =<<EOF;
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
SELECT *
WHERE {
   ?p a <http://dbpedia.org/ontology/Artist> .
   ?p <http://dbpedia.org/ontology/birthPlace> ?c .
   ?c <http://xmlns.com/foaf/0.1/name> "York"\@en .
   ?musician <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:German_musicians> .
}
EOF

	my $it = $client->get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'?p'};
	ok $binding->{'?c'};
	ok $binding->{'?musician'};

	ok defined($it->()) , 'got only more results';
}


done_testing;