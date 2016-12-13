#!/usr/bin/perl

use Device::Gsm;
use Encode;

$content = "ПРИВЕТ";
#Encode::from_to($content, "UTF-8", "UCS2");
#Encode::from_to($content, "UTF-8", "UTF-16BE");

my $gsm = new Device::Gsm( port => '/dev/ttyUSB2' );
         if( $gsm->connect() ) {
             print "connected!\n";
         } else {
             print "sorry, no connection with gsm phone on serial port!\n";
         }
my $lOk = $gsm->send_sms(
    content => $content,
    #recipient => '+79216126338',
    recipient => '+79114531517',
    class     => 'normal',     # try 'normal' 'flash'
    mode      => 'pdu'
                        );
if( $lOk ) {
    print "SMS check money sent!\n" ;
} else {
    print "Error in sending!\n";
    exit ;
}