#!/usr/bin/perl


# whois wrapper - steve ulrich <sulrich@botwerks.org>
#
# this will handle domains, packed ip addresses which are popular with
# spammers , normal ip addresses and as #'s.  handy for dealing with
# routing crap.
#

# being lazy isn't all bad ...

use Socket; # to make inet_aton() work
use Getopt::Std;

my $domain       = $ARGV[0];
my $whois_server = "";


getopt('h');


if ($opt_h) {
  print <<EOF;
negating wrapper...
using whois server @ $opt_h
EOF

  my $whois_output = `whois -h $opt_h $ARGV[$#ARGV]`;
  print STDOUT $whois_output;
  exit(0);
  
exit(0);
}

if ($domain eq "") { &printUsage(); }

if ( ($domain =~ /^(\d+)$/) && (length($domain) > 5) ) {
  # more cleanup is necessary - this is a munged IP
  $whois_server = "whois.arin.net";
  
  my ($name, $aliases, $addrtype, $length, @addrs) = 
    gethostbyaddr(inet_aton($domain), AF_INET);
  
  my $address = join ('.', unpack('C4', $addrs[0]));
  print "unpacked address: $address\n";
  
  my $whois_output = `whois -h $whois_server $address`;
  print STDOUT $whois_output;
  exit(0);
  
} elsif ( ($domain =~ /^(\d+)$/) && (length($domain) <= 5) ) {
  # looks like an AS Number

    # standard ARIN lookup
    $whois_server = "whois.arin.net";
    
    print "network: $domain\n";
    my $whois_output = `whois -h $whois_server $domain`;
    print STDOUT $whois_output;
    exit(0);
    
} elsif ($domain =~ /^([\d|\.]+)$/ )  { # grab IP address style
    # standard ARIN lookup
    $whois_server = "whois.arin.net";
    
    print "network: $domain\n";
    my $whois_output = `whois -h $whois_server $domain`;
    print STDOUT $whois_output;
    exit(0);
    
} else {
    # appears to be a domain and not an address

    open(REG_LOOKUP, "whois $domain|") || die "error: running whois";
    while(<REG_LOOKUP>) {
	if (/whois server:\s+(\S+)/i) { $whois_server = $1; }		
    }
    close(REG_LOOKUP);
    
    my $whois_output = `whois -h $whois_server $domain`;
    print STDOUT $whois_output;
    exit(0);
}



sub printUsage() {
    print <<EOF;

rec_whois.pl - recursive whois client - (wrappered around stock whois)

Usage: rec_whois.pl [-h whois server] domain [address]

Will resolve the registrar and the determine appropriate whois server to
query as well as perform the whois query against the appropriate whois
server.

-h <whois_server> 

   - will allow you to by pass the wrapper functions and query a specific
   whois server directly. The prevents your having to unalias the
   rec_whois.pl wrapper to query a specific whois server.

EOF

    exit(0);

}
