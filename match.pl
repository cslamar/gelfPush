#!/usr/bin/perl

while( <> ) {
	chomp($_);
#	print "$_\n";

	($host, $remote_logname, $remote_user, $timestamp, $request, $statusCode, $size_of_request, $refer, $user_agent, $timeServed, $pid, $hostname) = $_ =~ m/^(\S+) (\S+) (\S+) \[(.+)\] "(\S+ \S+ \S+)" (\S+) (\S+) "(.+)" "(.+)" (\S+) (\S+) (\S+)/g;

### Debug output ###
	print "host: $host\n";
	print "remote: $remote_logname\n";
	print "time: $timestamp\n";
	print "request: $request\n";
	print "status: $statusCode\n";
	print "size: $size_of_request\n";
	print "refer: $refer\n";
	print "Agent: $user_agent\n";
	print "Time Served: $timeServed\n";
	print "PID: $pid\n";
	print "Hostname: $hostname\n";
	print "\n";
###

use Term::ANSIColor qw(:constants);
if( $timeServed < 1000000 ) {
	print "All is well!\n";
	print "Time Served (Microseconds): ";
	print BOLD, GREEN, $timeServed . "\n", RESET;
	print "Time Served (Seconds): ";
	print BOLD, GREEN, ($timeServed / 1000000), RESET;
	print "\n";
} else {
	print "Oh no!!!\n";
	print "Time Served (Microseconds): ";
	print BOLD, RED, $timeServed . "\n", RESET;
	print "Time Served (Seconds): ";
	print BOLD, RED, ($timeServed / 1000000), RESET;
	print "\n";
}
print "\n";
}
