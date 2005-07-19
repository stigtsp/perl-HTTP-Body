package HTTP::Body::Octetstream;

use strict;
use base 'HTTP::Body';
use bytes;

use File::Temp 0.14;

sub spin {
    my $self = shift;

    unless ( $self->body ) {
        $self->body( File::Temp->new );
    }
    
    if ( my $length = length( $self->{buffer} ) ) {
        $self->body->write( delete $self->{buffer}, $length );
    }
    
    if ( $self->length == $self->content_length ) {
        seek( $self->body, 0, 0 );
        $self->state('done');
    }
}

1;
