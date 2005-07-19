package HTTP::Body;

use strict;

use Carp       qw[ ];
use List::Util qw[ first ];

our $TYPES = {
    'application/octet-stream'          => 'HTTP::Body::Octetstream',
    'application/x-www-form-urlencoded' => 'HTTP::Body::Urlencoded',
    'multipart/form-data'               => 'HTTP::Body::Multipart'
};

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

sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    return $self->{body};
}

sub buffer {
    return shift->{buffer};
}

sub content_length {
    return shift->{content_length};
}

sub content_type {
    return shift->{content_type};
}

sub init {
    return $_[0];
}

sub length {
    return shift->{length};
}

sub spin {
    Carp::croak('Define abstract method spin() in implementation');
}

sub state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};    
}

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

1;
