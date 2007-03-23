package HTTP::Body::Parser;

use strict;
use warnings;
use bytes;
use base 'Class::Accessor::Fast';

use Carp             qw[];
use Class::Param     qw[];
use HTTP::Headers    qw[];
use Params::Validate qw[];

__PACKAGE__->mk_accessors( qw[ bufsize context seen_eos ] );

our $PARSERS = { };

sub register_parser {
    my ( $content_type, $parser ) = ( @_ == 2 ) ?  @_[ 1, 0 ] : @_[ 1, 2 ];

    $PARSERS->{ $content_type } = $parser;

    eval "use prefork '$parser';";
}

__PACKAGE__->register_parser( 'application/octet-stream'          => 'HTTP::Body::Parser::OctetStream' );
__PACKAGE__->register_parser( 'application/x-www-form-urlencoded' => 'HTTP::Body::Parser::UrlEncoded' );
__PACKAGE__->register_parser( 'multipart/form-data'               => 'HTTP::Body::Parser::MultiPart'   );

=head1 NAME

HTTP::Body::Parser

=head1 METHODS

=over 4

=item new($hashref)

Constructor.

=cut

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my $params = Params::Validate::validate_with(
        params  => \@_,
        spec    => {
            bufsize => {
                type      => Params::Validate::SCALAR,
                default   => 65536,
                optional  => 1
            },
            context => {
                type      => Params::Validate::OBJECT,
                isa       => 'HTTP::Body::Context',
                optional  => 0
            }
        },
        called  => "$class\::new"
    );

    # subclass
    if ( $class ne __PACKAGE__ ) {
        return bless( {}, $class )->initialize($params);
    }

    # factory
    my $content_type = $params->{context}->content_type;

    Carp::croak qq/Mandatory header 'Content-Type' is missing from headers in context./
      unless defined $content_type;

    my $parser = $PARSERS->{ lc $content_type } || $PARSERS->{ 'application/octet-stream' };

    eval "require $parser;"
      or Carp::croak qq/Failed to load parser '$parser' for Content-Type '$content_type'. Reason '$@'/;

    return $parser->new($params);
}

sub initialize {
    my ( $self, $params ) = @_;

    $params->{buffer}   = '';
    $params->{length}   = 0;
    $params->{seen_eos} = 0;

    while ( my ( $param, $value ) = each( %{ $params } ) ) {
        $self->$param($value);
    }

    return $self;
}

sub buffer : lvalue {
    my $self = shift;

    if ( @_ ) {
        $self->{buffer} = $_[0];
    }

    $self->{buffer};
}

sub length : lvalue {
    my $self = shift;

    if ( @_ ) {
        $self->{length} = $_[0];
    }

    $self->{length};
}

sub eos {
    my $self = shift;

    $self->seen_eos(1);

    if ( $self->context->content_length ) {

        my $expected = $self->context->content_length;
        my $length   = $self->length;

        if ( $length < $expected ) {
            Carp::croak qq/Truncated body. Expected $expected bytes, but only got $length bytes./;
        }
    }

    return $self->parse;
}

sub put {
    my $self = shift;

    if ( defined $_[0] ) {
        $self->length += bytes::length $_[0];
        $self->buffer .= $_[0];
    }

    return $self->parse;
}

=back

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

This pod written by Ash Berlin, C<ash@cpan.org>.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
