#!/usr/bin/env perl
$|++;

use strict;

use RDF::LDF;
use RDF::Trine::Store::LDF;
use RDF::Trine::Store;
use RDF::Query;
use JSON;
use File::Slurp;
use Getopt::Long;
use Tie::IxHash;
use JSON;

my ($subject,$predicate,$object);

GetOptions("subject=s" => \$subject , "predicate=s" => \$predicate , "object=s" => \$object);

my $url    = shift;
my $sparql = shift;

unless (defined $url) {
    print STDERR <<EOF;
usage: $0 url sparql

usage: $0 [options] url

options:

   --subject=<.>
   --predicate=<.>
   --object=<.>

EOF
    exit(1);
}

binmode(STDOUT,":encoding(UTF-8)");

if (defined $sparql) {
    process_sparql($sparql);
}
else {
    process_fragments($subject,$predicate,$object);
}

sub process_fragments {
    my ($subject,$predicate,$object) = @_;

    my $client = RDF::LDF->new(url => $url);
    my $it = $client->get_statements($subject,$predicate,$object);

    print "[\n";
    while (my $st = $it->()) {
        my %triple = ();
        tie %triple , 'Tie::IxHash';

        $triple{subject}   = $st->subject->value;
        $triple{predicate} = $st->predicate->value;
        $triple{object}    = $st->object->value;

        print encode_json(\%triple), "\n";
    }
    print "]\n";
}

sub process_sparql {
    my $sparql = shift;
    $sparql = read_file($sparql) if -r $sparql;

    my $store = RDF::Trine::Store->new_with_config({
            storetype => 'LDF',
            url => $url
    });

    my $model =  RDF::Trine::Model->new($store);

    my $rdf_query = RDF::Query->new( $sparql );

    unless ($rdf_query) {
        print STDERR "failed to parse:\n$sparql";
        exit(2);
    }

    my $iter = $rdf_query->execute($model);

    while (my $s = $iter->next) {
        print $s . "\n";
    }
}
