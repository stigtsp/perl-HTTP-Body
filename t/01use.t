use Test::More 'no_plan';

use strict;
use FindBin;
use_ok 'HTTP::Body';
use YAML 'LoadFile';
use Path::Class;
use Data::Dumper;

for my $format (qw/multipart urlencoded/) {
    for my $match ( glob file( $FindBin::Bin, 'data', $format, '*.dat' ) ) {
        my $file = file($match);
        my $name = $file->basename;
        $name =~ /^(\d+)-.*/;
        my $num     = $1;
        my $headers =
          LoadFile(
            file( $FindBin::Bin, 'data', $format, "$num-headers.yml" ) );
        my $content = $file->open('<');
        my $body    = HTTP::Body->new( $headers->{'Content-Type'},
            $headers->{'Content-Length'} );
        binmode $content;

        while ( $content->read( my $buffer, 1024 ) ) {
            $body->add($buffer);
        }
        if ( $ENV{HTTP_Body_Debug} ) {
            warn Dumper( $body->param );
            warn Dumper( $body->upload );
            warn Dumper( $body->body );

            warn "state          : " . $body->state;
            warn "length         : " . $body->length;
            warn "content length : " . $body->content_length;
            warn "body length    : " . ( $body->body->stat )[7] if $body->body;
            warn "buffer         : " . $body->buffer if $body->buffer;
        }
        ok( $body->state eq 'done' );
    }
}

1;
