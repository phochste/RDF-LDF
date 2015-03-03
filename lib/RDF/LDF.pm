package RDF::LDF;

use strict;
use warnings;
use feature qw(state);
use utf8;

use Moo;
use Data::Util qw(:check);
use Data::Compare;
use RDF::NS;
use RDF::Trine;
use RDF::Query;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request::Common;
use Log::Any ();
use Cache::LRU;
use Clone qw(clone);
use Data::Dumper;
use JSON;
use URI::Template;
use RDF::LDF::Error;

our $VERSION = '0.05';
{
   my $ua   = RDF::Trine->default_useragent;
   $ua->agent("RDF:::LDF/$RDF::LDF::VERSION " . $ua->_agent);
}

has url => (
    is => 'ro' ,
    required => 1
);

has sn => (
    is     => 'ro' ,
    lazy   => 1,
    builder => sub {
        RDF::NS->new->REVERSE;
    }
);

has query_pattern => (
    is      => 'ro',
    lazy    => 1,
    builder => 'get_query_pattern'
);

has lru => (
    is     => 'ro' ,
    lazy   => 1,
    builder => sub {
        Cache::LRU->new( size => 100 );
    }
);

has log => (
    is    => 'ro',
    lazy  => 1,
    builder => sub {
        Log::Any->get_logger(category => ref(shift));
    }
);

# Public method
sub is_fragment_server {
    shift->query_pattern ? 1 : 0;
}

# Public method
# Optimized method to find all bindings matching a pattern
# See:
# Verborgh, Ruben, et al. Querying Datasets on the Web with High Availability. ISWC2014
# http://linkeddatafragments.org/publications/iswc2014.pdf
sub get_pattern {
    my ($self,$bgp,$context,%args) = @_;

    unless (defined $bgp) {
       RDF::LDF::Error->throw(text => "can't execute get_pattern for an empty pattern");
    }

    my (@triples)   = ($bgp->isa('RDF::Trine::Statement') or $bgp->isa('RDF::Query::Algebra::Filter'))
                    ? $bgp
                    : $bgp->triples;

    unless (@triples) {
        RDF::LDF::Error->throw(text => "can't execute get_pattern for an empty pattern");
    }

    my @vars = $bgp->referenced_variables;

    my @bgps = map { $self->_parse_triple_pattern($_)} @triples;
    
    my $sub = sub {
        state $it = $self->_find_variable_bindings(\@bgps);
        my $b = $it->();

        return undef unless $b;

        my $binding = RDF::Trine::VariableBindings->new({});

        for my $key (keys %$b) {
            my $val = $b->{$key};
            $key =~ s{^\?}{};
            $binding->set($key => $val);
        }

        $binding;
    };

    RDF::Trine::Iterator::Bindings->new($sub,\@vars);
}

sub _find_variable_bindings {
    my $self     = shift;
    my $bgps     = shift;
    my $bindings = shift // {};

    my $iterator = sub {
        state $it;
        state $results = sub {};

        my $ret;

        # Loop over all variabe bindinfgs with multiple matches
        while (!defined($ret = $results->())) {
            unless (defined $it) {
                # Find the an binding iterator for the best pattern from $bgpgs
                ($it,$bgps) = $self->_find_variable_bindings_($bgps);

                return undef unless $it;
            }

            # Update all the other bgps with the current binding..
            my $this_binding = $it->();

            return undef unless $this_binding;

            $bindings = { %$bindings , %$this_binding };

            return $bindings unless @$bgps;

            # Apply all the bindings to the rest of the bgps;
            my $bgps_prime = $self->_apply_binding($this_binding,$bgps);

            $results = $self->_find_variable_bindings($bgps_prime,$bindings);
        }
        
        $ret;
    };

    $iterator;
}

