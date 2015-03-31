requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '1.001003';
  requires 'Test::Pod', 0;
  requires 'Test::LWP::UserAgent', '0.026';
};

requires 'Cache::LRU', '0.04';
requires 'Clone', '0.38';
requires 'Data::Compare', '1.25';
requires 'Data::Util', '0.63';
requires 'HTTP::Message', '6.06';
requires 'JSON', '2.90';
requires 'Log::Any', '1.03';
requires 'Moo', '1.004006';
requires 'RDF::NS', '20140910';
requires 'RDF::Query', '2.913';
requires 'RDF::Trine', '1.013';
requires 'Throwable', '0.200004';
requires 'URI::Escape', '1.65';
requires 'URI::Template', '0.21';

feature 'ldf-client', 'LDF command line client example' => sub {
    requires 'Tie::IxHash', '1.23';
    requires 'Getopt::Long', '2.44';
    requires 'File::Slurp::Tiny', '0.003';
};
