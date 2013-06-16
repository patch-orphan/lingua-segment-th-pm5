package Lingua::Segment::TH;

use v5.8;
use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use parent 'Exporter';
use Lingua::Segment::TH::Dict;

our $VERSION = '0.01';
our @EXPORT_OK = qw( segment segment_th );

my $POINTER      = 0;
my $WEIGHT       = 1;
my $PATH_UNKNOWN = 2;
my ($START, $END)                 = 0..1;
my ($FIRST, $LAST)                = 0..1;
my ($INVALID, $ACTIVE, $BOUNDARY) = 0..2;

*segment_th = \&segment;

# TODO: Unicode Text Segmentation for words from AUX #29
# http://www.unicode.org/reports/tr29/#Word_Boundaries

sub segment {
    my ($text) = @_;
    my @segments;

    $text =~ s{ ^ \P{Alnum}+   }{}x;
    $text =~ s{   \P{Alnum}+ $ }{}x;

    for my $segment (split m{
        \b
        \P{Alnum}*
        \s+
        (?: [\P{Alnum}\s]+ \s )?
        \P{Alnum}*
        \b
    }x, $text) {
        my $length = length $segment;
        my @dag    = _dag($segment, $length);
        my @ranges = _ranges(\@dag, $length);

        push @segments, map {
            substr $segment, $_->[$START], $_->[$END] - $_->[$START]
        } @ranges;
    }

    return @segments;
}

sub _dag {
    my ($text, $length) = @_;
    my @dag;

    for my $i (0 .. $length - 1) {
        my $iter = _dict_iter();

        for my $j ($i .. $length - 1) {
            my $chr    = substr $text, $j, 1;
            my $status = $iter->($chr);

            last if $status == $INVALID;
            next if $status != $BOUNDARY;

            push @dag, [$i, $j + 1];
        }
    }

    return sort {
        my $r = 0;

        for my $i (0 .. 2) {
            $r = $a->[$i] <=> $b->[$i];
            last if $r;
        }

        return $r;
    } @dag;
}

sub _dict_iter {
    my $dict   = Lingua::Segment::TH::Dict::words();
    my $offset = 0;
    my $start  = 0;
    my $end    = scalar @$dict;
    my $state  = $ACTIVE;

    return sub {
        my ($chr) = @_;

        return $state
            if $state == $INVALID;

        my $first = _dict_index($dict, $chr, $offset, $start, $end, $FIRST);

        if (defined $first) {
            $start = $first;
            $end   = _dict_index($dict, $chr, $offset, $start, $end, $LAST) + 1;
            $offset++;
            $state = $offset == length $dict->[$first] ? $BOUNDARY : $ACTIVE;
        }
        else {
            $state = $INVALID;
        }

        return $state;
    }
}

sub _dict_index {
    my ($dict, $prefix, $offset, $start, $end, $pos_type) = @_;
    $offset ||= 0;
    $start  ||= 0;
    $end    ||= @$dict;
    my $left  = $start;
    my $right = $end - 1;
    my $index;

    while ($left <= $right) {
        my $i   = int( ($left + $right) / 2 );
        my $chr = substr $dict->[$i], $offset, 1;

        if (!length $chr || $prefix gt $chr) {
            $left = $i + 1;
        }
        elsif ($prefix lt $chr) {
            $right = $i - 1;
        }
        else {
            $index = $i;

            if ($pos_type == $FIRST) {
                $right = $i - 1;
            }
            elsif ($pos_type == $LAST) {
                $left  = $i + 1;
            }
        }
    }

    return $index;
}

sub _ranges {
    my ($dag, $length) = @_;
    my $start_index = _build_index($dag, $START);
    my $end_index   = _build_index($dag, $END);
    my $path        = _build_path($length, $start_index, $end_index);

    return _path_ranges($path, $length);
}

sub _build_index {
    my ($dag, $position) = @_;
    my %index;

    for my $range (@$dag) {
        $index{$range->[$position]} ||= [];
        push @{$index{$range->[$position]}}, $range;
    }

    return \%index;
}

sub _build_path {
    my ($length, $start_index, $end_index) = @_;
    my $left_boundary = 0;
    my @path = ([0, 0, 0]);

    for my $i (1 .. $length) {
        if ( $end_index->{$i} ) {
            for my $range ( @{$end_index->{$i}} ) {
                my $start = $range->[$START];

                if ( $path[$start] ) {
                    my $info = [
                        $start,
                        $path[$start][$WEIGHT] + 1,
                        $path[$start][$PATH_UNKNOWN],
                    ];

                    if ( !$path[$i] || _compare_path_info($info, $path[$i]) ) {
                        $path[$i] = $info;
                    }
                }
            }

            if ( $path[$i] ) {
                $left_boundary = $i;
            }
        }

        if ( !$path[$i] && $start_index->{$i} ) {
            $path[$i] = [
                $left_boundary,
                $path[$left_boundary][$WEIGHT]       + 1,
                $path[$left_boundary][$PATH_UNKNOWN] + 1,
            ];
        }
    }

    $path[$length] ||= [
        $left_boundary,
        $path[$left_boundary][$WEIGHT]       + 1,
        $path[$left_boundary][$PATH_UNKNOWN] + 1,
    ];

    return \@path;
}

sub _compare_path_info {
    my ($path1, $path2) = @_;

    return $path1->[$PATH_UNKNOWN] < $path2->[$PATH_UNKNOWN]
        && $path1->[$WEIGHT]       < $path2->[$WEIGHT];
}

sub _path_ranges {
    my ($path, $length) = @_;
    my @ranges;
    my $i = $length;

    while ($i > 0) {
        my $info  = $path->[$i];
        my $start = $info->[$POINTER];

        push @ranges, [$start, $i];

        $i = $start;
    }

    return reverse @ranges;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Segment::TH - Thai word segmenter

=head1 VERSION

This document describes Lingua::Segment::TH v0.01.

=head1 SYNOPSIS

    use Lingua::Segment::TH qw( segment_th );

    @words = segment_th($phrase);

=head1 DESCRIPTION

This module provides word segmentation (also known as word breaking) for the
Thai language.  The C<segement> and C<segment_th> functions are synonymous and
can optionally be exported.  They accept a string of Thai text and return a list
of words.

=head1 SEE ALSO

=over

=item * L<thailang4r|https://github.com/veer66/thailang4r> for Ruby

=item * L<PhlongTaIam|https://github.com/veer66/PhlongTaIam> for PHP

=item * L<ThaiWordseg|http://thaiwordseg.sourceforge.net/> for C

=item * L<libthai|http://linux.thai.net/projects/libthai> for C

=item * L<Lingua::TH::Segmentation> for Perl (interface to ThaiWordseg)

=back

=head1 ACKNOWLEDGEMENTS

This module is based on the Ruby library
L<thailang4r|https://github.com/veer66/thailang4r> by
L<Vee Satayamas|https://github.com/veer66>, who also authored ThaiWordseg.

This module is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2013 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
