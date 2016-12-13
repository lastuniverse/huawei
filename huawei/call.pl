#!/usr/bin/perl
use Encode;
#use Device::Gsm::Pdu;

# defaults
$port_term = "/dev/ttyUSB2";
$port_ussd = "/dev/ttyUSB2";

my $phone = '+79114531517';
#my $phone = '+79114531500'; # Леночка
#my $phone = '+79052418171'; # Зуйков
#my $phone = '+79520563918';  # Кондратьев
print "PHONE: $phone\n";
print "TIME: [".time."]\n";


#phone_send("ATZ\r",'OK');

phone_send("AT\r",'OK');
phone_send("ATD$phone;\r",'CEND',60);
phone_answer(undef,'CEND',60);

#phone_send('AT^DDSETEX=1','OK');


# отправка SMS транслит
#phone_send("AT\r",'OK');
#phone_send("AT+CMGF=1\r",'OK');
#phone_send("AT+CMGS=\"$phone\"\r");
#phone_send("test\x1A",'OK');

# отправка SMS русский
#    $phone=~/(\d+)/;
#    my $smsphone = "$1F";
#    my $count=0;
#    my @smsphone = split(//,$smsphone);
#    my $revercephone='';
#    my $tempphone='';
#    for my $cur ( @smsphone ){
#	$count=1-$count;
#	if( $count ){
#	    $tempphone=$cur;
#	}else{
#	    $revercephone.=$cur.$tempphone;
#	}
#    }
#    print "\nPHONE: [$smsphone]\n";
#    print "\nREVER: [$revercephone]\n";
#    my $smstext="Ты не гавнюк";
#    my $smspdu=utf8_pdu($smstext);
#    my $textlen=length($smspdu)/2;
#    my $smslen=14+$textlen;
#    print "\nTEXT(10): [$textlen]\n";
#    $textlen=sprintf "%x", $textlen;
#    if( length($textlen)<2 ){ $textlen="0$textlen"; }
#    print "\nTEXT(16): [$textlen]\n";
#phone_send("AT\r",'OK');
##phone_send("AT+CMGF=?\r",'OK');
##phone_send("AT+CMGF?\r",'OK');
#phone_send("AT+CMGF=0\r",'OK');
#phone_send("AT+CSMS=0\r",'OK');
#phone_send("AT+CMGS=$smslen\r");
#phone_send("0011000B91".$revercephone."0008AA".$textlen.$smspdu."\x1A",'OK');
##phone_send("AT+CMGS=22\r");
##phone_send("0011000B919711541315F70008AA080442043504410442\x1A",'OK');





#sleep 10;





sub phone_send{
    my $l_ptr=shift;
    my $l_answer=shift;
    my $l_timeout=shift;
    open my $l_port, '+<', "$port_term" or die "Can't open '$port_term': $!\n";
    print $l_port $l_ptr;
    chop $l_ptr;
    print "Дана команда: [$l_ptr]\n";
    phone_answer($l_port,$l_answer,$l_timeout);
    close $l_port;
}

sub phone_answer{
    my $l_port=shift;
    my $l_ptr=shift;
    my $l_timeout=shift;
    my $l_porttest=0;
#    if( !$l_port ){
#	$l_porttest=1;
#	open $l_port, '+<', "$port_term" or die "Can't open '$port_term': $!\n";
#    }
    if( $l_ptr ){
	print "Ждем ответа [$l_ptr]\n";
        while (<$l_port>) {
	    ~s/[\n\r]+//g;
	    print "[$_]\n" if $_;
	    if( $l_ptr && $_=~/$l_ptr/ ){
		print "Ответ [$l_ptr] получен\n";
		last;
	    }elsif( $_=~/ERROR/ ){
		print "ERROR: получено сообщение об ошибке\n";
		last;
	    }
	}
    }
#    if( $l_porttest ){
#	close $l_port;
#    }
}

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

sub pdu_utf8{
    my $l_pdu=shift;
    my $l_ret=pack "H*",$l_pdu;
    Encode::from_to($l_ret,'UCS2','UTF-8');
    return $l_ret;
}

sub utf8_pdu{
    my $l_text = shift;
    Encode::from_to($l_text, 'UTF-8', 'UCS2');
    my $l_ret = unpack "H*", $l_text;
    return "$l_ret";
}
