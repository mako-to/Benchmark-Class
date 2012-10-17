package Benchmark::Class::Task;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new => 1,
    rw  => [qw/worker/],
    ro_lazy => [qw/worker_manager memcached/],
    rw_lazy => [qw/max_perfom_per_child/],
);
use Benchmark::Class::Counter;
use Parallel::Prefork;
use Scalar::Util qw(refaddr);
use Smart::Args;

sub times_before_exit { 100 }

sub _build_worker_manager {
    my $self = shift;
    return Parallel::Prefork->new({
        max_workers => $self->worker || 4,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });
}

sub _build_memcached {
    my $self = shift;
    require Cache::Memcached::Fast;
    my $cache = Cache::Memcached::Fast->new({
        servers   => [ { address => 'localhost:11211' } ], #XXX configable
        namespace => 'benchmark:',
        io_timeout      => 0.1,
    });

    # check connection
    my $success = 0;
    defined $cache->set('__test', 1, 10) && $success++ for 1 .. 5;
    die "Can't connect memcached" unless $success;

    return $cache;
}

sub _build_max_perfom_per_child { 100 }

my $_counter = {};
sub counter {
    args my $self,
         my $name => { optional => 1, default => '_perform' };

    unless ( exists $_counter->{$name} ) {
        my $counter_key = join ':', $name, refaddr($self);
        $_counter->{$name} = Benchmark::Class::Counter->new(
            counter_key => $counter_key,
            memcached   => $self->memcached, # XXX memd 以外でも使えるようにする
        );
    }
    return $_counter->{$name};
}

sub is_finished { return 1 }

sub load {
    my $self = shift;

    local $SIG{USR1} = sub {
        if ( $self->is_finished ) {
            $self->worker_manager->signal_all_children(15);
            exit 0; # child プロセスが終わったら exit したい
        }
    };

    while ( $self->worker_manager->signal_received ne 'TERM' ) {
        $self->worker_manager->start and next;

        my $times_before_exit = $self->max_perfom_per_child;
        $SIG{TERM} = sub { $times_before_exit = 0 };
        while ( $times_before_exit > 0 ) {
            kill USR1 => $self->worker_manager->manager_pid;
            $self->counter->incr;
            --$times_before_exit;

            $self->perform(@_);
        }
        $self->worker_manager->finish;
    }
    $self->worker_manager->wait_all_children;
};

1;
