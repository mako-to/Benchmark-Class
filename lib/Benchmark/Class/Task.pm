package Benchmark::Class::Task;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new => 1,
    rw  => [qw/worker/],
    lazy_ro => [qw/worker_manager/],
);
use Parallel::Prefork;
use Role::Tiny;

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

sub perform_count : lvalue {
    my $self = shift;
    $self->{_perform_count} = 0 unless exists $self->{_perform_count};
    return $self->{_perform_count};
}

sub is_finished { return 1 }

before perform => sub { shift->perform_count++ };

sub load {
    my $self = shift;

    while ( $self->is_finished && $self->worker_manager->signal_received ne 'TERM' ) {
        $self->worker_manager->start(sub { $self->perform(@_) });
        # XXX MaxRequestsPerChild 的なことしといたほうがいいかな
    }
    $self->worker_manager->wait_all_children;
};

1;
