#!/usr/bin/perl

BEGIN {
    require FindBin;
}

use strict;
use warnings;
use lib "$FindBin::Bin/../lib";

use Benchmark   qw[cmpthese timethese];
use CGI         qw[];
use CGI::Simple qw[];
use HTTP::Body  qw[];
use IO::Handle  qw[];
use IO::File    qw[O_RDONLY SEEK_SET];
use YAML        qw[LoadFile];

my ( $headers, $content, $message );

my $benchmarks = {
    'CGI' => sub {

        $content->seek( 0, SEEK_SET )
          or die $!;

        STDIN->fdopen( $content->fileno, 'r' );

        CGI::_reset_globals();

        my $cgi = CGI->new;
    },
    'HTTP::Body' => sub {

        $content->seek( 0, SEEK_SET )
          or die $!;

        my $body = HTTP::Body->new( $headers->{'Content-Type'},
                                    $headers->{'Content-Length'} );

        while ( $content->read( my $buffer, 4096 ) ) {
            $body->add($buffer);
        }

        unless ( $body->state eq 'done' ) {
            die 'baaaaaaaaad';
        }
    },
    'HTTP::Body Complete' => sub {

        my $body = HTTP::Body->new( $headers->{'Content-Type'},
                                    $headers->{'Content-Length'} );

        $body->add($message);

        unless ( $body->state eq 'done' ) {
            die 'baaaaaaaaad';
        }
    },
};

if ( eval 'require CGI::Simple' ) {
    $benchmarks->{'CGI::Simple'} = sub {

        $content->seek( 0, SEEK_SET )
          or die $!;

        STDIN->fdopen( $content->fileno, 'r' );

        CGI::Simple::_reset_globals();

        my $cgi = CGI::Simple->new;
    };
}

my @benchmarks =  @ARGV ? @ARGV : qw[ t/data/benchmark/001
                                      t/data/benchmark/002
                                      t/data/benchmark/003 ];

foreach my $benchmark ( @benchmarks ) {

    $headers  = LoadFile("$FindBin::Bin/../$benchmark-headers.yml");
    $content  = IO::File->new( "$FindBin::Bin/../$benchmark-content.dat", O_RDONLY )
      or die $!;

    binmode($content);

    $message = do{ local $/; <$content> };

    local %ENV = (
        CONTENT_LENGTH => $headers->{'Content-Length'},
        CONTENT_TYPE   => $headers->{'Content-Type'},
        QUERY_STRING   => '',
        REQUEST_METHOD => 'POST'
    );

    printf( "Content-Type   : %s\n", $headers->{'Content-Type'} =~ m/^([^;]+)/ );
    printf( "Content-Length : %s\n", $headers->{'Content-Length'} );
    printf( "Benchmark      : %s\n", $headers->{'Benchmark'} ) if $headers->{'Benchmark'};
    print "\n";

    cmpthese( -1, $benchmarks );

    printf( "%s\n", "-" x 80 ) if @benchmarks > 1;
}
