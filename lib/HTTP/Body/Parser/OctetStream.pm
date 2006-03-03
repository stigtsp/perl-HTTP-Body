package HTTP::Body::Parser::OctetStream;

use strict;
use bytes;
use base 'HTTP::Body::Parser';

use Carp       qw[];
use Errno      qw[];
use File::Temp qw[];

sub parse {
    my $self = shift;

    if ( $self->seen_eos && length $self->buffer || length $self->buffer >= $self->bufsize ) {

        unless ( $self->context->content ) {
            $self->context->content( File::Temp->new );
        }

        my ( $r, $w, $s ) = ( length $self->buffer, 0, 0 );

        for ( $w = 0; $w < $r; $w += $s || 0 ) {

            $s = $self->context->content->syswrite( $self->buffer, $r - $w, $w );

            Carp::croak qq/Failed to syswrite buffer to temporary file. Reason: $!./
              unless defined $s || $! == Errno::EINTR;
        }

        $self->buffer = '';
    }

    if ( $self->seen_eos && $self->context->content ) {

        sysseek( $self->context->content, 0, 0 )
          or Carp::croak qq/Failed to sysseek temporary handle./;
    }
}

1;
