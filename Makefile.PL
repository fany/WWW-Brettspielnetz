use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Brettspielnetz',
    AUTHOR        => q{Martin H. Sluka <fany@cpan.org>},
    VERSION_FROM  => 'lib/WWW/Brettspielnetz.pm',
    ABSTRACT_FROM => 'lib/WWW/Brettspielnetz.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Any::Moose'       => 0,
        'Encode'           => 0,
        'Getopt::Long'     => 0,
        'List::Util'       => 0,
        'Net::Netrc'       => 0,
        'Readonly'         => 0,
        'Test::More'       => 0,
        'URI'              => 0,
        'WWW::Mechanize'   => 0,
        'Web::Scraper'     => 0,
        'namespace::clean' => 0,
    },
    EXE_FILES => ['bin/Brettspielnetz-Alarm'],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Brettspielnetz-*' },
);
