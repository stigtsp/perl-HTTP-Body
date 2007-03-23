package HTTP::Body;

use strict;

use Carp       qw[ ];

our $VERSION = 0.7;

our $TYPES = {
    'application/octet-stream'          => 'HTTP::Body::OctetStream',
    'application/x-www-form-urlencoded' => 'HTTP::Body::UrlEncoded',
    'multipart/form-data'               => 'HTTP::Body::MultiPart'
};

require HTTP::Body::OctetStream;
require HTTP::Body::UrlEncoded;
require HTTP::Body::MultiPart;

=head1 NAME

HTTP::Body - HTTP Body Parser

=head1 SYNOPSIS

    use HTTP::Body;
    
    sub handler : method {
        my ( $class, $r ) = @_;

        my $content_type   = $r->headers_in->get('Content-Type');
        my $content_length = $r->headers_in->get('Content-Length');
        
        my $body   = HTTP::Body->new( $content_type, $content_length );
        my $length = $content_length;

        while ( $length ) {

            $r->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );

            $length -= length($buffer);
            
            $body->add($buffer);
        }
        
        my $uploads = $body->upload; # hashref
        my $params  = $body->param;  # hashref
        my $body    = $body->body;   # IO::Handle
    }

=head1 DESCRIPTION

HTTP Body Parser.

=head1 METHODS

=over 4 

=item new 

Constructor. Takes content type and content length as parameters,
returns a L<HTTP::Body> object.

=cut

sub new {
    my ( $class, $content_type, $content_length ) = @_;

    unless ( @_ == 3 ) {
        Carp::croak( $class, '->new( $content_type, $content_length )' );
    }

    my $type;
    foreach my $supported ( keys %{$TYPES} ) {
        if ( index( lc($content_type), $supported ) >= 0 ) {
            $type = $supported;
        }
    }

    my $body = $TYPES->{ $type || 'application/octet-stream' };

    eval "require $body";

    if ($@) {
        die $@;
    }

    my $self = {
        buffer         => '',
        body           => undef,
        content_length => $content_length,
        content_type   => $content_type,
        length         => 0,
        param          => {},
        state          => 'buffering',
        upload         => {}
    };

    bless( $self, $body );

    return $self->init;
}

=item add

Add string to internal buffer. Will call spin unless done. returns
length before adding self.

=cut

sub add {
    my $self = shift;
    
    my $cl = $self->content_length;

    if ( defined $_[0] ) {
        $self->{length} += length( $_[0] );
        
        # Don't allow buffer data to exceed content-length
        if ( $self->{length} > $cl ) {
            $_[0] = substr $_[0], 0, $cl - $self->{length};
            $self->{length} = $cl;
        }
        
        $self->{buffer} .= $_[0];
    }

    unless ( $self->state eq 'done' ) {
        $self->spin;
    }

    return ( $self->length - $cl );
}

=item body

accessor for the body.

=cut

sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    return $self->{body};
}

=item buffer

read only accessor for the buffer.

=cut

sub buffer {
    return shift->{buffer};
}

=item content_length

read only accessor for content length

=cut

sub content_length {
    return shift->{content_length};
}

=item content_type

ready only accessor for the content type

=cut

sub content_type {
    return shift->{content_type};
}

=item init

return self.

=cut

sub init {
    return $_[0];
}

=item length

read only accessor for body length.

=cut

sub length {
    return shift->{length};
}

=item spin

Abstract method to spin the io handle.

=cut

sub spin {
    Carp::croak('Define abstract method spin() in implementation');
}

=item state

accessor for body state.

=cut

sub state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};
}

=item param

accesor for http parameters.

=cut

sub param {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $value ) = @_;

        if ( exists $self->{param}->{$name} ) {
            for ( $self->{param}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $value );
            }
        }
        else {
            $self->{param}->{$name} = $value;
        }
    }

    return $self->{param};
}

=item upload

=cut

sub upload {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $upload ) = @_;

        if ( exists $self->{upload}->{$name} ) {
            for ( $self->{upload}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $upload );
            }
        }
        else {
            $self->{upload}->{$name} = $upload;
        }
    }

    return $self->{upload};
}

=back

=head1 BUGS

Chunked requests are currently not supported.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

Sebastian Riedel, C<sri@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
