package App::Timestamper::Filter::TS;

use strict;
use warnings;

use Time::HiRes qw/time/;

sub new
{
    return bless {}, shift;
}

sub fh_filter
{
    my ($self, $in, $out) = @_;

    while (my $l = <$in>)
    {
        $out->(sprintf('%.9f', time()) . "\t" . $l);
    }

    return;
}


1;

=head1 METHODS

=head2 App::Timestamper::Filter::TS->new();

A constructor. Does not accept any options for now.

=head2 $obj->fh_filter($in_filehandle, $out_cb)

Reads line from $in_filehandle until eof() and for each line call $out_cb
with a string containing the timestamp when the line was read, a \t
character and the line itself.

=cut
