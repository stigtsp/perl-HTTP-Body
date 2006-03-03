package HTTP::Body::Parser::UrlEncoded;

use strict;
use bytes;
use base 'HTTP::Body::Parser';

our $DECODE = qr/%([0-9a-fA-F]{2})/;

sub parse {
    my $self = shift;

    return unless $self->seen_eos;

    for my $pair ( split( /[&;]/, $self->buffer ) ) {

        my ( $name, $value ) = split( /=/, $pair );

        next unless defined $name;
        next unless defined $value;

        $name  =~ tr/+/ /;
        $name  =~ s/$DECODE/chr(hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/$DECODE/chr(hex($1))/eg;

        $self->context->param->add( $name => $value );
    }

    $self->buffer = '';
}

1;
