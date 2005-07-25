package HTTP::Body::UrlEncoded;

use strict;
use base 'HTTP::Body';
use bytes;

our $DECODE = qr/%([0-9a-fA-F]{2})/;

sub spin {
    my $self = shift;
    
    return unless $self->length == $self->content_length;

    for my $pair ( split( /[&;]/, $self->{buffer} ) ) {
        
        my ( $name, $value ) = split( /=/, $pair );
        
        next unless defined $name;
        next unless defined $value;
        
        $name  =~ tr/+/ /;
        $name  =~ s/$DECODE/chr(hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/$DECODE/chr(hex($1))/eg;        
        
        $self->param( $name, $value );
    }
    
    $self->{buffer} = ''
    $self->{state}  = 'done';
}

1;
