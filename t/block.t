#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax 'say';

my $stdout = \*STDOUT;

stdout_is { say {$stdout} 23    } "23\n",       'say with block syntax and lexical filehandle';
stdout_is { say({$stdout} 23)   } "23\n",       'say with block syntax and explicit argument list';

{ no strict qw( subs refs );
  stdout_is { say {STDOUT} 23   } "23\n",       'say with block syntax and simple filehandle';
  stdout_is { say {*STDOUT} 23  } "23\n",       'say with block syntax and glob';
  stdout_is { say {\*STDOUT} 23 } "23\n",       'say with block syntax and glob ref';
}

done_testing;
