#!/usr/bin/perl
#use Device::Gsm::Pdu;
##use Text::Iconv;
##$conv = Text::Iconv->new('utf16be','utf8');
use Encode;

# defaults
$opt_r = "/dev/ttyUSB2";
$opt_s = "/dev/ttyUSB0";

my $ussd = '*100#';
print "USSD MSG: $ussd\n";
my $ussd_req = ussd_pdu($ussd);
print "PDU ENCODED: [$ussd_req]\n";

#$ussd_req = Device::Gsm::Pdu::encode_text7($ussd);
#$ussd_req =~ s/^..//;
#print "PDU ENCODED: [$ussd_req]\n";


my $ussd_reply;
    open (SENDPORT, '+<', $opt_s) or die "Can't open '$opt_s': $!\n";
    print SENDPORT 'AT+CUSD=1,',"$ussd_req",",15\r\n";
    close SENDPORT;
    open (RCVPORT, $opt_r) or die "Can't open '$opt_r': $!\n";
    print "Waiting for USSD reply...\n";
    while (<RCVPORT>) {
        chomp;
        die "USSD ERROR\n" if $_ eq "+CUSD: 2";
        if (/^\+CUSD: 0,\"([A-F0-9]+)\"/) {
            $ussd_reply = $1;
            print "PDU USSD REPLY: $ussd_reply\n";
            last;
        }
        print "Got unknown USSD message: $_\n" if /^\+CUSD:/;
    }


if($ussd_reply){
    $decoded_ussd_reply = pdu_ussd_utf8($ussd_reply);
    print STDOUT "USSD REPLY: $decoded_ussd_reply\n";
}else{
    print "No USSD reply!\n";
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

sub pdu_ussd_utf8{
    my $l_pdu=shift;
    my $l_ret=pack "H*",$ussd_reply;
    Encode::from_to($decoded_ussd_reply,'UTF-16BE','UTF-8');
    return $l_ret;
}

