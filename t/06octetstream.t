use strict;
use warnings;

use Test::More;

eval { require YAML; import YAML 'LoadFile'; };
if ($@) {
  eval { require YAML::Syck; import YAML::Syck 'LoadFile'; }
}

plan skip_all => 'Tests need YAML or YAML::Syck' if $@;

plan tests => 8;

use Cwd;
use HTTP::Body;
use File::Spec::Functions;
use IO::File;

my $path = catdir( getcwd(), 't', 'data', 'octetstream' );

for ( my $i = 1 ; $i <= 2 ; $i++ ) {

    my $test = sprintf( "%.3d", $i );
    my $headers = YAML::LoadFile( catfile( $path, "$test-headers.yml" ) );
    my $results =
      slurp_fh( IO::File->new( catfile( $path, "$test-results.dat" ) ) );
    my $content = IO::File->new( catfile( $path, "$test-content.dat" ) );
    my $body = HTTP::Body->new( $headers->{'Content-Type'},
        $headers->{'Content-Length'} );

    binmode $content, ':raw';

    while ( $content->read( my $buffer, 1024 ) ) {
        $body->add($buffer);
    }

    isa_ok( $body->body, 'File::Temp', "$test OctetStream body isa" );
    my $data = slurp_fh( $body->body );
    is_deeply( $data, $results, "$test UrlEncoded body" );
    cmp_ok( $body->state, 'eq', 'done', "$test UrlEncoded state" );
    cmp_ok(
        $body->length, '==',
        $headers->{'Content-Length'},
        "$test UrlEncoded length"
    );
}

sub slurp_fh {
    my ($fh) = @_;
    my $data = '';
    while ( $fh->read( my $buffer, 1024 ) ) {
        $data .= $buffer;
    }
    $data;
}
