package Lingua::Segment::TH::Dict;

use v5.8;
use utf8;
use Moo;

our $VERSION = '0.01';

my @dict;

has words => (
    is      => 'ro',
    builder => sub {
        _init() unless @dict;
        return \@dict;
    },
);

sub _init {
    while (my $word = <DATA>) {
        chomp $word;
        push @dict, $word;
    }

    close DATA;
}

sub get_index {
    my ($self, $pos_type, $prefix, $offset, $start, $end) = @_;
    $offset ||= 0;
    $start  ||= 0;
    $end    ||= @{$self->words};
    my $left  = $start;
    my $right = $end - 1;
    my $index;

    while ($left <= $right) {
        my $i    = int( ($left + $right) / 2 );
        my $char = substr $self->words->[$i], $offset, 1;

        if (!length $char || $prefix gt $char) {
            $left = $i + 1;
        }
        elsif ($prefix lt $char) {
            $right = $i - 1;
        }
        else {
            $index = $i;

            if ($pos_type eq 'first') {
                $right = $i - 1;
            }
            else {
                $left = $i + 1;
            }
        }
    }

    return $index;
}

1;

__DATA__
ก
กกต
ข
ขคทท
ขจ
จก
มจ
มม
