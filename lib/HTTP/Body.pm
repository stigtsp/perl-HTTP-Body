package HTTP::Body;

use strict;

use Carp       qw[ ];
use List::Util qw[ first ];

our $VERSION = '0.01';

our $TYPES = {
    'application/octet-stream'          => 'HTTP::Body::OctetStream',
    'application/x-www-form-urlencoded' => 'HTTP::Body::UrlEncoded',
    'multipart/form-data'               => 'HTTP::Body::MultiPart'
};

=head1 NAME

HTTP::Body - HTTP Body Parser

=head1 SYNOPSIS

    use HTTP::Body;

=head1 DESCRIPTION

HTTP Body Parser.

=head1 METHODS

=over 4

=cut

sub new {
    my ( $class, $content_type, $content_length ) = @_;

    unless ( @_ == 3 ) {
        Carp::croak( $class, '->new( $content_type, $content_length )' );
    }

    my $type = first { index( lc($content_type), $_ ) >= 0 } keys %{$TYPES};
    my $body = $TYPES->{ $type || 'application/octet-stream' };

    eval "require $body";

    if ($@) {
        die $@;
    }

    my $self = {
        buffer         => '',
        body           => '',
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

=cut

sub add {
    my $self = shift;

    if ( defined $_[0] ) {
        $self->{buffer} .= $_[0];
        $self->{length} += length( $_[0] );
    }

    unless ( $self->state eq 'done' ) {
        $self->spin;
    }

    return ( $self->length - $self->content_length );
}

=item body

=cut

sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    return $self->{body};
}

=item buffer

=cut

sub buffer {
    return shift->{buffer};
}

=item content_length

=cut

sub content_length {
    return shift->{content_length};
}

=item content_type

=cut

sub content_type {
    return shift->{content_type};
}

=item init

=cut

sub init {
    return $_[0];
}

=item length

=cut

sub length {
    return shift->{length};
}

=item spin

=cut

sub spin {
    Carp::croak('Define abstract method spin() in implementation');
}

=item state

=cut

sub state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};
}

=item param

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

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>
Messed up by Sebastian Riedel

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
