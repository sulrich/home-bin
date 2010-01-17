#!/opt/local/bin/perl

use strict;
use warnings;

use Mac::Growl;
use IO::Socket::INET;
use Fcntl qw/SEEK_SET/;
use Mail::Header;
use Mail::Address;

BEGIN { # try to load Lingua::EN::Summarize, but don't depend on it
	eval {
		require Lingua::EN::Summarize;
	};

	my $subs = sub { substr($_[0], 0, 23) };
	if ($@){
		*summarize = $subs;
	} else {
		*summarize = sub { &$subs(Lingua::EN::Summarize::summarize($_[0], maxlength => 23) || $_[0]) };
	}
}

my $application  = "BiffGrowl";
my $notification = "Watching Mailboxes";
my $Notes = ["Watching Mailboxes"];

my $boxroot = "/Users/sulrich/mail";

## Configure here

my $port = shift || "comsat"; # the port to use

my $sticky = 1; # should the growl bezel stick?

## Init
Mac::Growl::RegisterNotifications($application,[$notification],[$notification]);


my $comsat = IO::Socket::INET->new(
  LocalHost => '127.0.0.1',
  LocalPort => $port,
  Proto => 'udp',
) || die "can't create socket: $!";

Mac::Growl::PostNotification($application, $notification,
		"Init suceeded","Watching out for mails now",0);


while($comsat->recv(my $msg, 65535, 0)){
  my ($logname, $offset, $file) = ($msg =~ /^(.*?)\@(.*?):(.*?)$/) or next;

  my $mboxname = $file;
  $mboxname =~ s:$boxroot/::;

  open my $mbox, "<", $file or die "couldn't open $file: $!";
  seek $mbox, $offset, SEEK_SET;

  my $header = Mail::Header->new($mbox, MailFrom => "IGNORE");
  my $who = (Mail::Address->parse($header->get("From")))[0]->name || $header->get("From");
  my $what = $header->get("Subject") || '<no subject>';
  chomp $what;
  if (length($what) > 24) {
    $what = summarize($what) . "\x{2026}"; # \N{HORIZONTAL ELLIPSIS}
  }

  close $mbox;

  Mac::Growl::PostNotification(
    $application,
    $notification,
    $what,
    "From: $who\nFile: $mboxname",
    $sticky,
  );
}

