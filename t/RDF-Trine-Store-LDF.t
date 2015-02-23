use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use RDF::Trine::Store;

my $pkg;
BEGIN {
    $pkg = 'RDF::Trine::Store::LDF';
    use_ok $pkg;
}
require_ok $pkg;

my $store = $pkg->new_with_config({
	storetype => 'LDF',
	url => 'http://fragments.dbpedia.org/2014/en'
});

ok $store , 'got a store';

my $model =  RDF::Trine::Model->new($store);

ok $model , 'got a model';

my $it = $store->get_statements();

ok $it , 'got an iterator on the compelete database';

my $triple = $it->next();

isa_ok $triple , 'RDF::Trine::Statement' , 'triple is an RDF::Trine::Statement';

ok $triple , 'got a triple';

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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->next();

	ok $binding , 'got a binding';

	ok $binding->{'s'};
	ok $binding->{'o'};
	ok $binding->{'p'};
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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->next();

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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->next();

	ok $binding , 'got a binding';

	ok $binding->{'musician'};
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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->next();

	ok $binding , 'got a binding';

	ok $binding->{'musician'};
	ok $binding->{'name'};
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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->();

	ok $binding , 'got a binding';

	ok $binding->{'p'};
	ok $binding->{'c'};

	ok !defined($it->next()) , 'got only one result';
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

	my $it = get_sparql($sparql);

	ok $it , 'got an iterator';

	my $binding = $it->next();

	ok $binding , 'got a binding';

	ok $binding->{'p'};
	ok $binding->{'c'};
	ok $binding->{'musician'};

	ok defined($it->next()) , 'got only more results';
}

done_testing;

sub get_sparql {
	my $sparql = shift;
	my $rdf_query = RDF::Query->new( $sparql );
	$rdf_query->execute($model);
}