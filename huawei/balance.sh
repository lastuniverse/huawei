#!/bin/bash
if [ -e $1 ]; then
echo "Введите номер порта";

    else 

n=$1;    
F="/dev/ttyUSB$n"
echo -e "AT+CUSD=1,*102#,15\r">$F
head -n 4 $F | \
perl -ne '@a = m/([0-9A-F]{4})/g; map { eval "print \"\\x{$_}\""; } @a;' 2>/dev/null
echo ""

fi