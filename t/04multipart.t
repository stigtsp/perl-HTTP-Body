#!perl

use strict;
use warnings;

use Test::More tests => 102;

use Cwd;
use HTTP::Body;
use File::Spec::Functions;
use IO::File;
use YAML;
use File::Temp qw/ tempdir /;

my $path = catdir( getcwd(), 't', 'data', 'multipart' );

for ( my $i = 1; $i <= 13; $i++ ) {

    my $test    = sprintf( "%.3d", $i );
    my $headers = YAML::LoadFile( catfile( $path, "$test-headers.yml" ) );
    my $results = YAML::LoadFile( catfile( $path, "$test-results.yml" ) );
    my $content = IO::File->new( catfile( $path, "$test-content.dat" ) );
    my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );
    my $tempdir = tempdir( 'XXXXXXX', CLEANUP => 1, DIR => File::Spec->tmpdir() );
    $body->tmpdir($tempdir);

    my $regex_tempdir = quotemeta($tempdir);

    binmode $content, ':raw';

    while ( $content->read( my $buffer, 1024 ) ) {
        $body->add($buffer);
    }
    
    # Save tempnames for later deletion
    my @temps;
    
    for my $field ( keys %{ $body->upload } ) {

        my $value = $body->upload->{$field};

        for ( ( ref($value) eq 'ARRAY' ) ? @{$value} : $value ) {
            like($_->{tempname}, qr{$regex_tempdir}, "has tmpdir $tempdir");
            push @temps, delete $_->{tempname};
        }
    }

    is_deeply( $body->body, $results->{body}, "$test MultiPart body" );
    is_deeply( $body->param, $results->{param}, "$test MultiPart param" );
    is_deeply( $body->upload, $results->{upload}, "$test MultiPart upload" )
        if $results->{upload};
    cmp_ok( $body->state, 'eq', 'done', "$test MultiPart state" );
    cmp_ok( $body->length, '==', $body->content_length, "$test MultiPart length" );
    
    # Clean up temp files created
    unlink map { $_ } grep { -e $_ } @temps;
}