# Given an array ref of patterns return the variable bindings for the
# pattern with the least number of triples.
#
#  my ($iterator, $rest) = $self->_find_variable_bindings([ {pattern} , {pattern} , ... ]);
#
#  where:
# 
#  $iterator - Iterator for variable bindings for the winnnig pattern, or undef when no
#              patterns are provided or we get zero results
#              
#  $rest     - An array ref of patterns not containing the best pattern
sub _find_variable_bindings_ {
    my ($self,$bgps) = @_;

    return (undef, undef) unless is_array_ref($bgps) && @$bgps > 0;

    my ($pattern,$rest) = $self->_find_best_pattern($bgps);

    return (undef,undef) unless defined $pattern;

    my $it = $self->get_statements($pattern);

    # Build a mapping of variable bindings to Triple nodes. E.g.
    # {
    #    '?s' => 'subject' ,
    #    '?p' => 'predicate'  ,
    #    '?o' => 'object' ,
    #}
    my %pattern_var_map = map { $pattern->{$_} =~ /^\?/ ? ($pattern->{$_} , $_) : () } keys %$pattern;
    my $num_of_bindings = keys %pattern_var_map;

    my $sub = sub {
        my $triple = $it->();

        return undef unless defined $triple;

        my %var_map = %pattern_var_map;

        for (keys %var_map) {
            my $method   = $var_map{$_};
            $var_map{$_} = $triple->$method;
        }

        return {%var_map};
    };

    return ($sub,$rest);
}

sub _apply_binding {
    my ($self,$binding,$bgps) = @_;

    return unless is_array_ref($bgps) && @$bgps > 0;

    my $copy = clone $bgps;
    my @new  = ();

    for my $pattern (@$copy) {
        for (qw(subject predicate object)) {
            my $val = $pattern->{$_};
            if (defined($val) && $binding->{$val}) {
                my $str_val    = $self->_node_as_string($binding->{$val});
                $pattern->{$_} = $str_val
            }
        }
        push @new, $pattern;
    }

    return \@new;
}

# Create a pattern which binds to the graph pattern
#
# Usage:
#
#    my $triples = [
#              { subject => ... , predicate => ... , object => ... } , #tp1
#              { subject => ... , predicate => ... , object => ... } , #tp2
#              ...
#              { subject => ... , predicate => ... , object => ... } , #tpN
#    ];
#
#    my ($pattern, $rest) = $self->_find_best_pattern($triples);
#
#    $pattern => Pattern in $triples which least ammount of results
#    $rest    => All patterns in $triples except $pattern      
#  
sub _find_best_pattern {
    my ($self,$triples) = @_;

    return undef unless @$triples > 0;

    # If we only have one tripple pattern, the use it to create the bind
    if (@$triples == 1) {
        return $triples->[0] , [];
    }

    my $best_pattern = undef;
    my $best_count   = undef;

    for my $pattern (@$triples) {
        my $count = $self->_total_triples($pattern) // 0;

        if ($count == 0) {
            $best_pattern = undef;
            $best_count   = 0;
            last;
        }
        elsif (!defined $best_count || $count < $best_count) {
            $best_count   = $count;
            $best_pattern = $pattern;
        }
    }   

    return (undef,$triples) unless defined $best_pattern;

    my @rest_triples = map { Data::Compare::Compare($_,$best_pattern) ? () : ($_) } @$triples;

    return ($best_pattern, \@rest_triples);
}

# Find the total number of triples available for a pattern
#
# Usage:
#
#    my $count = $self->_total_triples(
#                { subject => ... , predicate => ... , object => ...}
#                );
# Where 
#       $count is a number
sub _total_triples {
    my ($self,$pattern) = @_;

    # Retrieve one...
    my $iterator = $self->get_statements($pattern);

    return 0 unless $iterator;

    my ($model,$info) = $iterator->();

    $info->{hydra_totalItems};
}

sub _node_as_string {
    my $self    = shift;
    my $node    = shift;
    if (is_invocant($node) && $node->isa('RDF::Trine::Node')) {
        if ($node->isa('RDF::Trine::Node::Variable')) {
            return $node->as_string; # ?foo
        } elsif ($node->isa('RDF::Trine::Node::Literal')) {
            return $node->as_string; # includes quotes and any language or datatype
        } else {
            return $node->value; # the raw IRI or blank node identifier value, without other syntax
        }
    }
    return '';
}

