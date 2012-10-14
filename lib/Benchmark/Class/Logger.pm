package Benchmark::Class::Logger;

use strict;
use warnings;
use Log::Minimal ();
use Exporter::Lite;

our @EXPORT = qw(DEBUG INFO WARN CRIT CROAK);

our $PRINT ||= sub {
    my ($time, $type, $message, $trace, $raw_message) = @_;
    warn "$time [$type] $message @ $trace\n";
};

$Log::Minimal::PRINT = sub { goto $PRINT };
$Log::Minimal::ENV_DEBUG = 'INTEREST_DEBUG';
$Log::Minimal::AUTODUMP  = 1;

foreach my $level (@EXPORT) {
    no strict 'refs';
    *$level = Log::Minimal->can(lc $level . 'f');
}

1;
