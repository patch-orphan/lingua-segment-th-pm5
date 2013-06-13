use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 2;
use Lingua::Segment::TH qw( segment );

is_deeply [segment('กกตขจ')],     [qw( กกต ขจ )];
is_deeply [segment('กกตศรรมขจ')], [qw( กกต ศรรม ขจ )];
