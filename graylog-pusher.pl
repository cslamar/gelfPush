#!/usr/bin/perl

use warnings;
use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket::INET;
use File::Tail;

my $counter = 0;
my $logfile = 'test.log';

sub sendToGraylog {
	# level, facility, file, short, long
	my $datetime = `date +%s`;
	chomp($datetime);
	my $hostname = `hostname`;
	chomp($hostname);

	my $gelf_format = { 
	        "version" => "1.0",
	        "host" => "$hostname",
	        "short_message" => "some short message",
	        "full_message" => "Really long message",
   	     	"timestamp" => "$datetime",
   	     	"level"=> "6",
        	"facility"=> "Test",
        	"file"=> "/path/to/file",
    };

	my $json_doc = encode_json($gelf_format);

	print "\n$json_doc\n\n";

	my $gzipped_message;
	gzip \$json_doc => \$gzipped_message or die "gzip failed! $GzipError\n\n";

	my $socket = new IO::Socket::INET (
		PeerHost => 'logging.lcgosc.com',
		PeerPort => '12201',
		Proto => 'udp',
	) or die "Error in socket creation : $!\n";

	print "UDP Connection sucessful!!!\n";

	print "Sending Message...\n";
	#$socket->send($gzipped_message);
	$socket->close();
}

my $file = File::Tail->new(name => $logfile, interval=>1, maxinterval=>1);
while( defined( my $line = $file->read ) ) {
	chomp($line);
	($short) = $line =~ m/^.{1,20}/;
	print "$counter: Short: $short\n";
	print "$counter: Long: $line\n";
	print "$counter: Facility: Testing\n";
	($host, $remote_logname, $remote_user, $timestamp, $request, $statusCode, $size_of_request, $refer, $user_agent, $timeServed, $pid, $hostname) = $_ =~ m/^(\S+) (\S+) (\S+) \[(.+)\] "(\S+ \S+ \S+)" (\S+) (\S+) "(.+)" "(.+)" (\S+) (\S+) (\S+)/g;
	print "$counter: Time Served: $timeServed\n";
	
	$counter++;
}
