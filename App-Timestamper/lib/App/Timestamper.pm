package App::Timestamper;

use strict;
use warnings;

use Getopt::Long qw(2.36 GetOptionsFromArray);
use Pod::Usage qw/pod2usage/;

use App::Timestamper::Filter::TS;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    my $argv = [@{$args->{argv}}];

    my $help = 0;
    my $man = 0;
    my $version = 0;
    if (! (my $ret = GetOptionsFromArray(
        $argv,
        'help|h' => \$help,
        man => \$man,
        version => \$version,
    )))
    {
        die "GetOptions failed!";
    }

    if ($help)
    {
        pod2usage(1);
    }

    if ($man)
    {
        pod2usage(-verbose => 2);
    }

    if ($version)
    {
        print "timestamper version $App::Timestamper::VERSION .\n";
        exit(0);
    }

    $self->{_argv} = $argv;
}

sub run
{
    my ($self) = @_;

    local @ARGV = @{$self->{_argv}};

    App::Timestamper::Filter::TS->new->fh_filter(\*ARGV, sub {print $_[0];});

    return;
}

1;

__END__

=encoding utf8

=head1 NAME

App::Timestamper - prefix lines with the timestamps of their arrivals.

=head1 SYNOPSIS

    use App::Timestamper;

    App::Timestamper->new({ argv => [@ARGV] })->run();

=head1 DESCRIPTION

App::Timestamper is a pure-Perl command line program that filters the input
so the timestamps (in seconds+fractions since the UNIX epoch) are prefixed
to the lines based on the time of the arrival.

So if the input was something like:

    First Line
    Second Line
    Third Line

It will become something like:

    1435254285.978485482\tFirst Line
    1435254302.569615087\tSecond Line
    1435254319.809459781\tThird Line

=head2 Some use cases

Some people asked me what is B<timestamper> useful for, so I'll try to
explain because I wrote the first version out of a need.

Let's suppose you have a simulation that outputs a "Reached $N iterations"
line after every certain number of iterations. Like so:

    Reached 100000 iterations
    Reached 200000 iterations
    Reached 300000 iterations
    .
    .
    .

You wish to draw a graph of iterations vs. time to analyse the performance
of the program. So what you can do is pipe it through B<timestamper> and then
get:

    1435254285.978485482\tReached 100000 iterations
    1435254302.569615087\tReached 200000 iterations
    1435254319.809459781\tReached 300000 iterations

And after putting it in a file (using "tee" or whatever), you can filter
the lines like this:

    perl -lane 'print "$1\t$2" if /\A([0-9\.]+)\tReached ([0-9]+) iterations\z/'

And get a nice tab-separated-value report of the time stamps in seconds and
the iterations which you can plot using your favourite spreadsheet program
or visualation framework.

Hope it helps.

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. Accepts the argv named arguments.

=head2 run

Runs the program.

=head1 SEE ALSO

=head2 “ts” from “moreutils”

“ts” is a program that is reportedely similar to “timestamper” and
is contained in joeyh’s “moreutils” (see L<http://joeyh.name/code/moreutils/>)
package. It is not easy to find online.

=head2 Chumbawamba’s song “Tubthumping”

I really like the song “Tubthumping” by Chumbawamba, which was a hit during
the 1990s and sounds similar to “Timestamping”, so please check it out:

=over 4

=item * English Wikipedia Page

L<http://en.wikipedia.org/wiki/Tubthumping>

=item * YouTube Search for the Video

L<http://www.youtube.com/results?search_query=chumbawamba%20tubthumping>

=back

=cut
