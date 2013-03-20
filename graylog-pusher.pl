#!/usr/bin/perl

use warnings;
use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket::INET;
use File::Tail;
use Term::ANSIColor qw(:constants);
use Config::Simple;

my $counter = 0;
my ($level, %Config);

### Read the config file in and set variables ###
Config::Simple->import_from('gelfPush.conf', \%Config);
# Config::Simple->import_from('/etc/gelfPush.conf', \%Config);

my $logfile = $Config{"APACHE_LOGGING.logfile"};
my $facility = $Config{"APACHE_LOGGING.facility"};

### Debugging lines ###
print $Config{"APACHE_LOGGING.graylog2_server"} . "\n";
print $Config{"APACHE_LOGGING.facility"} . "\n";
print $Config{"APACHE_LOGGING.logfile"} . "\n";


sub sendToGraylog {
	# level, facility, file, short, long
	my $datetime = `date +%s`;
	chomp($datetime);
	my $hostname = `hostname`;
	chomp($hostname);

	my $gelf_format = { 
	        "version" => "1.0",
	        "host" => "$hostname",
	        "short_message" => "$_[3]",
	        "full_message" => "$_[4]",
   	     	"timestamp" => "$datetime",
   	     	"level"=> "$_[0]",
        	"facility"=> "$_[1]",
        	"file"=> "$_[2]",
    };

	my $json_doc = encode_json($gelf_format);

	print "\n$json_doc\n\n";

	my $gzipped_message;
	gzip \$json_doc => \$gzipped_message or die "gzip failed! $GzipError\n\n";

	my $socket = new IO::Socket::INET (
		PeerHost => $Config{"APACHE_LOGGING.graylog2_server"},
		PeerPort => '12201',
		Proto => 'udp',
	) or die "Error in socket creation : $!\n";

	print "UDP Connection sucessful!!!\n";

	print "Sending Message...\n";
	$socket->send($gzipped_message);
	$socket->close();
}

my $file = File::Tail->new(name => $logfile, interval=>1, maxinterval=>1);
while( defined( my $line = $file->read ) ) {
	chomp($line);
	($short) = $line =~ m/(.{1,40})/;
	print "$counter: Short: $short\n";
	print "$counter: Long: $line\n";
	print "$counter: Facility: Testing\n";
	($host, $remote_logname, $remote_user, $timestamp, $request, $statusCode, $size_of_request, $refer, $user_agent, $timeServed, $pid, $hostname) = $line =~ m/^(\S+) (\S+) (\S+) \[(.+)\] "(\S+ \S+ \S+)" (\S+) (\S+) "(.+)" "(.+)" (\S+) (\S+) (\S+)/g;
	if( $timeServed < 1000000 ) {
		print BOLD, GREEN, "$counter: Time Served: $timeServed\n", RESET;
		$level = 6;
	} else {
		print BOLD, RED, "$counter: Time Served: $timeServed\n", RESET;
		$level = 3;
	}
	print "$counter: Level: $level\n";
	
	### Format: level, facility, file, short, long
	sendToGraylog( $level, $facility, $logfile, $short, $line );
	$counter++;
}
