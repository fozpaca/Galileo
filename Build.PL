use strict;
use warnings;

use 5.10.1;
use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Galileo',
  dist_author => 'Joel Berger',
  license => 'perl',
  
  requires => {
    'perl' => '5.10.1',
    'Mojolicious' => '3.92',  # RFC 6901 compliant json pointers in tests
    'Mojolicious::Plugin::Humane' => '0.04',
    'DBD::SQLite' => 0,
    'DBIx::Class' => 0,
    'DBIx::Class::Candy' => 0,
    'DBIx::Class::EncodedColumn' => 0,
    'DBIx::Class::DeploymentHandler' => 0,
    'Crypt::Eksblowfish::Bcrypt' => 0,
    'SQL::Translator' => 0,
    'Term::Prompt' => 0,
    'File::ShareDir' => 0,
    'File::Copy::Recursive' => 0,
    'File::Next' => 0,
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },

  share_dir => 'lib/Galileo/files',

  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Galileo",
      bugtracker => "http://github.com/jberger/Galileo/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
    },
  }
);

$builder->create_build_script;

