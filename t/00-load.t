#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Image::PNG::Write::BW' ) || print "Bail out!\n";
}

diag( "Testing Image::PNG::Write::BW $Image::PNG::Write::BW::VERSION, Perl $], $^X" );
