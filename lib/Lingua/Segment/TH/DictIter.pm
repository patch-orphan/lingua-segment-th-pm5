package Lingua::Segment::TH::DictIter;

use v5.8;
use utf8;
use strict;
use warnings;
use Lingua::Segment::TH::Dict;

our $VERSION = '0.01';

sub build_iter {
    my $dict   = Lingua::Segment::TH::Dict->new;
    my $offset = 0;
    my $start  = 0;
    my $end    = scalar @{$dict->words};
    my $state  = 'active';

    return sub {
        my ($char) = @_;

        return $state
            if $state eq 'invalid';

        my $first = $dict->get_index('first', $char, $offset, $start, $end);

        if (defined $first) {
            $start = $first;
            $end = $dict->get_index('last', $char, $offset, $start, $end) + 1;
            $offset++;
            $state = $offset == length $dict->words->[$first]
                ? 'active boundary'
                : 'active';
        }
        else {
            $state = 'invalid';
        }

        return $state;
    }
}

1;
