#!/usr/bin/env perl

# place the individual files from my mail archives into a directory
# hierarchy of the form appropriate
#
# pooka [sulrich/tmp-mailfoo]% ./archive-maildir.pl \
#  --arch_dir=/Users/sulrich/tmp-archive-foo/cisco  \
#  --src_dir=/Users/sulrich/tmp-mailfoo volunteer
#  --keep_recent
# archive_dir/$mbox_dir-YYYY-MM/cur/message_file
#
#
# if the skip_current_month flag is set, we should leave messages which
# originated in this or the previous month in the current src directory.

# the archive directory is specified on the command line.
#

use Getopt::Long;
use Date::Manip;
use File::Path;

my %opts = ();
my %dir_hash = ();

GetOptions('arch_dir=s'  => \$opts{arch_dir},
           'src_dir=s'   => \$opts{src_dir},
           'keep_recent' => \$opts{keep_recent}
          );

$debug = 1;


$current_date   = &ParseDate("today");
$current_month  = UnixDate($current_date, "%Y-%m");
$previous_date  = &DateCalc("today", "- 1 month");
$previous_month = UnixDate($previous_date, "%Y-%m");


foreach $mbox (@ARGV) {
	&processMboxDir($mbox);
}

sub processMboxDir {
  my ($mbox_dir) = @_;

  foreach $leaf ("cur", "new", "tmp") {
    my $subdir = "$mbox_dir/$leaf";
    opendir(MAILBOX, "$opts{src_dir}/$subdir");
    @mesgs = readdir(MAILBOX);
    foreach $mesg (@mesgs) {
      my $mesg_date = &getMessageDate("$opts{src_dir}/$subdir/$mesg");
      my $mesg_arch = UnixDate($mesg_date, "%Y-%m");


      # handle the case of malformed date info
      next if ($mesg_arch !~ /\d{4}\-\d{2}/);
      next if (($mesg_arch eq $current_month) && ( $opts{keep_recent} == 1 ));
      next if (($mesg_arch eq $previous_month) && ( $opts{keep_recent} == 1 ));

      my $mesg_path = "$opts{arch_dir}/$mbox_dir-$mesg_arch";
      if (! exists($dir_hash{$mesg_path}) ) {
	if (! -d "$mesg_path/cur/") {
	  print "need dir: $mesg_path\n";
	  mkpath("$mesg_path/cur", 0, 0700);
	  mkpath("$mesg_path/new", 0, 0700);
	  mkpath("$mesg_path/tmp", 0, 0700);
	  $dir_hash{$mesg_path} = 1;
	}
      }
      my $src_path = "$opts{src_dir}/$subdir/$mesg";
      my $dst_path = "$mesg_path/$leaf/$mesg";

      if ($debug == 1) {
	print " src: $src_path\n";
	print "dest: $dst_path\n";
      }
      rename($src_path, $dst_path);
    }
    closedir(MAILBOX);
  }
}

sub getMessageDate() {
  my ($message) = @_;
  open (MESSAGE, "<$message") || die "error opening $message";
  my $raw_date = "";
  while (<MESSAGE>) {
    next if $_ !~ /^Date:/;
    ($raw_date) = /^Date: (.*)$/;
    last;
  }
  close(MESSAGE);
  my $date = &ParseDate($raw_date);
  return $date;
}