# For an BGP triple create a fragment pattern
sub _parse_triple_pattern {
    my ($self,$triple) = @_;
    my $subject   = $self->_node_as_string($triple->subject);
    my $predicate = $self->_node_as_string($triple->predicate);
    my $object    = $self->_node_as_string($triple->object);
    my $hash      = {
        subject   => $subject ,
        predicate => $predicate,
        object    => $object
    };
    return $hash;
}

# Dynamic find out which triple patterns need to be used to query the fragment server
# Returns a hash:
# {
#   rdf_subject   => <name_of_subject_variable> ,
#   rdf_predicate => <name_of_predicate_variable> ,
#   rdf_object    => <name_of_object_variable>
#   void_uriLookupEndpoint => <endpoint_for_tripple_pattern>
# }
sub get_query_pattern {
    my ($self) = @_;
    my $url      = $self->url;

    my $fragment = $self->get_model_and_info($url);

    return undef unless defined $fragment;

    my $info  = $fragment->{info};

    my $pattern;

    return undef unless is_hash_ref($info);

    return undef unless $info->{void_uriLookupEndpoint};

    for (keys %$info) {
        next unless is_hash_ref($info->{$_}) && $info->{$_}->{hydra_property};
        my $property = join "_" , $self->sn->qname($info->{$_}->{hydra_property});
        my $variable = $info->{$_}->{hydra_variable};

        $pattern->{$property} = $variable;
    }

    return undef unless $pattern->{rdf_subject};
    return undef unless $pattern->{rdf_predicate};
    return undef unless $pattern->{rdf_object};

    $pattern->{void_uriLookupEndpoint} = $info->{void_uriLookupEndpoint};

    $pattern;
}

#----------------------------------------------------------------------------------

# Public method
sub get_statements {
    my ($self,@triple) = @_;
    my ($subject,$predicate,$object);

    if (@triple == 3) {
        ($subject,$predicate,$object) = @triple;
    }
    elsif (is_hash_ref($triple[0])) {
        $subject   = $triple[0]->{subject};
        $predicate = $triple[0]->{predicate};
        $object    = $triple[0]->{object};
    }

    $subject    = $subject->value if (is_invocant($subject) && $subject->isa('RDF::Trine::Node') and not $subject->is_variable);
    $predicate    = $predicate->value if (is_invocant($predicate) && $predicate->isa('RDF::Trine::Node') and not $predicate->is_variable);
    if (is_invocant($object) && $object->isa('RDF::Trine::Node') and not $object->is_variable) {
        $object    = ($object->isa('RDF::Trine::Node::Literal')) ? $object->as_string : $object->value;
    }
    
    my $pattern = $self->query_pattern;
    return undef unless defined $pattern;
    
    my %params;
    $params{ $pattern->{rdf_subject} }   = $subject if is_string($subject);
    $params{ $pattern->{rdf_predicate} } = $predicate if is_string($predicate);
    $params{ $pattern->{rdf_object} }    = $object if is_string($object);
    
    my $template    = URI::Template->new($pattern->{void_uriLookupEndpoint});
    my $url            = $template->process(%params)->as_string;

    my $sub = sub {
        state $model;
        state $info;
        state $iterator;

        unless (defined $model) {
            return unless defined $url;

            my $fragment = $self->get_model_and_info($url);

            return unless defined $fragment->{model};

            $model    = $fragment->{model};
            $info     = $fragment->{info};

            $url      = $info->{hydra_nextPage};
            $iterator = $model->get_statements;
        }

        my $triple = $iterator->next;

        unless ($iterator->peek) {
            $model = undef;
        }

        wantarray ? ($triple,$info) : $triple;
    };

    $sub;
}

# Fetch a fragment page and extract the metadata
sub get_model_and_info {
    my ($self,$url) = @_;

    if (my $cache = $self->lru->get($url)) {
         return $cache;
    }

    my $model = $self->get_fragment($url);
    my $info  = {};

    if (defined $model) {
        $info = $self->_model_metadata($model,$url, clean => 1);
    }

    my $fragment = { model => $model , info => $info };

    $self->lru->set($url => $fragment);

    $fragment;
}

