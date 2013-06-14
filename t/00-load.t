use utf8;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'Lingua::Segment::TH', qw( segment segment_th ) }

diag "Testing Lingua::Segment::TH $Lingua::Segment::TH::VERSION, Perl $], $^X";
