#!/usr/bin/perl

use strict;
use warnings;
use lib './lib';

use Data::Dumper;
use HTTP::Body;
use IO::File;
use YAML qw[LoadFile];

my $number = $ARGV[0] || 1;
my $test   = $ARGV[1] || 'multipart';


my $headers = LoadFile( sprintf( "t/data/%s/%.3d-headers.yml", $test, $number ) );
my $content = IO::File->new( sprintf( "t/data/%s/%.3d-content.dat", $test, $number ), O_RDONLY );
my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );

binmode $content;

while ( $content->read( my $buffer, 1024 ) ) {
    $body->add($buffer);
}

warn Dumper( $body->param  );
warn Dumper( $body->upload );
warn Dumper( $body->body   );

warn "state          : " . $body->state;
warn "length         : " . $body->length;
warn "content length : " . $body->content_length;
warn "body length    : " . ( $body->body->stat )[7] if $body->body;
warn "buffer         : " . $body->buffer if $body->buffer;
