#! /usr/bin/env perl
#
# Short description for timestamper-realtime.pl
#
# Author Shlomi Fish <shlomif@cpan.org>
# Version 0.0.1
#
# Based on the synopses of https://metacpan.org/release/IO-Async
# by PEVANS (Paul Evans). Thanks!

use strict;
use warnings;
use 5.014;
use autodie;

use Time::HiRes qw/ time /;
use Number::Format::BigFloat qw/ format_number /;
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
            my $t = time();
            my $l = $1;
            printf "\r%.8f\t%s", $t,
                ( $l =~
s#(\d+((?:\.\d*)?))#format_number("$1", {decimal_digits=>(length($2)?3:0),},)#egr
                );
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
