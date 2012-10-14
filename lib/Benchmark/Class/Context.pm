package Benchmark::Class::Context;

use strict;
use warnings;
use Class::Accessor::Lite::Lazy (
    new => 1,
    rw => [qw/config planner/],
);

1;
