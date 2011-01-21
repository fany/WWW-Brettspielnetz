#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Brettspielnetz' ) || print "Bail out!
";
}

diag( "Testing WWW::Brettspielnetz $WWW::Brettspielnetz::VERSION, Perl $], $^X" );
