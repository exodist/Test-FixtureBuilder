package Test::FixtureBuilder;
use strict;
use warnings;

our $VERSION = '0.001';

use Exporter::Declare;

use Scalar::Util qw/blessed/;
use Carp qw/croak confess/;

gen_default_export FIXTURE_BUILDER_META => sub {
    my ($exporter, $importer) = @_;

    my $meta = { class => $exporter };
    return sub { $meta };
};

default_export fixture_db => sub {
    my $caller = caller;
    my ($name, $code) = @_;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    croak "Cannot set db to '$name', already set to '$meta->{db}'"
        if exists $meta->{db};
    $meta->{db} = $name;

    my $dbh = $meta->{class}->name_to_handle($name);
    croak "Could not get db handle for '$name'"
        unless $dbh;

    $meta->{dbh} = $dbh;

    $meta->{builder} = $meta->{class}->new(%$meta);

    my $success = eval { $code->($meta->{builder}); 1 };
    my $error = $@;

    delete $meta->{$_} for qw/db dbh builder/;

    die $error || "Unknown Error"
        unless $success;

    return $dbh;
};

default_export fixture_table => sub {
    my $caller = caller;
    my ($name, $code) = @_;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    croak "Cannot set table to '$name', already set to '$meta->{table}'"
        if exists $meta->{table};
    $meta->{table} = $name;

    my $success = eval { $code->($meta->{builder}, $name); 1 };
    my $error = $@;

    delete $meta->{$_} for qw/table/;

    die $error || "Unknown Error"
        unless $success;

    return $name;
};

default_export fixture_row => sub {
    my $caller = caller;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    my $row = @_ > 1 ? {@_} : $_[0];

    return $meta->{builder}->insert_row( $meta->{table} => $row );
};

sub after_import {
    my $class = shift;
    my ($importer, $specs) = @_;
    $importer->FIXTURE_BUILDER_META->{class} = $class;
}

sub name_to_handle {
    my $class = shift;
    my ($name) = @_;

    return $name if blessed $name;

    croak "I don't know how to convert '$name' to a database handle, override name_to_handle()";
}

sub new {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;

    for my $field ( keys %params ) {
        croak "'$field' is not a valid accessor for '$class'"
            unless $self->can($field);

        $self->$field($params{$field});
    }

    return $self;
}

for my $field (qw/db dbh class table/) {
    my $accessor = sub {
        my $self = shift;

        croak "Accessor '$field' called without instance!"
            unless blessed $self && $self->isa( __PACKAGE__ );

        $self->{$field} = @_ if @_;

        return $self->{$field};
    };
    no strict 'refs';
    *$field = $accessor;
}

sub load {
    my $self = shift;

    croak "load() can only be used when the table is set"
        unless $self->table;

    for my $row (@_) {
        $self->insert_row( $self->table, $row );
    }

    return;
}

sub insert_row {
    my $self = shift;
    my ($table, $row) = @_;

    my $dbh = $self->dbh || croak "No database handle set!";

    my $quoted_table = $dbh->quote_identifier(undef, undef, $table);
    my @vals = values %$row;
    my $cols = join ',' => map { '`' . $dbh->quote_identifier($_) . '`' } keys %$row;
    my $vals = join ',' => map { '?' } @vals;

    my $sth = $dbh->prepare("INSERT INTO $quoted_table ($cols) VALUES($vals)");
    $sth->execute(@vals);

    return eval { $dbh->last_insert_id } || 0;
}

1;
