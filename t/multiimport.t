#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax say => { -as => 'say1' }, say => { -as => 'say2' };

stdout_is { say1 23 } "23\n", 'first import';
stdout_is { say2 23 } "23\n", 'second import';

done_testing;
