package HTTP::Body;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

use Params::Validate    qw[];
use HTTP::Body::Context qw[];
use HTTP::Body::Parser  qw[];

__PACKAGE__->mk_accessors( qw[ context parser ] );

our $VERSION = 0.7;

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

=item new($hashref)

Constructor taking arugments as a hashref. Requires a C<context> argument which
isa L<HTTP::Body::Context> object, and optional C<bufsize> (integer) and 
C<parser> (L<HTTP::Body::Parser>) arguments.

If called with two arguments C<($content_type, $content_length), 
L<HTTP::Body::Compat> will be used instead to maintain compatability with
versions <= 0.6

=cut

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    
    # bring in compat for old API <= 0.6
    if ( @_ == 2 ) {
        require HTTP::Body::Compat;
        return  HTTP::Body::Compat->new(@_);
    }

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
            },
            parser  => {
                type      => Params::Validate::OBJECT,
                isa       => 'HTTP::Body::Parser',
                optional  => 1
            }
        },
        called  => "$class\::new"
    );

    return bless( {}, $class )->initialize($params);
}

sub initialize {
    my ( $self, $params ) = @_;
    
    my $bufsize = delete $params->{bufsize} || 65536;

    $params->{parser} ||= HTTP::Body::Parser->new(
        bufsize => $bufsize,
        context => $params->{context}
    );

    while ( my ( $param, $value ) = each( %{ $params } ) ) {
        $self->$param($value);
    }

    return $self;
}

=item eos

=cut

sub eos {
    return shift->parser->eos;
}

=item put

=cut

sub put {
    return shift->parser->put(@_);
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
