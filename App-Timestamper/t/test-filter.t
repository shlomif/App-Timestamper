#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use 5.008;

use Test::More tests => 9;
use Time::HiRes qw/time/;

use App::Timestamper::Filter::TS;

{
    my @results;

    my $start = time();

    my $obj = App::Timestamper::Filter::TS->new;

    # TEST
    ok ($obj, "Object was initialized.");

    my $TEXT = "First line\nSecond line\nLine\twith-tab.\nFinal line.\n";

    open my $in_fh, '<', \$TEXT;

    $obj->fh_filter($in_fh, sub {
            my ($l) = @_;

            # TEST:$num_lines=4;
            if (my ($time, $s) = $l =~ m#\A([0-9]+(?:\.[0-9]+)?)\t([^\n]+\n)\z#)
            {
                # TEST*$num_lines
                ok (1, "String matched.");
                push @results, +{ts => $time, str => $s, };
            }
            else
            {
                ok (0, "String failed.");
            }
        }
    );

    # TEST
    is ($results[0]->{str}, "First line\n");
    # TEST
    is ($results[1]->{str}, "Second line\n");
    # TEST
    is ($results[2]->{str}, "Line\twith-tab.\n");
    # TEST
    is ($results[3]->{str}, "Final line.\n");

    close ($in_fh);

}

