#! /usr/bin/env perl

# Copyright (c) 2020 Shlomi Fish ( https://www.shlomifish.org/ )
# Author: Shlomi Fish ( https://www.shlomifish.org/ )
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# -------------------------
#
# timestamper-with-elapsed.pl
#
# Based on the synopses of https://metacpan.org/release/IO-Async
# by PEVANS (Paul Evans) and relicensed as MIT License with his
# permission. Thanks!

use strict;
use warnings;
use 5.014;
use autodie;

use Time::HiRes qw/ time /;

use IO::Async::Stream          ();
use IO::Async::Loop            ();
use IO::Async::Timer::Periodic ();
my $loop = IO::Async::Loop->new;

my $last_line_time = time();
STDOUT->autoflush(1);
my $timer = IO::Async::Timer::Periodic->new(
    interval => 0.1,

    on_tick => sub {
        my $t = time();
        printf "\r%.8f elapsed", $t - $last_line_time;

        return;
    },
);

my $stream = IO::Async::Stream->new(
    read_handle => \*STDIN,
    on_read     => sub {
        my ( $self, $buffref, $eof ) = @_;

        while ( $$buffref =~ s/\A([^\n]*\n)//ms )
        {
            my $l = $1;
            my $t = time();
            printf "\r%.8f\t%s", $t, $l;
            $last_line_time = $t;
        }

        if ($eof)
        {
            printf "%.8f\t%s\n", time(), $$buffref;
        }

        return 0;
    }
);

$loop->add($stream);
$timer->start();
$loop->add($timer);
$loop->run();
