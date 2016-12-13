#!/usr/bin/perl

use Inline CPP;

print "9 + 16 = ", add(9, 16), "\n";
print "9 - 16 = ", subtract(9, 16), "\n";

__END__
__CPP__

int add(int x, int y) {
	return x + y;
}

int subtract(int x, int y) {
	return x - y;
}




