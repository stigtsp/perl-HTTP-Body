#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'HTTP::Body',
    VERSION_FROM => 'lib/HTTP/Body.pm',
    PREREQ_PM    => {
        perl             => 5.006,
        Carp             => 0,
        Class::Accessor  => 0,
        Class::Param     => 0,
        File::Temp       => '0.14',
        HTTP::Headers    => 0,
        IO::File         => 0,
        Params::Validate => 0,
        Scalar::Util     => 0,
    }
);
