#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Output;
use syntax 'say';

sub NOHANDLE { shift }
sub CONST    { 17 }
sub CODEREF  { sub { 23 } }

stdout_is { say STDOUT 23       } "23\n",       'simple say with bareword handle'; 
stdout_is { say NOHANDLE(23)    } "23\n",       'bareword w/o space but declared sub';
stdout_is { say NOHANDLE (23)   } "23\n",       'bareword w/ space but declared sub';
stdout_is { say CONST           } "17\n",       'bareword only';
stdout_is { say CONST, 23       } "1723\n",     'bareword w/ comma';
stdout_is { say CODEREF ->()    } "23\n",       'dereferencing bareword result';
stdout_is { say FOO => 23       } "FOO23\n",    'autoquoting w/ space';
stdout_is { say FOO=>23         } "FOO23\n",    'autoquoting w/o space';
throws_ok { say STDOUT(23)      } qr/STDOUT/,   'invalid handle syntax';
stdout_is { say(STDOUT 23)      } "23\n",       'bareword handle with explicit argument list';

{ local $@;
  eval q(say STDOUT, 23);
  like $@, qr/no comma allowed/i, 'invalid comma after handle';
}

done_testing;
