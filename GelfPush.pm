package GelfPush;

use strict;
use warnings;
use Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket::INET;
use File::Tail;
use threads;

$VERSION		= 0.0.1;
@ISA			= qw(Exporter);
@EXPORT			= ();
@EXPORT_OK		= qw(sendToGraylog);
%EXPORT_TAGS	= ( DEFAULT => [qw(&sendToGraylog &watcher_secure)]);

sub sendToGraylog {
	### ARGS: level, facility, file, short, long, hostname, debug
	my $datetime = `date +%s`;
	chomp($datetime);
	my $hostname = `hostname`;
	chomp($hostname);
	my $debug = $_[6];

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

	if($debug) { print "\n$json_doc\n\n"; }

	my $gzipped_message;
	gzip \$json_doc => \$gzipped_message or die "gzip failed! $GzipError\n\n";

	my $socket = new IO::Socket::INET (
		PeerHost => $_[5],
		PeerPort => '12201',
		Proto => 'udp',
	) or die "Error in socket creation : $!\n";

	if( $debug ) {
		print "UDP Connection sucessful!!!\n";
		print "Sending Message...\n";
	}
	$socket->send($gzipped_message);
	$socket->close();
	if($debug) { print "Message Sent!\n"; }
}

sub watcher_apache_access {
	### ARGS: Hostname, Debug
	#
	# Assumed Log Format:
	# "%h - %{X-Forwarded-For}i - %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""
	
	my ($file);
	my $hostname = $_[0];
	my $debug = $_[1];
	
	$SIG{'KILL'} = sub { threads->exit(); };
	
	if( $debug ) {
		$file = File::Tail->new(name => 'logs/access.log', interval=>1, maxinterval=>1) or die("$!\n");
	} else {
		$file = File::Tail->new(name => '/var/log/httpd/access_log', interval=>1, maxinterval=>1) or die("$!\n");
	}
	
	while( defined( my $line = $file->read ) ) {
		chomp($line);
		(my $request, my $statusCode) = $line =~ m/\S+ - \S+ - \S+ \S+ \[.*\] \"(.*)\" (\d+) \S+ \".*\" \".*\"/;
		print "Request: $request\n";
		print "Status Code: $statusCode\n";
		(my $short) = $request =~ m/(^.{1,30})/;
		if( $statusCode =~ m/401|403|500|502|503/ ) {
			print "Error!!! $statusCode returned!\n";
			print "Short: $short\n";
			sendToGraylog( 3, 'Apache Access', '/var/log/httpd/access_log', $short, $line, $hostname, $debug );
		} else {
			print "Ok!  $statusCode returned!\n";
			print "Short: $short\n";
			sendToGraylog( 6, 'Apache Access', '/var/log/httpd/access_log', $short, $line, $hostname, $debug );
		}
	}
}

sub watcher_secure {
	### ARGS: Hostname, debug
	my ($file);
	my $hostname = $_[0];
	my $debug = $_[1];
	
	$SIG{'KILL'} = sub { threads->exit(); };
	
	if($debug) {
		$file = File::Tail->new(name => 'logs/secure.log', interval=>1, maxinterval=>1) or die("$!\n");
	} else {
		$file = File::Tail->new(name => '/var/log/secure', interval=>1, maxinterval=>1) or die("$!\n");
	}
	
	while( defined( my $line = $file->read ) ) {
		chomp($line);
		my $rule = $line;
			if( $rule =~ m/sudo/ ) {
				(my $who, my $command) = $rule =~ m/sudo: (\S+) \:.* (COMMAND\=.+)/;
			print "SUDO: $who $command\n";
			my $short = "SUDO: $who $command";
			(my $full) = $rule =~ m/(sudo: .*)/;
			sendToGraylog( 4, 'Secure Log', '/var/log/secure', $short, $full, $hostname, $debug );
		} elsif ( $rule =~ m/sshd/ && $rule !~ m/authentication failure/) {
			if ( $rule =~ m/Accepted/ && $rule !~ m/cacti/ ) {
				(my $who, my $from) = $rule =~ m/sshd.+ for (\S+) from (\S+)/;
					my $short =  "SSH: $who from $from";
				(my $tmpFull) = $rule =~ m/sshd\[\d+\]\: (.*)/;
				my $full = "SSH: " . $tmpFull;
				sendToGraylog( 4, 'Secure Log', '/var/log/secure', $short, $full, $hostname, $debug );
			}
		} elsif ( $rule =~ m/pam_sss\(sshd\:auth\)\: authentication failure/ ) {
			(my $from, my $who) = $rule =~ m/rhost\=(\S+) user\=(\S+)/;
				my $short = "SSH FAILURE: $who from $from";
			(my $tmpFull) = $rule =~ m/sshd\[\d+\]\: (.*)/;
			my $full = "SSH: " . $tmpFull;
			sendToGraylog( 2, 'Secure Log', '/var/log/secure', $short, $full, $hostname, $debug );
		}
	}
}

1;