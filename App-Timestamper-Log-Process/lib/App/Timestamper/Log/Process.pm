package App::Timestamper::Log::Process;

use 5.014;
use strict;
use warnings;
use autodie;

use bigint;

use Carp                ();
use File::ReadBackwards ();
use Getopt::Long        qw( GetOptionsFromArray  );

# use parent qw(ParentClass);

sub _argv
{
    my $self = shift;

    if (@_)
    {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ( $self, $args ) = @_;
    $self->_argv( $args->{argv} // ( die "no argv key" ) );

    return;
}

my $NUM_DIGITS = 16;
my $LOW_BASE   = 10;
my $HIGH_BASE  = 1;
foreach my $e ( 1 .. $NUM_DIGITS )
{
    $HIGH_BASE *= $LOW_BASE;
}
my $OUT_NUM_DIGITS = 8;
my $TO_OUT_BASE    = 1;
foreach my $e ( 1 .. ( $NUM_DIGITS - $OUT_NUM_DIGITS ) )
{
    $TO_OUT_BASE *= $LOW_BASE;
}

sub run
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();

    my $mode = shift(@$argv);

    if ( ( $mode eq "from_start" ) or ( $mode eq "from-start" ) )
    {
        return $self->_mode_from_start();
    }
    elsif ( ( $mode eq "time" ) )
    {
        return $self->_mode_time();
    }
    else
    {
        Carp::confess("Unknown mode '$mode'!");
    }

    return;
}

sub _mode_from_start
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();
    my $output_fn;
    my $ret = GetOptionsFromArray( $argv, "output|o=s" => ( \$output_fn ), )
        or Carp::confess($!);
    my $input_fn = shift(@$argv);
    if ( not defined($input_fn) )
    {
        die "Must specify an input file-path!";
    }
    if (@$argv)
    {
        die "Leftover command-line arguments after the input filename";
    }

    my $USE_STDOUT = ( not( defined($output_fn) and ( $output_fn ne "-" ) ) );

    my $out;
    if ($USE_STDOUT)
    {
        ## no critic
        open $out, ">&STDOUT";
        ## use critic
    }
    else
    {
        open $out, ">", $output_fn;
    }
    open my $in, "<", $input_fn;
    my $start;

    while ( my $line = <$in> )
    {
        chomp $line;
        if ( my ( $seconds, $dotdigits, $data_str ) =
            ( $line =~ m#\A([0-9]+)((?:\.(?:[0-9]){0,16})?)\t([^\n]*\z)#ms ) )
        {
            my $ticks = $seconds * $HIGH_BASE;
            if ( $dotdigits =~ s#\A\.##ms )
            {
                $dotdigits .=
                    scalar( "0" x ( $NUM_DIGITS - length($dotdigits) ) );
                $ticks += ( 0 + $dotdigits );
            }
            if ( not defined($start) )
            {
                $start = $ticks;
            }
            my $distance     = $ticks - $start;
            my $dist_seconds = $distance / $HIGH_BASE;
            my $dist_dot     = $distance % $HIGH_BASE;
            $dist_dot /= $TO_OUT_BASE;
            $out->printf(
                "%d\.%0*d\t%s\n", $dist_seconds, $OUT_NUM_DIGITS,
                $dist_dot,        $data_str
            );
        }
        else
        {
            die "The line is formatted wrong";
        }
    }

    close($in);
    if ( not $USE_STDOUT )
    {
        close($out);
    }

    return;
}

sub _mode_time
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();
    my $output_fn;
    my $ret = GetOptionsFromArray( $argv, "output|o=s" => ( \$output_fn ), )
        or Carp::confess($!);
    my $USE_STDOUT = ( not( defined($output_fn) and ( $output_fn ne "-" ) ) );

    my $out;
    if ($USE_STDOUT)
    {
        ## no critic
        open $out, ">&STDOUT";
        ## use critic
    }
    else
    {
        open $out, ">", $output_fn;
    }
    while (@$argv)
    {
        my $input_fn = shift(@$argv);
        if ( not defined($input_fn) )
        {
            die "Must specify an input file-path!";
        }

        open my $in, "<", $input_fn;
        my $start;

        {
            my $line = <$in>;
            chomp $line;
            if (
                my ( $seconds, $dotdigits, $data_str ) = (
                    $line =~ m#\A([0-9]+)((?:\.(?:[0-9]){0,16})?)\t([^\n]*\z)#ms
                )
                )
            {
                my $ticks = $seconds * $HIGH_BASE;
                if ( $dotdigits =~ s#\A\.##ms )
                {
                    $dotdigits .=
                        scalar( "0" x ( $NUM_DIGITS - length($dotdigits) ) );
                    $ticks += ( 0 + $dotdigits );
                }
                die if ( defined($start) );
                $start = $ticks;
            }
            else
            {
                die "The line is formatted wrong";
            }
        }

        close($in);

        my $bw_in = File::ReadBackwards->new($input_fn)
            or Carp::confess("can't open $input_fn backwards $!");
        my $end_ticks;
        {
            my $line = $bw_in->readline();
            chomp $line;
            $bw_in->close();
            if (
                my ( $seconds, $dotdigits, $data_str ) = (
                    $line =~ m#\A([0-9]+)((?:\.(?:[0-9]){0,16})?)\t([^\n]*\z)#ms
                )
                )
            {
                $end_ticks = $seconds * $HIGH_BASE;
                if ( $dotdigits =~ s#\A\.##ms )
                {
                    $dotdigits .=
                        scalar( "0" x ( $NUM_DIGITS - length($dotdigits) ) );
                    $end_ticks += ( 0 + $dotdigits );
                }
            }
            else
            {
                die "The line is formatted wrong";
            }
        }
        my $distance     = $end_ticks - $start;
        my $dist_seconds = $distance / $HIGH_BASE;
        my $dist_dot     = $distance % $HIGH_BASE;
        $dist_dot /= $TO_OUT_BASE;
        $out->printf(
            "%d\.%0*d\t%s\n", $dist_seconds, $OUT_NUM_DIGITS,
            $dist_dot,        $input_fn,
        );
    }

    if ( not $USE_STDOUT )
    {
        close($out);
    }

    return;
}

1;

__END__

=encoding utf8

=head1 NAME

App::Timestamper::Log::Process - various filters and queries for
L<App::Timestamper> logs.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 my $app_obj = App::Timestamper::Log::Process->new({argv => [@ARGV],});

Instantiate a new application object.

=head2 $app_obj->run()

Run the application based on the Command-Line (“CLI”) arguments.

=head1 MODES

=head2 from_start

    timestamper-log-process from_start --output zero-based.ts.log.txt absolute-timestamps.ts.log.txt

Start the timestamps from 0 by negating the one on the first line.

=head2 time

    timestamper-log-process time --output run-times-of-log-files.txt [files]

Calculate the wallclock times, from-start-to-finish, of one or more timestamper log files.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
