package HTTP::Body::Multipart;

use strict;
use base 'HTTP::Body';
use bytes;

use File::Temp 0.14;

sub init {
    my $self = shift;

    unless ( $self->content_type =~ /boundary=\"?([^\";,]+)\"?/ ) {
        my $content_type = $self->content_type;
        Carp::croak("Invalid boudrary in content_type: '$content_type'");
    }

    $self->{boundary} = $1;
    $self->{state}    = 'preamble';
    $self->{length}   = $self->content_length - $self->content_length * 2;

    return $self;
}

sub add {
    my ( $self, $buffer ) = @_;

    unless ( defined $buffer ) {
        $buffer = '';
    }

    $self->{buffer} .= $buffer;
    $self->{length} += length($buffer);

    while (1) {

        if ( $self->{state} eq 'done' ) {
            return 0;
        }

        elsif ( $self->{state} =~ /^(preamble|boundary|header|body)$/ ) {
            my $method = "parse_$1";
            return $self->{length} unless $self->$method;
        }

        else {
            Carp::croak('Unknown state');
        }
    }
}

sub boundary {
    my $self = shift;
    $self->{boundary} = shift if @_;
    return $self->{boundary};
}

sub boundary_begin {
    return "--" . shift->boundary;
}

sub boundary_end {
    return shift->boundary_begin . "--";
}

sub crlf {
    return "\x0d\x0a";
}

sub delimiter_begin {
    my $self = shift;
    return $self->crlf . $self->boundary_begin;
}

sub delimiter_end {
    my $self = shift;
    return $self->crlf . $self->boundary_end;
}

sub parse_preamble {
    my $self = shift;

    my $index = index( $self->{buffer}, $self->boundary_begin );

    unless ( $index >= 0 ) {
        return 0;
    }

    # replace preamble with CRLF so we can match dash-boundary as delimiter
    substr( $self->{buffer}, 0, $index, $self->crlf );

    $self->{state} = 'boundary';

    return 1;
}

sub parse_boundary {
    my $self = shift;

    if ( index( $self->{buffer}, $self->delimiter_begin . $self->crlf ) == 0 ) {

        substr( $self->{buffer}, 0, length( $self->delimiter_begin ) + 2, '' );
        $self->{current}  = {};
        $self->{state}    = 'header';

        return 1;
    }

    if ( index( $self->{buffer}, $self->delimiter_end . $self->crlf ) == 0 ) {
        $self->{current}  = {};
        $self->{state}    = 'done';
        return 0;
    }    

    return 0;
}

sub parse_header {
    my $self = shift;

    my $crlf  = $self->crlf;
    my $index = index( $self->{buffer}, $crlf . $crlf );

    unless ( $index >= 0 ) {
        return 0;
    }

    my $header = substr( $self->{buffer}, 0, $index );

    substr( $self->{buffer}, 0, $index + 4, '' );

    my @headers;
    for ( split /$crlf/, $header ) {
        if (s/^[ \t]+//) {
            $headers[-1] .= $_;
        }
        else {
            push @headers, $_;
        }
    }

    my $token = qr/[^][\x00-\x1f\x7f()<>@,;:\\"\/?={} \t]+/;

    for my $header (@headers) {

        $header =~ s/^($token):[\t ]*//;

        ( my $field = $1 ) =~ s/\b(\w)/uc($1)/eg;

        if ( exists $self->{current}->{headers}->{$field} ) {
            for ( $self->{current}->{headers}->{$field} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $header );
            }
        }
        else {
            $self->{current}->{headers}->{$field} = $header;
        }
    }

    $self->{state} = 'body';

    return 1;
}

sub parse_body {
    my $self = shift;

    my $index = index( $self->{buffer}, $self->delimiter_begin );

    if ( $index < 0 ) {

        # make sure we have enough buffer to detect end delimiter
        my $length = length( $self->{buffer} ) - ( length( $self->delimiter_end ) + 2 );

        unless ( $length > 0 ) {
            return 0;
        }

        $self->{current}->{data} .= substr( $self->{buffer}, 0, $length, '' );
        $self->{current}->{size} += $length;
        $self->{current}->{done}  = 0;

        $self->handler( $self->{current} );

        return 0;
    }

    $self->{current}->{data} .= substr( $self->{buffer}, 0, $index, '' );
    $self->{current}->{size} += $index;
    $self->{current}->{done}  = 1;

    $self->handler( $self->{current} );

    $self->{state} = 'boundary';

    return 1;
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
            
            my $fh = delete $part->{fh};
            $fh->close;
            
            $self->upload( $part->{name}, $part );
        }

        else {
            $self->param( $part->{name}, $part->{data} );
        }
    }
}

1;
