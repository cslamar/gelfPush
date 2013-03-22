#!/usr/bin/perl

use feature qw( switch );
use warnings;
use GelfPush;
use Config::INI::Reader;
use Data::Dumper;
use threads;

my (@inis_enabled, $graylog2_sever);

### Read the config file in and set variables ###
my $config = Config::INI::Reader->read_file('gelfPush.conf');

### Production:
# my $config = Config::INI::Reader->read_file('/etc/gelfPush.conf');

foreach my $block (keys %$config) {
	print "Keys: $block\n";
	if( $block ne 'GLOBAL' && $config->{$block}->{'enabled'} == 1) {
		push( @inis_enabled, $block );
	}
}

print "Inis enabled:\n";
print Dumper( @inis_enabled );
$graylog2_server = $config->{'GLOBAL'}->{'graylog2_sever'};
print "Server: $graylog2_server\n";

for my $action (@inis_enabled) {
	print "Action: $action\n";
	my $thr = threads->create( \&spawn_watcher, $graylog2_server, $action )->detach();
}

while(1) { }

sub spawn_watcher {
	### ARGS: Hostname, watcher
	my $hostname = $_[0];
	my $watcher = $_[1];
	
	print "Graylog2 Server: $hostname\n";
	given($watcher) {
		when("APACHE_LOGGING") {
			print "Apache log watching enabled...\n";
			GelfPush::watcher_apache_access($hostname);
		}
		when("SECURE_LOG") {
			print "Secure log watching enabled...\n";
			GelfPush::watcher_secure($hostname);
		}
	}
}