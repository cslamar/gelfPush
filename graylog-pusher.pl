#!/usr/bin/perl

use warnings;
use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket::INET;

my $datetime = `date +%s`;
chomp($datetime);

my $gelf_format = { 
        "version" => "1.0",
        "host" => "somehost.lcgosc.com",
        "short_message" => "some short message",
        "full_message" => "Really long message",
        "timestamp" => "$datetime",
        "level"=> "3",
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
$socket->send($gzipped_message);
$socket->close();