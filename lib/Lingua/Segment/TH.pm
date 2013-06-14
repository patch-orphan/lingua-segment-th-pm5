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

my $LINK_TYPE      = 2;
my $POINTER        = 0;
my $WEIGHT         = 1;
my $PATH_UNK       = 2;
my $PATH_LINK_TYPE = 3;
my ($START, $END)                 = 0..1;
my ($FIRST, $LAST)                = 0..1;
my ($INVALID, $ACTIVE, $BOUNDARY) = 0..2;

*segment_th = \&segment;

sub segment {
    my ($text) = @_;
    my $length = length $text;
    my @dag    = _dag($text, $length);
    my @ranges = _ranges(\@dag, $length);

    return map {
        substr $text, $_->[$START], $_->[$END] - $_->[$START]
    } @ranges;
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

            push @dag, [$i, $j + 1, 'dict'];
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
            if $state eq $INVALID;

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

            if ($pos_type eq $FIRST) {
                $right = $i - 1;
            }
            elsif ($pos_type eq $LAST) {
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
    my ($dag, $pos) = @_;
    my %index;

    for my $range (@$dag) {
        $index{$range->[$pos]} ||= [];
        push @{$index{$range->[$pos]}}, $range;
    }

    return \%index;
}

sub _build_path {
    my ($length, $start_index, $end_index) = @_;
    my $left_boundary = 0;
    my @path = (undef) x ($length + 1);
    $path[0] = [0, 0, 0, 'unk'];

    for my $i (1 .. $length) {
        if ( $end_index->{$i} ) {
            for my $range ( @{$end_index->{$i}} ) {
                my $start = $range->[$START];

                if ( $path[$start] ) {
                    my $info = [
                        $start,
                        $path[$start][$WEIGHT] + 1,
                        $path[$start][$PATH_UNK],
                        $range->[$LINK_TYPE],
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
                $path[$left_boundary][$WEIGHT]   + 1,
                $path[$left_boundary][$PATH_UNK] + 1,
                'unk',
            ];
        }
    }

    $path[$length] ||= [
        $left_boundary,
        $path[$left_boundary][$WEIGHT]   + 1,
        $path[$left_boundary][$PATH_UNK] + 1,
        'unk',
    ];

    return \@path;
}

sub _compare_path_info {
    my ($path1, $path2) = @_;

    return $path1->[$PATH_UNK] < $path2->[$PATH_UNK]
        && $path1->[$WEIGHT]   < $path2->[$WEIGHT];
}

sub _path_ranges {
    my ($path, $length) = @_;
    my @ranges;
    my $i = $length;

    while ($i > 0) {
        my $info  = $path->[$i];
        my $start = $info->[$POINTER];

        push @ranges, [$start, $i, $info->[$PATH_LINK_TYPE]];

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

    # 'กกต', 'ศรรม', 'ขจ'
    @words = segment_th('กกตศรรมขจ');

=head1 DESCRIPTION

...

=head1 SEE ALSO

=over

=item * L<thailang4r|https://github.com/veer66/thailang4r> for Ruby

=item * L<PhlongTaIam|https://github.com/veer66/PhlongTaIam> for PHP

=item * L<ThaiWordseg|http://thaiwordseg.sourceforge.net/> for C

=item * L<libthai|http://linux.thai.net/projects/libthai> for C

=item * L<Lingua::TH::Segmentation> interface to ThaiWordseg for Perl

=back

=head1 ACKNOWLEDGEMENTS

This module is based on <thailang4r|https://github.com/veer66/thailang4r> for
Ruby by <Vee Satayamas|https://github.com/veer66>.

This module is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2013 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
