#!/usr/bin/perl
use Encode;

my $utf16='041204300448002004370430043F0440043E04410020043F04400438043D044F0442002C0020043E04360438043404300439044204350020043E04420432043504420020043F043E00200053004D0053002E';
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
