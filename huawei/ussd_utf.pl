#!/usr/bin/perl
use Encode;

my $utf16='50083406F5417BD01AB4171580A28368202A80C2A03B10140782FEA03EE80EEA83DAA038E80E14154401D1013406D5450701';
my $utf8=pdu_ussd_utf8($utf16);
print "\n--------------------\n";
print "USSD: [$utf16]\n";
print "UTF8: [$utf8]\n";
print "\n--------------------\n";



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
    my $l_ret=pack "H*",$l_pdu;
    Encode::from_to($l_ret,'UTF-16BE','UTF-8');
    return $l_ret;
}
