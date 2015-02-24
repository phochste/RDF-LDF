
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use RDF::LDF;

my $client = RDF::LDF->new(url => 'http://fragments.dbpedia.org/2014/en');

ok $client , 'got a client to http://fragments.dbpedia.org/2014/en';

ok $client->is_fragment_server , 'this server is a ldf server';

my $it = $client->get_statements();

ok $it , 'got an iterator on the compelete database';

my $triple = $it->();

ok $triple , 'got a triple';

isa_ok $triple , 'RDF::Trine::Statement' , 'triple is an RDF::Trine::Statement';

my ($triple2,$info) = $it->();

ok $info , 'got ldf metadata';

ok $info->{void_triples}  , 'got lotsa triples';

throws_ok { $client->get_pattern() } 'RDF::Trine::Error::MethodInvocationError' , 'throws on empty pattern';

done_testing;