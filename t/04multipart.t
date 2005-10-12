#!perl

use strict;
use warnings;

use Test::More tests => 55;

use Cwd;
use HTTP::Body;
use File::Spec::Functions;
use IO::File;
use YAML;

my $path = catdir( getcwd(), 't', 'data', 'multipart' );

for ( my $i = 1; $i <= 11; $i++ ) {

    my $test    = sprintf( "%.3d", $i );
    my $headers = YAML::LoadFile( catfile( $path, "$test-headers.yml" ) );
    my $results = YAML::LoadFile( catfile( $path, "$test-results.yml" ) );
    my $content = IO::File->new( catfile( $path, "$test-content.dat" ) );
    my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );

    binmode $content, ':raw';

    while ( $content->read( my $buffer, 1024 ) ) {
        $body->add($buffer);
    }
    
    for my $field ( keys %{ $body->upload } ) {

        my $value = $body->upload->{$field};

        for ( ( ref($value) eq 'ARRAY' ) ? @{$value} : $value ) {
            delete $_->{tempname};
        }
    }

    is_deeply( $body->body, $results->{body}, "$test MultiPart body" );
    is_deeply( $body->param, $results->{param}, "$test MultiPart param" );
    is_deeply( $body->upload, $results->{upload}, "$test MultiPart upload" );
    cmp_ok( $body->state, 'eq', 'done', "$test MultiPart state" );
    cmp_ok( $body->length, '==', $headers->{'Content-Length'}, "$test MultiPart length" );
}
