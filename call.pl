#!/usr/bin/perl
#use Device::Gsm::Pdu;

# defaults
$port = "/dev/ttyUSB2";

my $phone = '+79114531500';
print "PHONE: $phone\n";
print "TIME: [".time."]\n";

phone_send('AT','OK');
phone_send("ATD$phone;",'CONN:1,0',20);
#sleep 10;




sub ussd_pdu{
    my $l_ussd=shift;
    @a=split(//,unpack("b*",$l_ussd));
    for ($i=7; $i < $#a; $i+=8){
	$a[$i]="";
    }
    my $l_ret= uc(unpack("H*", pack("b*", join("", @a))))."";
    return $l_ret;
}
sub pdu_ussd{
    my $l_pdu=shift;
    @a=split(//,unpack("b*", pack("H*",$l_pdu)));
    for ($i=6; $i < $#a; $i+=7) {
	$a[$i].="0";
    }
    my $l_ret= pack("b*", join("", @a))."";
    return $l_ret;
}

sub phone_send{
    my $l_ptr=shift;
    my $l_answer=shift;
    my $l_timeout=shift;
    open my $l_port, '+<', "$port" or die "Can't open '$opt_s': $!\n";
    print $l_port "$l_ptr\r";
    print "Дана команда: [$l_ptr]\n";
    phone_answer($l_port,$l_answer,$l_timeout);
    close $l_port;
}

sub phone_answer{
    my $l_port=shift;
    my $l_ptr=shift;
    my $l_timeout=shift;
    print "Ждем ответа [$l_ptr]\n";
    my $l_timestart=time;
    while (<$l_port>) {
	~s/[\n\r]+//g;
	my $l_timecurrent=time;
	print "[$_]\n" if $_;
	if( $l_ptr && /$l_ptr/ ){
	    print "Ответ [$l_ptr] получен\n";
	    last;
	}
	if( $l_timeout && ($l_timecurrent-$l_timestart)>=$l_timeout ){
	    print "Закончилось время ожидания [$l_timeout]\n";
	    last;
	}
    }
}
