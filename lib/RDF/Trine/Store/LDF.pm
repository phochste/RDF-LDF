package RDF::Trine::Store::LDF;

use strict;
use warnings;
no warnings 'redefine';
use feature qw(state);
use utf8;
use base qw(RDF::Trine::Store);

use RDF::Trine::Store;
use RDF::Trine::Iterator;
use RDF::LDF;

sub new {
	my ($class,%opts) = @_;
	my $ref = \%opts;
	$ref->{ldf} =  RDF::LDF->new( url => $ref->{url});
	bless $ref , $class;
}

sub _new_with_string {
	my ($class, $cfg) = @_;
	$class->new(url => $cfg);
}
sub _new_with_config {
	my ($class,$cfg) = @_;
	$class->new(url => $cfg->{url});
}

sub get_statements {
	my ($self,$subject,$predicate,$object,$context) = @_;

	my $sub = $self->{ldf}->get_statements($subject,$predicate,$object);
	RDF::Trine::Iterator::Graph->new($sub);
}

sub get_pattern {
	my ($self,$bgp,$context) = @_;

	$self->{ldf}->get_pattern($bgp,$context);
}

sub get_contexts {
	undef;
}

sub add_statement {
	die "add_sattement is not implemented";
}

sub remove_statement {
	die "remove_statement is not implemented";
}

sub remove_statements {
	die "remove_statements is not implemented";
}

sub count_statements {
	my ($self,$subject,$predicate,$object,$context) = @_;

	my $it = $self->{ldf}->get_statements($subject,$predicate,$object);

	my ($triples,$info) = $it->();

	$info->{hydra_totalItems};
}

sub size {
	shift->count_statements;
}

sub supports {
	undef;
}

1;

=head1 NAME

RDF::Trine::Store::LDF - RDF Store proxy for a Linked Data Fragment endpoint 

=head1 SYNOPSIS

    use RDF::Trine::Store::LDF;
	use RDF::Trine::Store;
	use RDF::Query;

	my $store = RDF::Trine::Store->new_with_config({
			storeclass => 'RDF::Trine::Store::LDF',
			url => $url
	});

	my $model =  RDF::Trine::Model->new($store);

	my $rdf_query = RDF::Query->new(<<EOF);
	.
	.
	SPARQL
	.
	.
	EOF

	my $iter = $rdf_query->execute($model);

	while (my $s = $iter->next) {
		print $s . "\n";
	}

=head1 DESCRIPTION

RDF::Trine::Store::LDF provides a RDF::Trine::Store API to interact with a remote 
Linked Data Fragment endpoint. For details see: <http://linkeddatafragments.org/>.

=head1 METHODS

Beyond the methods documented below, this class inherits methods from the L<RDF::Trine::Store> class.

=over 

=item new({ url => url })

Returns a new RDF::Trine::Store object that will act as a proxy for the Linked Data Fragment
endpoint accessible via the supplied $url.

=item new_with_config( $hashref )

Returns a new RDF::Trine::Store object configured by a hashref with the url as required key.

=item get_statements( $subject, $predicate, $object )

Returns a stream object of all statements matching the specified subject, predicate and objects. 
Any of the arguments may be undef to match any value.

=item get_pattern( $bgp )

Returns an iterator object of all bindings matching the specified graph pattern.

=item get_contexts

Not supported.

=item add_statement ( $statement [, $context] )

Not supported.

=item remove_statement ( $statement [, $context])

Not supported.

=item remove_statements ( $subject, $predicate, $object [, $context])

Not supported.

=item count_statements ( $subject, $predicate, $object )

Returns a count of all the statements matching the specified subject, predicate and object. 
Any of the arguments may be undef to match any value.

=item size

Returns the number of statements in the store.

=item supports ( [ $feature ] )

Not supported.

=back

=head1 AUTHOR

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=encoding utf8

=cut