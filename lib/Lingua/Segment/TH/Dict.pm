package Lingua::Segment::TH::Dict;

use v5.8;
use utf8;
use strict;
use warnings;

our $VERSION = '0.01';

my @words;

sub _init {
    while (my $word = <DATA>) {
        chomp $word;
        push @words, $word;
    }

    close DATA;
}

sub words {
    _init() unless @words;
    return \@words;
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
