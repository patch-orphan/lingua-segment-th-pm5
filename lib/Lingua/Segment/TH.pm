package Lingua::Segment::TH;

use v5.8;
use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use parent 'Exporter';
use Lingua::Segment::TH::DictIter;

our $VERSION = '0.01';
our @EXPORT_OK = qw( segment segment_th );

my $S              = 0;
my $E              = 1;
my $LINK_TYPE      = 2;
my $POINTER        = 0;
my $WEIGHT         = 1;
my $PATH_UNK       = 2;
my $PATH_LINK_TYPE = 3;

#*segment_th = \&segment;

sub segment {
    my ($text) = @_;
    my $len    = length $text;
    my @dag    = get_dag($text, $len);
    my @ranges = get_ranges(\@dag, $len);

    return map {
        substr $text, $_->[$S], $_->[$E] - $_->[$S]
    } @ranges;
}

sub get_dag {
    my ($text, $len) = @_;
    my @dag;

    for my $i (0 .. $len - 1) {
        my $iter = Lingua::Segment::TH::DictIter::build_iter();

        for my $j ($i .. $len - 1) {
            my $char   = substr $text, $j, 1;
            my $status = $iter->($char);

            last if $status eq 'invalid';
            next if $status ne 'active boundary';

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

sub get_ranges {
    my ($dag, $len) = @_;
    my $s_index = _build_s_index($dag);
    my $e_index = _build_e_index($dag);
    my $path    = _build_path($len, $s_index, $e_index);

    return _path_to_ranges($path, $len);
}

sub _build_s_index {
    my ($dag) = @_;

    return _build_index($dag, $S);
}

sub _build_e_index {
    my ($dag) = @_;

    return _build_index($dag, $E);
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
    my ($len, $s_index, $e_index) = @_;
    my $left_boundary = 0;
    my @path = (undef) x ($len + 1);
    $path[0] = [0, 0, 0, 'unk'];

    for my $i (1 .. $len) {
        if ( $e_index->{$i} ) {
            for my $range ( @{$e_index->{$i}} ) {
                my $s = $range->[$S];

                if ( $path[$s] ) {
                    my $info = [
                        $s,
                        $path[$s][$WEIGHT] + 1,
                        $path[$s][$PATH_UNK],
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

        if ( !$path[$i] && $s_index->{$i} ) {
            $path[$i] = [
                $left_boundary,
                $path[$left_boundary][$WEIGHT]   + 1,
                $path[$left_boundary][$PATH_UNK] + 1,
                'unk',
            ];
        }
    }

    $path[$len] ||= [
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

sub _path_to_ranges {
    my ($path, $len) = @_;
    my @ranges;
    my $i = $len;

    while ($i > 0) {
        my $info = $path->[$i];
        my $s    = $info->[$POINTER];

        push @ranges, [ $s, $i, $info->[$PATH_LINK_TYPE] ];

        $i = $s;
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

=item * L<thailang4r|https://github.com/veer66/thailang4r>

=item * L<ThaiWordseg|http://thaiwordseg.sourceforge.net/>

=item * L<libthai|http://linux.thai.net/projects/libthai>

=item * L<Lingua::TH::Segmentation>

=back

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2013 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
