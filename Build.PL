#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::FixtureBuilder',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Carp'              => 0,
        'Exporter::Declare' => 0,
        'Scalar::Util'      => 0,
    },
    recommends => {
    },
    build_requires => {
        'DBD::SQLite' => '1.40',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Test-FixtureBuilder',
            bugtracker  => 'http://github.com/exodist/Test-FixtureBuilder/issues',
        },
    },
);

$build->create_build_script;
