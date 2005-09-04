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
        my $headers = LoadFile( file( $FindBin::Bin, 'data', $format, "$num-headers.yml" ) );
        my $results = LoadFile( file( $FindBin::Bin, 'data', $format, "$num-results.yml" ) );
        my $content = $file->open('<');
        my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );

        binmode $content, ':raw';

        while ( $content->read( my $buffer, 1024 ) ) {
            $body->add($buffer);
        }

        if ( $ENV{HTTP_BODY_DEBUG} ) {
            warn Dumper( $body->param );
            warn Dumper( $body->upload );
            warn Dumper( $body->body );

            warn "state          : " . $body->state;
            warn "length         : " . $body->length;
            warn "content length : " . $body->content_length;
            warn "body length    : " . ( $body->body->stat )[7] if $body->body;
            warn "buffer         : " . $body->buffer if $body->buffer;
        }
        
        for my $field ( keys %{ $body->upload } ) {

            my $value = $body->upload->{$field};

            for ( ( ref($value) eq 'ARRAY' ) ? @{$value} : $value ) {
                delete $_->{tempname};
            }
        }

        is_deeply( $body->body, $results->{body}, "$num-$format body" );
        is_deeply( $body->param, $results->{param}, "$num-$format param" );
        is_deeply( $body->upload, $results->{upload}, "$num-$format upload" );
        cmp_ok( $body->state, 'eq', 'done', "$num-$format state" );
        cmp_ok( $body->length, '==', $headers->{'Content-Length'}, "$num-$format length" );
    }
}

1;
