#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax 'say';

my $stdout = \*STDOUT;

stdout_is {
    say
    $stdout 23
} "23\n", 'multiline say with lexical handle';

stdout_is {
    say
    $stdout 
    23
} "23\n", 'ubermultiline say with lexical handle';

stdout_is {
    say 23;
    say 24;
} "23\n24\n", 'next statement still working';

done_testing;
