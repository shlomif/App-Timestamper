package App::Timestamper::WithElapsed;

use strict;
use warnings;
use 5.014;
use autodie;

# -------------------------
#
# timestamper-with-elapsed.pl
#
# Based on the synopses of https://metacpan.org/release/IO-Async
# by PEVANS (Paul Evans) and relicensed as MIT License with his
# permission. Thanks!

use Getopt::Long 2.37 qw/ GetOptionsFromArray /;
use Time::HiRes qw/ time /;

use IO::Async::Stream          ();
use IO::Async::Loop            ();
use IO::Async::Timer::Periodic ();

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _from_start
{
    my $self = shift;

    if (@_)
    {
        $self->{_from_start} = shift;
    }

    return $self->{_from_start};
}

sub _init
{
    my ( $self, $args ) = @_;
    my $argv = ( $args->{argv} // [] );

    my $from_start;
    GetOptionsFromArray( $argv, 'from-start!' => \$from_start, )
        or die $!;
    $self->_from_start($from_start);
    return;
}

sub run
{
    my $self = shift;
    my $loop = IO::Async::Loop->new;

    my $last_line_time = time();
    my $init_time      = $self->_from_start ? ( $last_line_time + 0 ) : 0;
    STDOUT->autoflush(1);
    my $timer = IO::Async::Timer::Periodic->new(
        interval => 0.1,

        on_tick => sub {
            my $t = time();
            printf "\r%.8f elapsed", $t - $last_line_time;

            return;
        },
    );
    my $out = sub {
        my $t = shift;
        my $l = shift;
        chomp $l;
        my $s = sprintf( "%.8f    %s", $t - $init_time, $l );
        printf "\r%-70s\n", $s;
        return;
    };

    my $stream = IO::Async::Stream->new(
        read_handle => \*STDIN,
        on_read     => sub {
            my ( $self, $buffref, $eof ) = @_;

            while ( $$buffref =~ s/\A([^\n]*\n)//ms )
            {
                my $l = $1;
                my $t = time();
                $out->( $t, $l );
                $last_line_time = $t;
            }

            if ($eof)
            {
                $out->( time(), $$buffref );
            }

            return 0;
        }
    );

    $loop->add($stream);
    $timer->start();
    $loop->add($timer);
    $loop->run();

    return;
}

1;

__END__

=head1 NAME

App::Timestamper::WithElapsed - display the timestamp STDIN lines were received and the elapsed
seconds since the last received line.

=head1 SYNOPSIS

    $ [process] | perl -MApp::Timestamper::WithElapsed -e 'App::Timestamper::WithElapsed->new->run'

=head1 METHODS

=head2 new

Constructor

=head2 run

Run the application .

=head1 CREDITS

Based on the synopses of L<https://metacpan.org/release/IO-Async>
by PEVANS (Paul Evans) and relicensed as MIT License with his
permission. Thanks!

=cut
