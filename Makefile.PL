#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'HTTP::Body',
    VERSION_FROM => 'lib/HTTP/Body.pm',
    PREREQ_PM    => {
        Carp          => 0,
        File::Temp    => '0.14',
        HTTP::Headers => 0, 
        IO::File      => 0,
        Test::Deep    => 0,
        YAML          => '0.39'
    }
);
