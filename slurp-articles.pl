#!/usr/local/bin/perl

use Net::NNTP;
use Getopt::Long;

my %opts  = ();

GetOptions(
           'server=s'    => \$opts{server}, 
           'group=s'     => \$opts{group}, 
           'startart=s'  => \$opts{startart}, 
           'dumpfile=s'  => \$opts{dumpfile},
          );

if (! defined($opts{server}) )    { &printUsage(); exit(); }
if (! defined($opts{group}) )    { &printUsage(); exit(); }

# specify STDOUT shorthand '-' here if you just want to dump the articles
# to STDOUT otherwise specify a filename to catch the crap.
if (! defined($opts{dumpfile}) ) { &printUsage(); exit(); }

my $nntp = Net::NNTP->new($opts{server}, Reader);
my ($num_arts, $first_art, $last_art, $groupname) = $nntp->group($opts{group});


open(DUMPFILE, ">>$opts{dumpfile}") || 
  die "error opening file: $opts{dumpfile}";

if (defined($opts{startart})) {
  print DUMPFILE "article start: ---------------------------------------------\n";
  print DUMPFILE $nntp->article($opts{startart});
  
  # this will dump the first article and set the group article pointer to
  # the appropriate value so you can hop into the loop happily.

}

while ($nntp->next()) {
  my $article = $nntp->article();

  # modify this code to suite your needs for chunking out to whatever your
  # outbound process is. - note that you will need to change the loop to
  # handle stopping before the last article in the group.

  print DUMPFILE "article start: ---------------------------------------------\n";
  print DUMPFILE @$article;
}

$nntp->quit;
close(DUMPFILE);

sub printUsage() {
print <<EOF;

something should really go here but i'm to lazy to write instructions this
late and i've got a really early flight ...
EOF


}
