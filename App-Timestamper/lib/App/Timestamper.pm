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

    local @ARGV = @$argv;

    App::Timestamper::Filter::TS->new->fh_filter(\*ARGV, sub {print $_[0];});

    return;
}

1;

__END__

=head1 NAME

App::Timestamper - prefix lines with the timestamps of their arrivals.

=head1 SYNOPSIS

    use App::Countdown;

    App::Countdown->new({ argv => [@ARGV] })->run();

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

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. Accepts the argv named arguments.

=head2 run

Runs the program.

=cut
