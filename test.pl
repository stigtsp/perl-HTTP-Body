#!/usr/bin/perl

use strict;
use warnings;
use lib './lib';

use Data::Dumper;
use HTTP::Body;
use IO::File;
use YAML qw[LoadFile];

my $test = shift(@ARGV) || 1;

my $headers = LoadFile( sprintf( "t/data/multipart/%.3d-headers.yml", $test ) );
my $content = IO::File->new( sprintf( "t/data/multipart/%.3d-content.dat", $test ), O_RDONLY );
my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );

binmode $content;

while ( $content->read( my $buffer, 1024 ) ) {
    $body->add($buffer);
}

warn Dumper( $body->param  );
warn Dumper( $body->upload );
warn Dumper( $body->body   );

warn "length         : " . $body->length;
warn "content length : " . $body->content_length;
warn "state          : " . $body->{state};
warn "buffer         : " . $body->buffer;
