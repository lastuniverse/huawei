#!/usr/bin/perl


use IO::File;

my $number='+79814621397';
$number='+79114531517';

$OPT_I = "/dev/ttyUSB1"; $OPT_O = "/dev/ttyUSB2"; $PATH_WAV = "all-circuits-busy.wav";

open (SENDPORT, '+<', $OPT_O) or die "Can't open '$OPT_O': $!\n";
print SENDPORT "AT;\r";
print "SEND: AT;\n";
my $test=1;
while ( $test ) { 
    my $recive=<SENDPORT>;
    print "RECIVE: [$recive]\n";
    $test=0 if $recive=~/OK/;
}


print SENDPORT "AT^DDSETEX=2\r";
print "SEND: AT^DDSETEX=2\n";
$test=1;
while ( $test ) { 
    my $recive=<SENDPORT>;
    print "RECIVE: [$recive]\n";
    $test=0 if $recive=~/OK/;
}


print SENDPORT "ATD$number;\r";
print "SEND: ATD$number;\n";
$test=1;
while ( $test ) { 
    my $recive=<SENDPORT>;
    print "RECIVE: [$recive]\n";
    $test=0 if $recive=~/OK/;
}
$test=1;
while ( $test ) { 
    my $recive=<SENDPORT>;
    print "RECIVE: [$recive]\n";
    $test=0 if $recive=~/\^CONN:1,0/;
    sleep 1;
}
print "GO GO GO\n";



print SENDPORT "AT^DDSETEX=2\r";
print "SEND: AT^DDSETEX=2\n";
$test=1;
while ( $test ) { 
    my $recive=<SENDPORT>;
    print "RECIVE: [$recive]\n";
    $test=0 if $recive=~/OK/;
}



#$test=1;
#while ( $test ) { 
#    my $recive=<SENDPORT>;
#    print "RECIVE: [$recive]\n";
#    #$test=0 if $recive=~/\^CONN:1,0/;
#    sleep 1;
#}



close SENDPORT;
sleep 1;

open (SENDPORT_WAV, '+<', $OPT_I) or die "Can't open '$OPT_I': $!\n";
my $FILE = new IO::File "< $PATH_WAV" or die "Cannot open $PATH_WAV : $!";
binmode($FILE);
my $BUFER;
my $BUFLEN = 320;
seek($FILE,44,0);
while (read($FILE,$BUFER,$BUFLEN)) {
    print SENDPORT_WAV $BUFER; sleep(0.2);
}
close SENDPORT_WAV;

sleep 3;

open (SENDPORT, '+<', $OPT_O) or die "Can't open '$OPT_O': $!\n";
print SENDPORT "AT+CHUP\r";
close SENDPORT;