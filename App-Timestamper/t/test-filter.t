#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Time::HiRes qw/time/;

use App::Timestamper::Filter::TS;

{
    my @results;

    my $start = time();

    my $obj = App::Timestamper::Filter::TS->new;

    # TEST
    ok ($obj, "Object was initialized.");

}

