package Benchmark::Class::Builder;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new     => 1,
    ro_lazy => [qw/context/],
    rw_lazy => [qw/tasks/],
);
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Carp;
use Module::Load;
use JSON;

my $json = JSON->new->allow_nonref->relaxed(1);

sub _build_context {
    my $self = shift;
    require Benchmark::Class::Context;
    return Benchmark::Class::Context->new;
}

sub _build_tasks {
    my $self = shift;
    return [];
}

sub parse_options {
    my $self = shift;

    local @ARGV = @_;
    # From 'prove': Allow cuddling the paths with -I, -M
    @ARGV = map { /^(-[IM])(.+)/ ? ($1,$2) : $_ } @ARGV;

    GetOptions(
        'config=s'  => \my $config,
        'planner=s' => \my $planner,
        'task=s@'   => \my $tasks,
        'I=s@'      => \my $includes,
        'M=s@'      => \my $modules,
    );

    if (@{ $includes || [] }) {
        require lib;
        lib->import(@$includes);
    }

    for (@{ $modules || [] }) {
        my($module, @import) = split /[=,]/;
        load $module;
    }

    if ($config) {
        open my $config_fh, '<', $config or croak $!;
        my $string = do { local $/; <$config_fh> };
        close $config_fh;

        $self->context->config( $json->decode($string) );

        my $planner_config = $self->context->config->{planner};
        if ($planner_config) {
            load $planner_config->{class};
            $self->context->planner(
                $planner_config->{class}->new($planner_config->{args})
            );
        }

        my $task_config = $self->context->config->{tasks} || [];
        for my $task (@$task_config) {
            load $task;
            push @{ $self->tasks }, $task->new( $task->{args} );
        }
    }

    if ($planner) {
        load $planner;
        $self->context->planner($planner->new);
    }

    for my $task (@$tasks) {
        # XXX すでに config に task があるときどうするのがいいか
        # 1. config における task を破棄
        # 2. 新しい task を追加

        load $task;
        push @{ $self->tasks }, $task->new;
    }
}

sub run {
    my $self = shift;

    if ( $self->context->planner ) {
        return $self->context->planner->launch($self->context);
    }

    for my $task ( @{ $self->tasks } ) {
        $task->load($self->context);
    }
}

1;
