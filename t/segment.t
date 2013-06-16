use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 6;
use Lingua::Segment::TH qw( segment );

is join(' ', segment('สุนัขและแมว')), 'สุนัข และ แมว',  'dog and cat';
is join(' ', segment('ปลาใหญ่')),    'ปลา ใหญ่',      'big fish';
is join(' ', segment('คนเดิน')),     'คน เดิน',       'man walking';
is join(' ', segment('ฉันไม่ชอบมัน')), 'ฉัน ไม่ ชอบ มัน', "I don't like it";

is join('|', segment('The quick (“brown”) fox can’t jump 32.3 feet, right?')),
    'The|quick|brown|fox|can’t|jump|32.3|feet|right', 'English text';

is join('|', segment('she said “ปลาใหญ่”')),
    'she|said|ปลา|ใหญ่', 'English/Thai mix';
