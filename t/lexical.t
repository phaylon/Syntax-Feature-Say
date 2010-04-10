#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax 'say';

my $stdout = \*STDOUT;
my %hash   = (out => 99);
my @array  = (777);
my $ref    = \%hash;
my $key    = 'foo';
my $num    = 23;

stdout_is { say $stdout 23      } "23\n",       'simple say with scalar handle';
stdout_is { say $hash{out}      } "99\n",       'say with scalar hash access';
stdout_is { say $hash {out}     } "99\n",       'say with scalar hash access w/ space';
stdout_is { say $array[0]       } "777\n",      'say with scalar array access';
stdout_is { say $array [0]      } "777\n",      'say with scalar array access w/ space';
stdout_is { say $ref ->{out}    } "99\n",       'say with scalar hash ref deref w/ space';
stdout_is { say $key => 23      } "foo23\n",    'say with scalar pair key w/ space';
stdout_is { say $key=>23        } "foo23\n",    'say with scalar pair key w/o space';
stdout_is { say $key,23         } "foo23\n",    'say with scalar and comma';
stdout_is { say $key , 23       } "foo23\n",    'say with scalar and comma w/ spaces';
stdout_is { say $num+7          } "30\n",       'say with op w/o spaces';
stdout_is { say $stdout +7      } "7\n",        'say with op w/ space';
stdout_is { say $num + 7        } "30\n",       'say with op w/ more spaces';
stdout_is { say($stdout 23)     } "23\n",       'say with scalar handle and explicit argument list';

done_testing;
