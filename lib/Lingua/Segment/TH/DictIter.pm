package Lingua::Segment::TH::DictIter;

use v5.8;
use utf8;
use Moo;
use Lingua::Segment::TH::Dict;

our $VERSION = '0.01';

has dict => (
    is      => 'ro',
    builder => sub { Lingua::Segment::TH::Dict->new },
);

has start => (
    is      => 'rw',
    default => sub { 0 },
);

has end => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { scalar @{shift->dict->words} },
);

has offset => (
    is      => 'rw',
    default => sub { 0 },
);

has state => (
    is      => 'rw',
    default => sub { 'active' },
);

sub walk {
    my ($self, $char) = @_;

    if ($self->state ne 'invalid') {
        my $first = $self->dict->get_index(
            'first',
            $char,
            $self->offset,
            $self->start,
            $self->end,
        );

        if (!defined $first) {
            $self->state('invalid');
        }
        else {
            $self->start($first);
            my $last = $self->dict->get_index(
                'last',
                $char,
                $self->offset,
                $self->start,
                $self->end,
            );
            $self->end($last + 1);
            $self->offset($self->offset + 1);
            my $len = length $self->dict->words->[$first];
            $self->state(
                $self->offset == $len ? 'active boundary' : 'active'
            );
        }
    }

    return $self->state;
}

1;
