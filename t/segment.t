use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 2;
use Lingua::Segment::TH qw( segment );

is join(' ', segment('กกตขจ')),     'กกต ขจ';
is join(' ', segment('กกตศรรมขจ')), 'กกต ศรรม ขจ';
