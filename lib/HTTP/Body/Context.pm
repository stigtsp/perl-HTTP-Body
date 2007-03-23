package HTTP::Body::Context;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

use Class::Param     qw[];
use HTTP::Headers    qw[];
use Params::Validate qw[];
use Scalar::Util     qw[];

__PACKAGE__->mk_accessors( qw[ content headers param upload ] );

=head1 NAME

HTTP::Body::Context

=head1 METHODS

=over

=item new($hashref)

Constructor. Takes the following arguments in a hashref:

=over

=item headers

HTTP::Headers object, or an array or hashref

=item param (optional)

=item upload (optional)

=back

=cut

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

=item context_length

=cut

sub content_length {
    return shift->headers->content_length(@_);
}

=item content_type

=cut

sub content_type {
    return shift->headers->content_type(@_);
}

=item header

=cut

sub header {
    return shift->headers->header(@_);
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

__END__
