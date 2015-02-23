#!/usr/bin/env perl
$|++;

use strict;

use RDF::LDF;
use JSON;
use File::Slurp;
use Getopt::Long;
use Tie::IxHash;
use JSON;

my ($subject,$predicate,$object);

GetOptions("subject=s" => \$subject , "predicate=s" => \$predicate , "object" => \$object);

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

my $client = RDF::LDF->new(url => $url);

if (defined $sparql) {
	process_sparql($sparql);
}
else {
	process_fragments($subject,$predicate,$object);
}

sub process_fragments {
	my ($subject,$predicate,$object) = @_;

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

	my $it = $client->get_sparql($sparql);

	print "[\n";
	while (my $binding = $it->()) {
		print encode_json($binding), "\n";
	}
	print "]\n";
}