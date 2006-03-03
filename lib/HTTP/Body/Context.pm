package HTTP::Body::Context;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

use Class::Param     qw[];
use HTTP::Headers    qw[];
use Params::Validate qw[];
use Scalar::Util     qw[];

__PACKAGE__->mk_accessors( qw[ content headers param upload ] );

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my $params = Params::Validate::validate_with(
        params  => \@_,
        spec    => {
            headers => {
                type      =>   Params::Validate::ARRAYREF
                             | Params::Validate::HASHREF
                             | Params::Validate::OBJECT,
                optional  => 0,
                callbacks => {
                    'isa HTTP::Headers instance' => sub {
                        return 1 unless Scalar::Util::blessed( $_[0] );
                        return $_[0]->isa('HTTP::Headers');
                    }
                }
            },
            param => {
                type      => Params::Validate::OBJECT,
                isa       => 'Class::Param::Base',
                optional  => 1
            },
            upload => {
                type      => Params::Validate::OBJECT,
                isa       => 'Class::Param::Base',
                optional  => 1
            }
        },
        called  => "$class\::new"
    );

    return bless( {}, $class )->initialize($params);
}

sub initialize {
    my ( $self, $params ) = @_;
    
    if ( ref $params->{headers} eq 'ARRAY' ) {
        $params->{headers} = HTTP::Headers->new( @{ $params->{headers} } );
    }
    
    if ( ref $params->{headers} eq 'HASH' ) {
        $params->{headers} = HTTP::Headers->new( %{ $params->{headers} } );
    }
    
    $params->{param}  ||= Class::Param->new;
    $params->{upload} ||= Class::Param->new;

    while ( my ( $param, $value ) = each( %{ $params } ) ) {
        $self->$param($value);
    }

    return $self;
}

sub content_length {
    return shift->headers->content_length(@_);
}

sub content_type {
    return shift->headers->content_type(@_);
}

sub header {
    return shift->headers->header(@_);
}

1;

__END__
