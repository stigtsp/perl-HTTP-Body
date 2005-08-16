#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'HTTP::Body',
    VERSION_FROM => 'lib/HTTP/Body.pm',
    PREREQ_PM    => {
        YAML         => 0,
        Data::Dumper => 0,
        IO::File     => 0,
        List::Util   => 0,
        Carp         => 0,
        File::Temp   => '0.14',
        Path::Class  => 0
    }
);
