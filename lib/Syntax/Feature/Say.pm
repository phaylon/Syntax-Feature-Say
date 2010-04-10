use strict;
use warnings;

# ABSTRACT: Add a 'say' keyword to pre-5.10 perls

package Syntax::Feature::Say;

use Carp                            qw( croak );
use Devel::Declare                  ();
use Devel::Declare::Context::Simple;
use PPI::Document;
use B::Compiling;

use namespace::clean;

sub install {
    my ($class, %args) = @_;

    # initialise options
    my $target  = $args{into};
    my $options = $args{options};
    my $name    = $options->{ -as } || 'say';

    # check identifier validity
    croak qq(Invalid say keyword identifier '$name')
        unless $name =~ m{\A[_a-z][_a-z0-9]*\Z}i;

    # setup handler for declarations
    Devel::Declare->setup_for(
        $target => { 
            $name => { 
                const => sub {
                    my $ctx = Devel::Declare::Context::Simple->new;
                    $ctx->init(@_);
                    $class->_parse($ctx, $target, (caller)[2]);
                },
            },
        },
    );

    ## no critic
    # setup value passthrough
    no strict 'refs';
    *{ "${target}::${name}" } = sub ($) { shift };
}

sub _parse {
    my ($class, $ctx, $target, $line_offset) = @_;

    my $line_num    = PL_compiling->line;
    my $orig_offset = $ctx->offset;
    my $prefix      = substr($ctx->get_linestr, 0, $orig_offset);

    # locate a usable document
    my $doc = $class->_locate_document_snippet($ctx);

    # split our own statement out of all others that were there
    my ($own, @foreign) = $doc->children;

    # snip out declarator
    my $declarator = $own->remove_child($own->first_element);

    # detect if there was a semicolon at the end
    my $join_by = '';
    if (my $last_element = $own->last_element) {
        
        if ($last_element->isa('PPI::Token::Structure') and $last_element eq ';') {

            $own->remove_child($last_element);
            $join_by = ';';
        }
    }

    # transform our own statement into the code we want
    my $new_code = $class->_handle_statement($own);

    # find what the parser left over
    my $rest = $ctx->get_linestr;

    # build new line content
    my $line = join '', 
        "$declarator ", 
        $new_code, 
        $join_by, 
        @foreign;

    # inject our code together with surrounding leftovers
    $ctx->set_linestr($prefix . $line . $rest);

    warn "LINE:\n" . $ctx->get_linestr . "\n"
        if $ENV{SAY_DEBUG_CALL};

    # return a value pass-through
    return $ctx->shadow(sub ($) { warn "SAY[@_]\n" if $ENV{SAY_DEBUG_CALL}; 1 });
}

sub _handle_statement {
    my ($class, $statement) = @_;

    # join with comma by default
    my $joiner = PPI::Token::Operator->new(',');

    # don't use a comma if there's nothing else printed
    unless ($statement->schildren) {

        $joiner = PPI::Token::Whitespace->new(' ');
    }

    # also possibly deal with an explicit argument list
    my $append  = '';
    my $newline = '';
    my $explicit;
    if (    $statement->schildren 
        and $statement->schild(0)->isa('PPI::Structure::List')
    ) {

        # remember overhang and use list as actual arguments
        $append    = $statement;
        $statement = $append->remove_child($statement->schild(0));
        $explicit++;

        # inject newline into list
        $statement->add_element($_) for
            $joiner,
            PPI::Token::Whitespace->new(' '),
            PPI::Token::Quote::Single->new(q("\n"));
    }

    # newline can be normally added, we're building the list ourselves
    else {

        $newline   = q( "\n");
    }
    
    # remove possible newline at end
    chomp $statement;
    my $body = $statement . $joiner . $newline;

    # turn our arguments into a list
    unless ($explicit) {

        $body = "($body)";
    }

    # wrap our body in a print statement
    return sprintf q!(print%s)%s!, $body, $append;
}

sub _locate_document_snippet {
    my ($class, $ctx) = @_;

    # fetch the code of the current line and remove it so perl won't notice it
    my $line = $ctx->get_linestr;
    my $code = substr $line, $ctx->offset;
    substr($line, $ctx->offset) = '';
    $ctx->set_linestr($line);

    # locate the document
    my $doc;
    while (1) {

        # build a document out of the existing code
        $doc = PPI::Document->new(\$code);
        
        # check if the statement has been fullly read
        no warnings 'uninitialized';
        if (   $doc->schildren > 1
            or (    $doc->first_element->isa('PPI::Statement')
                and $doc->first_element->last_element eq ';')
        ) {

            last;
        }

        # skip spaces, or if nothing more is to come, take what we have as document
        $ctx->skipspace
            or last;

        # add next line to the code and start over
        $code .= $ctx->get_linestr;
        $ctx->set_linestr('');
    }

    # the document that was found
    return $doc;
}

1;

__END__

=method install

Called by the L<syntax> dispatcher to install the extension in the target 
package.

=option -as

This allows you to import the keyword under a different name. Use the 
following in case you want C<printn> instead of C<say>:

    use syntax say => { -as => 'printn' };

If you want to use both, you can specify a single keyword multiple times
to the L<syntax> dispatcher:

    use syntax say => { -as => 'printn' },
               say => { -as => 'display' };

After this, both C<printn> and C<display> will be available as C<say>
keywords.

=head1 SYNOPSIS

    use syntax 'say';

    # simple...
    say 23

    # bareword handles...
    say STDOUT 23;

    # lexical handles...
    say $fh 23;

    # block style...
    say { $fh } 23;

    # and also with parenthesis...
    say(23);
    say(STDOUT 23);
    say($fh 23);
    say({ $fh } 23);

=head1 DESCRIPTION

This is a L<Devel::Declare> powered implementation of the C<say> keyword found
in perls above 5.10. You should use this module through the L<syntax> 
dispatcher.

The keyword operates the same way a normal C<print> does, except that it also
appends a newline. The actual transformation that happens is that this

    say FOO 23;

becomes

    say print(FOO 23, "\n");

thereby forwarding the actual syntax to C<print>.

=head1 SEE ALSO

L<syntax>

=cut
