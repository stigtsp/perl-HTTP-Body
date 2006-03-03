package HTTP::Body::Compat;

use strict;
use warnings;
use base 'HTTP::Body';

use Params::Validate    qw[];
use HTTP::Body::Context qw[];

sub new {
    my $class   = ref $_[0] ? ref shift : shift;
    my ( $content_type, $content_length ) = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            {
                type      => Params::Validate::SCALAR,
                optional  => 0
            },
            {
                type      => Params::Validate::SCALAR,
                optional  => 0
            }
        ],
        called  => "$class\::new"
    );
    
    my $context = HTTP::Body::Context->new(
        headers => {
            'Content-Type'   => $content_type,
            'Content-Length' => $content_length
        }
    );

    return bless( {}, $class )->initialize( { context => $context } );
}

sub add {
    my $self = shift;
    
    if ( defined $_[0] ) {
        $self->{length} += bytes::length $_[0];
    }
    
    $self->put(@_);
    
    if ( $self->length == $self->content_length ) {
        $self->eos;
        return 0;
    }

    return ( $self->length - $self->content_length );
}

sub body {
    return $_[0]->context->content;
}

sub buffer {
    return '';
}

sub content_length {
    return $_[0]->context->content_length;
}

sub content_type {
    return $_[0]->context->content_type;
}

sub length {
    return $_[0]->{length};
}

sub state {
    return 'done';
}

sub param {
    my $self = shift;
    
    if ( @_ == 2 ) {
        return $self->context->param->add(@_);        
    }
    
    return scalar $self->context->param->as_hash;
}

sub upload {
    my $self = shift;
    
    if ( @_ == 2 ) {
        return $self->context->upload->add(@_);        
    }
    
    return scalar $self->context->upload->as_hash;
}

1;
