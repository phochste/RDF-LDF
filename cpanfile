requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Deep', '0';
  requires 'Test::Exception', '0';
  requires 'Test::More', '0';
  requires 'Test::Pod', 0;
  requires 'Test::LWP::UserAgent', '0';
};

requires 'Cache::LRU', '0';
requires 'Clone', '0';
requires 'Data::Compare', '1.22';
requires 'Data::Util', '0.59';
requires 'Getopt::Long', '0';
requires 'HTTP::Message', '0';
requires 'JSON', '0';
requires 'Log::Any', '1.00';
requires 'Moo', '1.004006';
requires 'RDF::NS', '20120827';
requires 'RDF::Query', '2.913';
requires 'RDF::Trine', '1.013';
requires 'Throwable', '0.102080';
requires 'URI::Escape', '0';
requires 'URI::Template', '0';
