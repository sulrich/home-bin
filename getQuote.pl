#!/usr/local/bin/perl

# connect to the url @ yahoo and pull the information down from the
# website in a comma delimited file.  we'll store this file someplace and
# then we'll use a cgi program to display it.  seems fair. ;-)

use LWP::UserAgent;
require "/home/http/cgi-bin/www.botwerks.org/settings.pl";
require "/home/http/cgi-bin/www.botwerks.org/libs/misc.pl";


$debug = 0;

$ua = new LWP::UserAgent;
$ua->agent("botwerks-quote/1.0 " . $ua->agent);

my $output = ""; 
if ($ARGV[0] ne "") { 
  $output = $ARGV[0]; 
} else {
  $output = $settings{QUOTE_FILE};
}

# my $ticker_list  = "covd,npntq,dsln,rthm,";
# web consulting firms
my $ticker_list .= "";
# server hardware folks
   $ticker_list .= "sunw,sgi,ibm,";
# carriers and tier 1 isps
   $ticker_list .= "genu,fon,q,t,wcom,";
# network hardware vendors
   $ticker_list .= "csco,jnpr,ntap,fdry,extr,nt,lu,";
# hardware comp. vendors
   $ticker_list .= "lsi,xlnx,inov";

# quote url
my $quote_url = 
  "http://finance.yahoo.com/d/quotes.csv?s=$ticker_list&f=sl1d1t1c1ohgv&e=.csv";

print $quote_url if $debug > 0;

my $req = new HTTP::Request(GET => $quote_url);
my $res = $ua->request($req);

if ($res->is_success) {
  &storeQuotes($res->content);
  exit(0);
} else {
  print "error getting quotes\n";
  exit(1);
}


sub storeQuotes {
  my ($quote_buffer) = @_;

  open(QUOTE_OUT, ">$output") || die "error: opening $output";
  print QUOTE_OUT $quote_buffer;
  close(QUOTE_OUT);
  return();
}
