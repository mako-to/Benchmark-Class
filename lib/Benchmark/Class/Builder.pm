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
    GetOptions(
        'config=s'  => \my $config,
        'planner=s' => \my $planner,
        'task=s@'   => \my $tasks,
    );

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
__END__

=head1 NAME

benchup - Run Benchmark Plan with Benchmark::Class

=head1 SYNOPSIS

  % benchup --planner=MyApp::Benchmark::Planner::SimpleGetPost
  % benchup --config=config/simple-get-post-1000.json
  {
    "planner": {
      "class": "MyApp::Benchmark::Plan::SimpleGetPost",
      "args": {
          "post": 1000,
          "get":  1000,
      },
    }
  }

  # ex. planner class
  package MyApp::Benchmark::Planner::SimpleGetPost {
      use parent 'Benchmark::Class::Planner';

      sub launch {
          my ($self, $c) = @_;
          # is ref($c), Benchmark::Class::Context;

          # your code here..

          my $task = MyApp::Benchmark::Task::GetEntry->new(
              get    => 1000,
              worker => 8,
          );
          $task->perform;
      }
  }

  % benchup --task=MyApp::Benchmark::Task::GetEntry --task=MyApp::Benchmark::Task::PostEntry
  % benchup --config=config/simple-get-post-1000.json
  {
    "tasks": [
        {
            "class": "MyApp::Benchmark::Task::GetEntry",
            "args": {
                "get": 1000,
                "worker": 8,
            },
        },
        {
            "class": "MyApp::Benchmark::Task::PostEntry",
            "args": {
                "post": 1000,
                "worker": 8,
            },
        },
    ],
  }

  # ex. task class
  package MyApp::Benchmark::Task::GetEntry {
      use parent 'Benchmark::Class::Task';

      # if $self->worker enabled, perform with prefork

      sub perform {
          my ($self, $c) = @_;
          # is ref($c), Benchmark::Class::Context;

          # your code here..
      }
  }

=head1 TODO

# http_agent with AnyEvent::HTTP or FurlX::Coro or mechanized Furl
# test
