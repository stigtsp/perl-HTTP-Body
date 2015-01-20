use utf8;
use warnings;
use strict;

use Test::More;
use HTTP::Body;
use HTTP::Request::Common;
use Encode;
use HTTP::Message::PSGI ();
use File::Spec::Functions;
use File::Temp qw/ tempdir /;


my $utf8 = 'test ♥';
my $shiftjs = 'test テスト';
my $path = File::Spec->catfile('t', 'utf8.txt');

ok my $req = POST '/root/echo_arg',
  Content_Type => 'form-data',
    Content =>  [
      arg0 => 'helloworld',
      arg1 => [
        undef, '',
        'Content-Type' =>'text/plain; charset=UTF-8',
        'Content' => Encode::encode('UTF-8', $utf8)],
      arg2 => [
        undef, '',
        'Content-Type' =>'text/plain; charset=SHIFT_JIS',
        'Content' => Encode::encode('SHIFT_JIS', $shiftjs)],
      arg2 => [
        undef, '',
        'Content-Type' =>'text/plain; charset=SHIFT_JIS',
        'Content' => Encode::encode('SHIFT_JIS', $shiftjs)],
      file => [
        "$path", Encode::encode_utf8('♥ttachment.txt'), 'Content-Type' =>'text/html; charset=UTF-8'
      ],
    ];


ok my $env = HTTP::Message::PSGI::req_to_psgi($req);
ok my $fh = $env->{'psgi.input'};
ok my $body = HTTP::Body->new( $req->header('Content-Type'), $req->header('Content-Length') );
ok my $tempdir = tempdir( 'XXXXXXX', CLEANUP => 1, DIR => File::Spec->tmpdir() );
$body->tmpdir($tempdir);

binmode $fh, ':raw';

while ( $fh->read( my $buffer, 1024 ) ) {
  $body->add($buffer);
}

is $body->param->{'arg0'}, 'helloworld';
is Encode::decode('UTF-8', $body->param->{'arg1'}), $utf8;
is Encode::decode('SHIFT_JIS', $body->param->{'arg2'}[0]), $shiftjs;

is $body->part_data->{'arg0'}->{data}, 'helloworld';
is Encode::decode('UTF-8', $body->part_data->{'arg1'}->{data}), $utf8;
is Encode::decode('SHIFT_JIS', $body->part_data->{'arg2'}[0]->{data}), $shiftjs;

done_testing;
