#!perl

use 5.32.0;

use strict;
use warnings;

use Test2::V0;

use Net::DigitalNZ;

my $dnz1 = Net::DigitalNZ->new();
my $dnz3 = Net::DigitalNZ->new( version => 3 );

isa_ok( $dnz1, ['Net::DigitalNZ'],     "Old DigitalNZ constructor gives old class" );
isa_ok( $dnz3, ['Net::DigitalNZ::V3'], "Old DigitalNZ constructor with version=>3 gives v3 class" );

done_testing;

