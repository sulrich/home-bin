#! /usr/bin/env perl
# put into the public domain by Bruce Guenter <bruceg@qcc.sk.ca>
# based heavily on code by Russell Nelson <nelson@qmail.org>, also in
# the public domain
# NO GUARANTEE AT ALL
#
# Creates a maildir from a mbox file

# Assumes that nothing is trying to modify the mailboxe
# version 0.00 - first release to the public.

require 'stat.pl';

sub error {
    print STDERR join("\n", @_), "\n";
    exit(1);
}

sub usage {
    print STDERR "usage: mbox2maildir <mbox file> <maildir> [ <uid> <gid> ]\n";
    exit(@_);
}

&usage(1) if $#ARGV != 1 && $#ARGV != 3;;

$mbox = $ARGV[0];
$mdir = $ARGV[1];
$uid = $ARGV[2];
$gid = $ARGV[3];

&error("can't open mbox '$mbox'") unless
    open(SPOOL, $mbox);

-d $mdir || mkdir $mdir,0700 ||
    &error("maildir '$mdir' doesn't exist and can't be created.");
chown ($uid,$gid,$mdir) if defined($uid) && defined($gid);
chdir($mdir) || &error("fatal: unable to chdir to $mdir.");
-d "tmp" || mkdir("tmp",0700) || &error("unable to make tmp/ subdir");
-d "new" || mkdir("new",0700) || &error("unable to make new/ subdir");
-d "cur" || mkdir("cur",0700) || &error("unable to make cur/ subdir");
chown ($uid,$gid,"tmp","new","cur") if defined($uid) && defined($gid);

$i = time;
while(<SPOOL>) {
    if (/^From /) {
        close(OUT);
        $fn = "cur/$i.$$.mbox";
        # $fn = sprintf("new/%d.$$.mbox", $i);
        open(OUT, ">$fn") || &error("unable to create new message");;
        chown ($uid,$gid,$fn) if defined($uid) && defined($gid);
        $i++;
        next;
    }
    s/^>From /From /;
    print OUT || &error("unable to write to new message");
}
close(SPOOL);
close(OUT);
