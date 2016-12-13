#!/usr/bin/perl

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
clock_gettime clock_getres clock_nanosleep clock
stat );

use IO::File;
$|=1;

#my $number='+79814621397';
#my $number='+79118651755';
my $number='+79114531517';

$OPT_I = "/dev/ttyUSB1";
$OPT_O = "/dev/ttyUSB3";
$PATH_WAV = "all-circuits-busy.wav";

open my $SENDPORT, '+<', $OPT_O or die "Can't open '$OPT_O': $!\n";


#at_send('AT+CFUN=1',qr/OK/,$SENDPORT);
at_send('AT');
#at_send('AT^CVOICE=0');
#at_send('ATX1');
#exit_call();

exit_call() if 'NO CARRIER' eq at_send("ATD$number;",qr/(OK|NO CARRIER)/);
exit_call() if 'CEND:' eq  at_rec(qr/\^(CONN\:1\,0|CEND\:)/);
print "GO GO GO\n";
exit_call() if 'CEND:' eq  at_send('AT^DDSETEX=2',qr/(OK|CEND\:)/);
print "VOICE\nn";


open my $SENDPORT_WAV, '+<', $OPT_I or die "Can't open '$OPT_I': $!\n";
my $FILE = new IO::File "< $PATH_WAV" or die "Cannot open $PATH_WAV : $!";
binmode($FILE);
my $BUFER;
my $BUFLEN = 320;
seek($FILE,44,0);
while (read($FILE,$BUFER,$BUFLEN)) {
	$|=1;
        print SENDPORT_WAV $BUFER; usleep(200000);
}

exit_call();











sub at_rec{
    my $l_rx = shift || qr/OK/;
    my $l_inport = $SENDPORT;
    print "WHILE: /$l_rx/\n";
    my $test=1;
    my $recive='';
    while ( $test ) { 
	$recive=<$l_inport>;
	chomp $recive;
	print "\tRECIVE: [$recive]\n"  if $recive;
	$test=0 if $recive=~$l_rx;
    }
    $recive=~$l_rx;
    $1;
}

sub at_send{
    my $l_cmd = shift;
    my $l_rx = shift || qr/(OK)/;
    my $l_inport = $SENDPORT;
    print $SENDPORT "$l_cmd\r";
    print "SEND: [$l_cmd]\n";
    my $test=1;
    my $recive='';
    while ( $test ) { 
	$recive=<$l_inport>;
	chomp $recive;
	print "\tRECIVE: [$recive]\n"  if $recive;
	$test=0 if $recive=~$l_rx;
    }
    $recive=~$l_rx;
    $1;
}

sub hangup{
    open my $SENDPORT, '+<', $OPT_O or die "Can't open '$OPT_O': $!\n";
    print $SENDPORT "AT+CHUP\r";
    close $SENDPORT;
}

sub exit_call{
    print "THE END\n";
    close $SENDPORT_WAV;
    close $SENDPORT;
    hangup();
    exit 0;

}