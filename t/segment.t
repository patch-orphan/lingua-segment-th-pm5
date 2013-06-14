use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 4;
use Lingua::Segment::TH qw( segment );

is join(' ', segment('สุนัขและแมว')), 'สุนัข และ แมว',  'dog and cat';
is join(' ', segment('ปลาใหญ่')),    'ปลา ใหญ่',      'big fish';
is join(' ', segment('คนเดิน')),     'คน เดิน',       'man walking';
is join(' ', segment('ฉันไม่ชอบมัน')), 'ฉัน ไม่ ชอบ มัน', "I don't like it";
