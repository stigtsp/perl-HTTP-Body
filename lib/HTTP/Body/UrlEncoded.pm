package HTTP::Body::UrlEncoded;

use strict;
use base 'HTTP::Body';
use bytes;

our $DECODE = qr/%([0-9a-fA-F]{2})/;

=head1 NAME

HTTP::Body::UrlEncoded - HTTP Body UrlEncoded Parser

=head1 SYNOPSIS

    use HTTP::Body::UrlEncoded;

=head1 DESCRIPTION

HTTP Body UrlEncoded Parser.

=head1 METHODS

=over 4

=item spin

=cut

sub spin {
    my $self = shift;

    return unless $self->length == $self->content_length;

    for my $pair ( split( /[&;]/, $self->{buffer} ) ) {

        my ( $name, $value ) = split( /=/, $pair );

        next unless defined $name;
        next unless defined $value;

        $name  =~ tr/+/ /;
        $name  =~ s/$DECODE/chr(hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/$DECODE/chr(hex($1))/eg;

        $self->param( $name, $value );
    }

    $self->{buffer} = '';
    $self->{state}  = 'done';
}

=back

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