# Fetch a result page from fragment server
sub get_fragment {
    my ($self,$url) = @_;

    return undef unless $url;

    $self->log->info("fetching: $url");

    my $model  = RDF::Trine::Model->temporary_model;
    eval {
        RDF::Trine::Parser->parse_url_into_model($url, $model);
    };
    
    if ($@) {
        $self->log->error("failed to parse input");
        return undef;
    }
    
    return $model;
}

# Create a hash with fragment metadata from a RDF::Trine::Model
# parameters:
#    $model    - RDF::Trine::Model
#    $this_uri - result page URL
#    %opts
#        clean => 1 - remove the metadata from the model 
sub _model_metadata {
    my ($self,$model,$this_uri,%opts) = @_;

    my $info = {};

    $self->_build_metadata($model, {
        subject => RDF::Trine::Node::Resource->new($this_uri)
    } , $info);

    if ($opts{clean}) {
        $model->remove_statements(
            RDF::Trine::Node::Resource->new($this_uri),
            undef,
            undef
        );
        $model->remove_statements(
            undef,
            undef,
            RDF::Trine::Node::Resource->new($this_uri)
        );
    }

    for my $predicate (
        'http://www.w3.org/ns/hydra/core#variable' ,
        'http://www.w3.org/ns/hydra/core#property' ,
        'http://www.w3.org/ns/hydra/core#mapping'  ,
        'http://www.w3.org/ns/hydra/core#template' ,
        'http://www.w3.org/ns/hydra/core#member'   ,
    ) {
        $self->_build_metadata($model, {
            predicate => RDF::Trine::Node::Resource->new($predicate)
        }, $info);

        if ($opts{clean}) {
            $model->remove_statements(
                    undef,
                    RDF::Trine::Node::Resource->new($predicate) ,
                    undef);
        }
    }

    my $source = $info->{dct_source}->[0] if is_array_ref($info->{dct_source});

    if ($source) {
        $self->_build_metadata($model, {
            subject => RDF::Trine::Node::Resource->new($source)
        }, $info);

        if ($opts{clean}) {
            $model->remove_statements(
                RDF::Trine::Node::Resource->new($source),
                undef,
                undef
            );
            $model->remove_statements(
                undef,
                undef,
                RDF::Trine::Node::Resource->new($source)
            );
        }
    }

    $info;
}

# Helper method for _parse_model
sub _build_metadata {
    my ($self, $model, $triple, $info) = @_;
    
    my $iterator = $model->get_statements(
        $triple->{subject},
        $triple->{predicate},
        $triple->{object}
    );

    while (my $triple = $iterator->next) {
        my $subject   = $triple->subject->as_string;
        my $predicate = $triple->predicate->uri_value;
        my $object    = $triple->object->value;

        my $qname = join "_" , $self->sn->qname($predicate);

        if ($qname =~ /^(hydra_variable|hydra_property)$/) {
            my $id= $triple->subject->value;

            $info->{"_$id"}->{$qname} = $object;
        }
        elsif ($qname eq 'hydra_mapping') {
            my $id= $triple->subject->value;

            push @{$info->{"_$id"}->{$qname}} , $object;
        }
        elsif ($qname =~ /^(void|hydra)_/) {
            $info->{$qname} = $object;
        }
        else {
            push @{$info->{$qname}} , $object;
        }
    }

    $info;
}

1;

__END__

=head1 NAME

RDF::LDF - Linked Data Fragments client

=head1 SYNOPSIS

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


=head1 DESCRIPTION

The RDF::LDF  module is a basic implementation of a Linked Data Fragment client. For details see:
<http://linkeddatafragments.org/>.

This a low level module to implement the Linked Data Fragment protocol. You probably want to
use L<RDF::Trine::Store::LDF>.

=head1 CONFIGURATION

=over

=item url

URL to retrieve RDF from.

=back

=head1 METHODS

=over 

=item get_statements( $subject, $predicate, $object )

Return an iterator for every RDF::Trine::Statement served by the LDF server.

=item get_pattern( $bgp );

Returns a stream object of all bindings matching the specified graph pattern.

=back

=head1 AUTHOR

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=head1 CONTRIBUTORS

Gregory Todd Williams, C<< greg@evilfunhouse.com >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of either: 
the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=encoding utf8

=cut
