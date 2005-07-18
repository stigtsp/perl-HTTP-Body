package HTTP::Body::Multipart;

use strict;
use base 'HTTP::Body::Multipart::Parser';

use File::Temp 0.14;

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    $self->{param}  = {};
    $self->{upload} = {};

    return $self;
}

sub handler {
    my ( $self, $part ) = @_;

    if ( $part->{done} && $part->{size} == 0 ) {
        return 0;
    }

    unless ( $self->{seen}->{"$part"}++ ) {

        my $disposition = $part->{headers}->{'Content-Disposition'};
        my ($name)      = $disposition =~ / name="?([^\";]+)"?"/;
        my ($filename)  = $disposition =~ / filename="?([^\"]+)"?/;

        $part->{name}     = $name;
        $part->{filename} = $filename;

        if ($filename) {

            my $fh = File::Temp->new( UNLINK => 0 );

            $part->{fh}       = $fh;
            $part->{tempname} = $fh->filename;
        }
    }

    if ( $part->{filename} ) {
        $part->{fh}->write( delete $part->{data} );
    }

    if ( $part->{done} ) {

        if ( $part->{filename} ) {
            $self->upload( $part->{name}, $part );
        }

        else {
            $self->param( $part->{name}, $part->{data} );
        }
    }
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
