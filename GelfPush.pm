package GelfPush;

use strict;
use warnings;
use Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket::INET;
use File::Tail;

$VERSION		= 0.0.1;
@ISA			= qw(Exporter);
@EXPORT			= ();
@EXPORT_OK		= qw(sendToGraylog);
%EXPORT_TAGS	= ( DEFAULT => [qw(&sendToGraylog &watcher_secure)]);

sub sendToGraylog {
	### ARGS: level, facility, file, short, long, hostname
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
		PeerHost => $_[5],
		PeerPort => '12201',
		Proto => 'udp',
	) or die "Error in socket creation : $!\n";

	print "UDP Connection sucessful!!!\n";

	print "Sending Message...\n";
	$socket->send($gzipped_message);
	$socket->close();
	print "Message Sent!\n";
}

sub watcher_secure {
	### ARGS: Hostname
	
	my $hostname = $_[0];
	
	### Production def
	# my $file = File::Tail->new(name => '/var/log/secure', interval=>1, maxinterval=>1);
	my $file = File::Tail->new(name => 'logs/scratch_secure.log', interval=>1, maxinterval=>1);
	while( defined( my $line = $file->read ) ) {
		chomp($line);
		my $rule = $line;
#		print "Rule: $rule\n";
		if( $rule =~ m/sudo/ ) {
#			print "$rule\n";
			(my $who, my $command) = $rule =~ m/sudo: (\S+) \:.* (COMMAND\=.+)/;
			print "SUDO: $who $command\n";
			my $short = "SUDO: $who $command";
			(my $full) = $rule =~ m/(sudo: .*)/;
#			print "Full: $full\n";
			sendToGraylog( 4, 'Secure Log', '/var/log/secure', $short, $full, $hostname );
				# level, facility, file, short, long, hostname
		} elsif ( $rule =~ m/sshd/ ) {
			if ( $rule =~ m/Accepted/ && $rule !~ m/cacti/ ) {
				(my $who, my $from) = $rule =~ m/sshd.+ for (\S+) from (\S+)/;
				print "SSH: $who from $from\n";
				my $short =  "SSH: $who from $from";
				(my $tmpFull) = $rule =~ m/sshd\[\d+\]\: (.*)/;
				my $full = "SSH: " . $tmpFull;
#				print "SSHFULL $full\n";
				sendToGraylog( 4, 'Secure Log', '/var/log/secure', $short, $full, $hostname );
			}
		}
	}
}

1;