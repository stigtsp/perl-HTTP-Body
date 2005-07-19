package HTTP::Body::Urlencoded;

use strict;
use base 'HTTP::Body';
use bytes;

our $DECODE = qr/%(u?[0-9a-fA-F]{2,4})/;

sub spin {
    my $self = shift;
    
    return unless $self->length == $self->content_length;

    for my $pair ( split( /[&;]/, $self->{buffer} ) ) {
        
        my ( $name, $value ) = split( /=/, $pair );
        
        next unless defined $name;
        next unless defined $value;
        
        $name  =~ s/$DECODE/chr(hex($1))/eg;
        $name  =~ tr/+/ /;
        $value =~ s/$DECODE/chr(hex($1))/eg;
        $value =~ tr/+/ /;
        
        $self->param( $name, $value );
    }
    
    $self->{state}  = 'done';
    $self->{buffer} = ''
}

1;
