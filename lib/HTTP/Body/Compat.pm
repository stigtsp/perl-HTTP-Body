package HTTP::Body::Compat;

use strict;
use warnings;
use base 'HTTP::Body';

use Params::Validate    qw[];
use HTTP::Body::Context qw[];

=head1 NAME

HTTP::Body::Compat - Backwards compataible HTTP Body Parser for versions <= 0.6

=head1 SYNOPSIS

   use HTTP::Body;
   
   sub handler : method {
       my ( $class, $r ) = @_;

       my $content_type   = $r->headers_in->get('Content-Type');
       my $content_length = $r->headers_in->get('Content-Length');
      
       # Calling HTTP::Body->new this way will go into pre 0.7 compat mode
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
returns a L<HTTP::Body::Compat> object.

=cut

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

=item add 

Add string to internal buffer. Returns length before adding string.

=cut

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

=item body

accessor for the body

=cut

sub body {
    return $_[0]->context->content;
}

sub buffer {
    return '';
}

=item content_length

Read-only accessor for content legnth

=cut

sub content_length {
    return $_[0]->context->content_length;
}

=item content_type

Read-only accessor for content type

=cut

sub content_type {
    return $_[0]->context->content_type;
}

sub length {
    return $_[0]->{length};
}

sub state {
    return 'done';
}

=item param

Accessor for HTTP parameters

=cut

sub param {
    my $self = shift;
    
    if ( @_ == 2 ) {
        return $self->context->param->add(@_);        
    }
    
    return scalar $self->context->param->as_hash;
}

=iteam upload

=cut

sub upload {
    my $self = shift;
    
    if ( @_ == 2 ) {
        return $self->context->upload->add(@_);        
    }
    
    return scalar $self->context->upload->as_hash;
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
