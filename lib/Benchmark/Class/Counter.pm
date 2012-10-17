package Benchmark::Class::Counter;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new => 1,
    rw  => [qw/memcached counter_key/],
);
use Class::Method::Modifiers;

around new => sub {
    my $orig = shift;
    my $self = $orig->(@_);
    $self->memcached->add( $self->counter_key => 0 );
    return $self;
};

sub incr {
    my $self = shift;
    return $self->memcached->incr( $self->counter_key );
}

sub decr {
    my $self = shift;
    return $self->memcached->decr( $self->counter_key );
}

sub count {
    my $self = shift;
    return $self->memcached->get( $self->counter_key ) || 0;
}

1;
