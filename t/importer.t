#!/usr/bin/perl
use strict;
use warnings;

use Fennec class => 'Test::FixtureBuilder';

BEGIN {
    require_ok $CLASS;
    package MyFixtureBuilder;
    use Carp qw/croak/;

    use base $main::CLASS;

    sub name_to_handle {
        my $class = shift;
        my ($name) = @_;

    }
}

BEGIN { MyFixtureBuilder->import }

tests can_we_fix_it => sub {
    my $self = shift;
    can_ok( $self, qw/fixture_db fixture_table fixture_row/ );
};

tests full_stack => sub {
    my $self = shift;

    # Assert no rows

    fixture_db test => sub {
        fixture_table A => sub {
            fixture_row { a => 1, b => 1 };
            fixture_row { a => 2, b => 2 };
            fixture_row { a => 3, b => 3 };
        };

        fixture_table B => sub {
            fixture_row { a => 1, b => 1 };
            fixture_row { a => 2, b => 2 };
            fixture_row { a => 3, b => 3 };
        };
    };

    # Assert all rows
};

done_testing;
