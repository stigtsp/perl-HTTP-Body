package HTTP::Body;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

use Params::Validate    qw[];
use HTTP::Body::Context qw[];
use HTTP::Body::Parser  qw[];

__PACKAGE__->mk_accessors( qw[ context parser ] );

our $VERSION = 0.7;

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

sub eos {
    return shift->parser->eos;
}

sub put {
    return shift->parser->put(@_);
}

1;
