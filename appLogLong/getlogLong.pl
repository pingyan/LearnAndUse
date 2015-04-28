#!/usr/bin/perl -w
#have an individual script per log type

use strict;
use Data::Dumper;
$Data::Dumper::Indent=1;
use Net::SSL;
use LWP::UserAgent;  # Module for https calls
use XML::Simple;     # convrt xml to hash
use URI::Escape;     # sanitize searches to web friendly characters

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my $twdate=$ARGV[1];
my $twmonth=$ARGV[0];

my $SEARCH;
#	$SEARCH ='search earliest=-15m@m ( index=ap* OR index=eu* OR index=na* ) (logRecordType="scchl") | table instance,userId,username,organizationId,ip,transport,country,stage,timestamp';
$SEARCH = "search earliest=$twmonth/$twdate/2015:00:00:00 latest=$twmonth/$twdate/2015:23:59:59 index=na6 userId=005800000037y6T (logRecordType=R OR logRecordType=L OR logRecordType=A OR logRecordType=v OR logRecordType=U OR logRecordType=V OR logRecordType=aprst)";

print $SEARCH;

my $userId = '005800000037y6T';

my $base_url = 'https://splunk-api.crz.salesforce.com:8214';
my $username = 'pyan';
my $password = 'FENGmobile2172200359';
my $app      = 'search';

my $XML = new XML::Simple;
my $ua = LWP::UserAgent -> new (ssl_opts => {verify_hostname => 0},);
my $post;         # Return object for web call
my $results;      # raw results from Splunk
my $xml;          # pointer to xml hash

# Request a session Key 
$post = $ua->post(
	"$base_url/servicesNS/admin/$app/auth/login",
	Content => "username=$username&password=$password"
);

$results = $post->content;
#print $results;
$xml = $XML->XMLin($results);

# Extract a session key
my $ssid = "Splunk ".$xml->{sessionKey};
print "Session_Key(Authorization): $ssid\n";

# Add session key to header for all future calls
$ua->default_header( 'Authorization' => $ssid);

# Perform a search
$post = $ua->post(
"$base_url/servicesNS/$username/$app/search/jobs", 
	Content => "search=".uri_escape($SEARCH)
);
$results = $post->content;
$xml = $XML->XMLin($results);

# Check for valid search
unless (defined($xml->{sid})) {
	print "Unable to run command\n$results\n";
	exit;
}

my $sid = $xml->{sid};
print  "SID(Search ID)            : $sid\n";

my $done;
do {
	sleep(2);
	$post = $ua->get(
	"$base_url/services/search/jobs/$sid/"
);

$results = $post->content;
if ( $results =~ /name="isDone">([^<]*)</ ) {
	$done = $1;
} else {
	$done = '-';
}

print "Progress Status:$done: Running\n";
} until ($done eq "1");  

# Get Search Results
$post = $ua->get(
	"$base_url/services/search/jobs/$sid/results?output_mode=csv&count=0"
);

$results = $post->content;

my $input_folder = '/Users/pyan/ping/experiments/appLogLong/data';

my $fo; 
open ($fo, ">>", "$input_folder/applogLong-$userId-$twmonth-$twdate.txt") or die "Couldn't open: $!";
print $fo $results;

#close $fo;
