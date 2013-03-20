#!/usr/bin/perl

while( <> ) {
	chomp($_);
	$rule = $_;
	if( $rule =~ m/sudo/ ) {
#		print "$rule\n";
		($who, $command) = $rule =~ m/sudo: (\S+) \:.* (COMMAND\=.+)/;
		print "SUDO: $who $command\n";
	} elsif ( $rule =~ m/sshd/ ) {
		if ( $rule =~ m/Accepted/ && $rule !~ m/cacti/ ) {
			($who, $from) = $rule =~ m/sshd.+ for (\S+) from (\S+)/;
			print "SSH: $who from $from\n";
		}
	}
}