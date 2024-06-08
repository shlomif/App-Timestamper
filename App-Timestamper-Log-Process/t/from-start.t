#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use Path::Tiny qw/ path tempdir tempfile cwd /;

my $dir = tempdir( 'CLEANUP' => 1 );
my $ofn = $dir->child("output.log.txt");
my $inputfn =
    cwd()->child( "t", "data", "sample-input-logs", "hp1.build.log.txt" );

my $expected_results_fn =
    cwd()
    ->child( "t", "data", "expected-output", "from-start",
    "hp1.build.log.txt" );

{
    system(
        $^X,  "-Mblib", "-MApp::Timestamper::Log::Process",
        "-e", "App::Timestamper::Log::Process->new({argv => [\@ARGV,]})->run()",
        "--", "from_start", "--output", $ofn, $inputfn,
    );

    # TEST
    ok( scalar( -f $ofn ), "from_start app-mode produced a file", );

    # TEST
    is_deeply(
        [ $ofn->lines_utf8(), ],
        [ $expected_results_fn->lines_utf8(), ],
        "Expected from-start results ",
    )
}
