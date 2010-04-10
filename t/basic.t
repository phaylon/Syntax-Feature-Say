#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax 'say';
use syntax say => { -as => 'printn' };

my @ls = (1, 2, 3);

stdout_is { printn 23           } "23\n",       'aliasing with -as';
stdout_is { say 23              } "23\n",       'simplest say';
stdout_is { say @ls             } "123\n",      'say array';

stdout_is { say } "\n", 'without arguments';

{ my @result;
  stdout_is { 
      @result = (say(2, 3, 4), 23);
  } "234\n", 'say with parens';
  note explain 'Returned ', \@result;
  is_deeply \@result, [1, 23], 'correct argument capture';
}

stdout_is { say 17; say 23 } "17\n23\n", 'multiple per line';

done_testing;
