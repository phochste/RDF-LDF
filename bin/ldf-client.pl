#!/usr/bin/env perl

use RDF::LDF;
use JSON;
use File::Slurp;
use Getopt::Long;

my $url    = shift;
my $sparql = shift;

unless (defined $url) {
	print STDERR <<EOF;
usage: $0 [options] url sparql
EOF
	exit(1);
}

my $client = RDF::LDF->new(url => $url);

my $it = $client->get_sparql($sparql);

$sparql = read_file($sparql) if -r $sparql;

binmode(STDOUT,":encoding(UTF-8)");

while (my $binding = $it->()) {
	print encode_json($binding);
}