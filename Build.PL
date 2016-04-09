#!perl
use strict;
use warnings;
use Module::Build::Compat;
use Module::Build::Pluggable 'CPANfile';

my $builder = Module::Build::Pluggable->new(
    module_name       => 'DBIx::Model',
    create_license    => 1,
    create_readme     => 1,
    license           => 'GPL_3',
    dist_author       => 'Mark Lawrence <nomad@null.net>',
    dist_version_from => 'lib/DBIx/Model.pm',
    no_index          => {
        package => [],
    },
    recursive_test_files => 1,
    add_to_cleanup       => [ 'db-*', '*.bak', 'blib', 'Makefile' ],
    meta_merge           => {
        resources => {
            bugtracker => 'https://github.com/mlawren/p5-DBIx-Model/issues',
            repository => 'git://github.com/mlawren/p5-DBIx-Model.git',
            homepage   => 'https://github.com/mlawren/p5-DBIx-Model',
        },
        keywords => [],
    },
);

$builder->create_build_script();

# I prefer to use make when developing so lets built the Makefile here
# as well
#Module::Build::Compat->create_makefile_pl( 'small', $builder );
Module::Build::Compat->write_makefile( build_class => 'Module::Build' );
