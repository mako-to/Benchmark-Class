package Benchmark::Class::Task;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new => 1,
    rw  => [qw/worker/],
    lazy_ro => [qw/worker_manager/],
);
use Parallel::Prefork;

sub _build_worker_manager {
    my $self = shift;
    return Parallel::Prefork->new({
        max_workers => $self->worker || 1,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
            USR1 => undef,
        },
    });
}

sub load {
    my ($self, $c) = @_;

    while ( $self->worker_manager->signal_received ne 'TERM' ) {
        $self->worker_manager->start(sub { $self->perform($c) });
        # XXX MaxRequestsPerChild 的なことしといたほうがいいかな
    }

    $self->worker_manager->wait_all_children;
}

1;
