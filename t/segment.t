use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 13;
use Lingua::Segment::TH qw( segment );

is join(' ', segment('สุนัขและแมว')), 'สุนัข และ แมว',  'dog and cat';
is join(' ', segment('ปลาใหญ่')),    'ปลา ใหญ่',      'big fish';
is join(' ', segment('คนเดิน')),     'คน เดิน',       'man walking';
is join(' ', segment('ฉันไม่ชอบมัน')), 'ฉัน ไม่ ชอบ มัน', "I don't like it";

is join('|', segment('The quick (“brown”) fox can’t jump 32.3 feet, right?')),
    'The|quick|brown|fox|can’t|jump|32.3|feet|right', 'English text';

is join('|', segment('she said “ปลาใหญ่”')),
    'she|said|ปลา|ใหญ่', 'English/Thai mix';

is join('|', segment("can't")),        "can't",        'no break on apostrophe';
is join('|', segment('over-the-top')), 'over-the-top', 'no break on hyphan';
is join('|', segment('East–West')),    'East|West',    'break on en dash';
is join('|', segment('9,00.00')),      '9,00.00',      'no break within number';
is join('|', segment('3:45')),         '3:45',         'no break within time';

is join('|', segment('style—not sincerity—is')),
    'style|not|sincerity|is', 'break on em dash';

is join('|', segment('style--not sincerity--is')),
    'style|not|sincerity|is', 'break on double hyphan';
