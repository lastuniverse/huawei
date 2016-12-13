#!/usr/bin/perl

my $pin='xxxx';
my $phone='+79114531500';

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

print "\n-----------------\n";
print ussd_pdu('*111#');
print "\n";
print pdu_ussd(ussd_pdu('*111#'));
print "\n-----------------\n";