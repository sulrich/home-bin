#!/usr/bin/env perl -w 
# mutt_ldap_query.pl version 3.0
# Written by Marc de Courville <marc@courville.org>
# The latest version of the code can be retrieved at 
#  ftp://ftp.mutt.org/pub/mutt/contrib
# This code is distributed under the GNU General Public License (GPL). See
# http://www.opensource.org/gpl-license.html and http://www.opensource.org/.

# mutt_ldap_query performs ldap queries using either ldapsearch command
# or the perl-ldap module and it outputs the required formatted data for
# feeding mutt when using its "External Address Query" feature.
# This perl script can be interfaced with mutt by defining in your .muttrc:
#   set query_command = "mutt_ldap_query.pl '%s'"
# Multiple requests are supported: the "Q" command of mutt accepts as argument
# a list of queries (e.g. "Gosse de\ Courville").

# References:
# - ldapsearch is a ldap server query tool present in ldap-3.3 distribution 
#   http://www.umich.edu/~rsug/ldap)
# - perl-ldap module 
#   http://www.perl.com/CPAN-local/authors/id/GBARR
# - mutt is the ultimate email client
#   http://www.mutt.org
# - historical Brandon Blong's "External Address Query" feature patch for mutt
#   http://www.fiction.net/blong/programs/mutt/#query

# Version History (major changes only)
# 3.0 (12/29/1999): 
#  implemented another query method using perl-ldap module enabled by 
#  the -p boolean flag
# 2.3 (12/28/1999): 
#  added better parsing of the options, a shortcut for avoiding
#  -s and -b options by using the script builtin table of common
#  servers and associated search bases performing a <server_nickname>
#  lookup (changes inspired from a patch sent by Adrian Likins
#  <alikins@redhat.com>), performed some Y2K cleanups ;-)
# 2.2 (11/02/1999): 
#  merged perl style fixes proposed by Warren Jones <wjones@tc.fluke.com>
# 2.1 (4/14/1998):
#  first public release

use Net::LDAP;

use strict;
use constant DEBUG     => 0;
use constant ONLY_PERL => 1;

use Getopt::Std;
use vars qw($opt_p $opt_h $opt_s $opt_b $opt_n $opt_q);
getopts('hpn:s:b:q:');


#- CONFIG AREA -------------------------------------------------------
#
#
my $ldap_server = "ldap.cisco.com";
my $search_base = "ou=active,ou=employees,ou=people,o=cisco.com";
my @fields = qw(cn mail sn fn uid);

my $ldap_server_nick = "cisco";
# list of the fields that will be used for composing the answer
my $expected_answers = "cn fn sn mail";
#---------------------------------------------------------------------
my @results;

# database of the common server with default search starting points
# the format is: 'server nickname','full address of the server', 'search base'
my %server_db = (
 local	=> ['localhost', 'ou=active,ou=employees,ou=people,o=cisco.com'],
 cisco	=> ['ldap.cisco.com', 'ou=active,ou=employees,ou=people,o=cisco.com']
);


# print usage error
#die usage if (! $ARGV[0] || $opt_h);

# define default $ldap_server
$ldap_server = $opt_s if $opt_s;
$search_base = $opt_b if $opt_b;
if ($opt_n) 
{
  $ldap_server_nick = $opt_n;
  my $option_array = $server_db{$ldap_server_nick};

  if (! $option_array) {
  die print <<EOF
$0 unknown server nickname:
      
  no server associated to the nickname $ldap_server_nick, please 
  modify the internal database according your needs by editing the 
  script $0 

EOF

  }

  $ldap_server = $option_array->[0];
  $search_base = $option_array->[1];
}

print "DEBUG: ldap_server=$ldap_server search_base=$search_base\n" if (DEBUG);

$/ = '';	# paragraph mode for input.


# enable this if you want to include wildcard in your search with some huge 
# ldap databases you might want to avoid it
#  my $query = join '', map { "($_=$askfor*)" } @fields;


my $query = "(&(" . $opt_q . "))";
print "DEBUG: query is: $query\n" if (DEBUG);

my $ldap = Net::LDAP->new($ldap_server) || die $@;
$ldap->bind;

my $mesg = $ldap->search( base => $search_base, filter => $query ) || 
    die $@;

print $query;
$mesg->code && die $mesg->error;

my @entries = $mesg->entries;

map { $_->dump } $mesg->all_entries if (DEBUG);

my $entry;
foreach $entry (@entries)  { 
    print "DEBUG processing $entry->dn\n" if (DEBUG);
    
    my $email  = $entry->get_value('mail');
    my $cn     = $entry->get_value('cn');
    my $fn     = $entry->get_value('fn');
    my $sn     = $entry->get_value('sn');
    
    $cn =~ tr/A-Z/a-z/;
    # this one works mostly for everyody
    push @results, "<$email>\t$cn\t\n";
}
$ldap->unbind;

print "LDAP query: found ", scalar(@results), "\n", @results;
exit 1 if ! @results;



sub usage
{
<<EOF;
mutt_ldap_query performs ldap queries using either ldapsearch command
or the perl-ldap module and it outputs the required formatted data for
feeding mutt when using its "External Address Query" feature.

This perl script can be interfaced with mutt by defining in your .muttrc:
  set query_command = "mutt_ldap_query.pl '%s'"
Multiple requests are supported: the "Q" command of mutt accepts as argument
a list of queries (e.g. "Gosse de\ Courville").

usage: $0 -s <server_name> -n <server_nickname> <name_to_query> 

-n shortcut for avoiding -s and -b options by using the script builtin
   table of common servers and associated search bases performing a 
   <server_nickname> lookup

examples of queries:
  classical query:
    mutt_ldap_query.pl -s ldap.crm.mot.com -b 'o=Motorola,c=US' Gosse
  and its shortcut version using a nickname
    mutt_ldap_query.pl -n crm Gosse de\ Courville
EOF
}


