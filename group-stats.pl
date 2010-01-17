#!/usr/local/bin/perl

use Net::NNTP;
use Data::Dumper;

# there appear to be some issues with tracking uniq author count and the
# numbers of xposted groups for select groups.  this needs to be
# addressed.


my $nntp_server = "news.visi.com";

my $grp_stats   = 0;
my $debug       = 0;

my ($xpost_info, $group_info, $author_info, $subject_info) = {};

my $xpost_db   = "$ENV{HOME}/.misc-stats/xpost.db";
my $author_db  = "$ENV{HOME}/.misc-stats/author.db";
my $group_db   = "$ENV{HOME}/.misc-stats/group.db";
my $subject_db = "$ENV{HOME}/.misc-stats/subject.db";

my @newsrc_list = qw(
		      mn.arts mn.aviation mn.config 
		      mn.games mn.general mn.humor mn.jobs
		      mn.net mn.online-service mn.personals mn.politics 
		      mn.traffic
		      visi.announce visi.frontpage visi.general visi.gripes 
		      visi.help visi.quake 
		     );



&initDataStructs();

if ($debug >= 3) {
  print Dumper($group_info);
  print Dumper($author_info);
  print Dumper($xpost_info);
  print Dumper($subject_info);
}

my $server = Net::NNTP->new($nntp_server, reader) || 
   die "cannot connect to server: $nntp_server";

# where the action is jackson
foreach my $group (@newsrc_list) {
  &groupProc($group);
  &groupInfoProc();
}

$server->quit(); # disconnect from the nntp server
&closeDataStructs();


#---------------------------------------------------------------------
# groupInfoProc() - walk the various structs and dump their contents.  i'm
# thinking that we should add anchors and some other things in here like
# sorting but i'm feeling rather lazy @ the moment.
#
sub groupInfoProc() {
  my $head1_fmt = 
"\n\n" . 
"----------------------------------------------------------------------\n" . 
"   newsgroup: @<<<<<<<<<<<<<<<<<<<| total art(s): @<<<<<<<<<<\n" . 
" first art #: @<<<<<<<<<<<<<<<<<<<|   last art #: @<<<<<<<<<<\n" . 
"xpost grp(s): @<<<<<<<<<<<<<<<<<<<| uniq auth(s): @<<<<<<<<<<\n\n";

  my $line_fmt = 
"@>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> | @<<<<\n";
  

  foreach my $base_grp ( @newsrc_list ) {
    # dump basic group info
    print &swrite($head1_fmt, $base_grp, $group_info->{$base_grp}->{numart}, 
		  $group_info->{$base_grp}->{first_art}, 
		  $group_info->{$base_grp}->{last_art},
		  $group_info->{$base_grp}->{xpost_grp_ct},
		  $group_info->{$base_grp}->{uniq_auth_ct}
		 );

    # dump xposted group info
    print "group xposted to                  | # xposts\n";
    print '-' x 70 . "\n";
    foreach my $xpost_grp ( keys %{ $xpost_info->{$base_grp} } ) {
      print &swrite($line_fmt, 
		    $xpost_grp, $xpost_info->{$base_grp}->{$xpost_grp});

    }

    # dump author info
    print "\n\n";
    print "author                            | # posts\n";
    print '-' x 70 . "\n";
    foreach my $author ( keys %{ $author_info->{$base_grp} } ) {
      print &swrite($line_fmt, 
		    $author, $author_info->{$base_grp}->{$author});

    }

    # dump the subject info
    print "\n\n";
    print "subject                           | # posts\n";
    print '-' x 70 . "\n";
    foreach my $subject ( keys %{ $subject_info->{$base_grp} } ) {
      print &swrite($line_fmt, 
		    $subject, $subject_info->{$base_grp}->{$subject});

    }

  }
} # end groupInfoProc()


#--------------------------------------------------------------------- 
# groupProc() - collect the headers for articles within a group and
# assemble the appropriate stats on the article headers based on the
# analysis that is being performed.
#
sub groupProc() {
  my ($group) = @_;

  my $start_art = 0;

  my ($numart, $first_art, $last_art, $news_group) = $server->group($group);
  if ($debug >= 1) {
    print "$group\n";
    print "$numart, $first_art, $last_art, $news_group\n";
    print $group_info->{$group}->{'last_art'}, "\n";
  }

  if (! exists( $group_info->{$group}->{'last_art'})) {
    $start_art = $first_art;
    $last_art  = $last_art;
  } else {
    # we have hit this group before 
    if ( $last_art > $group_info->{$group}->{'last_art'} ) {
      $start_art = $group_info->{$group}->{last_art} + 1; 
    } elsif ( $last_art == $group_info->{$group}->{'last_art'} ) {
      $start_art = $group_info->{$group}->{last_art}; 
    } else { 
      $start_art = $first_art;
    }
  }

  $group_info->{$group} = {
			   numart    => $numart,
			   first_art => $first_art,
			   last_art  => $last_art
			  }; 
  if ($debug >= 1) {
    print "start: $start_art end: $last_art\n";
    print "$group: articles to process this run: ", $last_art - $start_art, "\n";  
  }
  
  foreach my $article ($start_art .. $last_art) {
    my $headers = &parseHeaders($server->head($article));

    &xpostProc($group, $headers);
    &authorProc($group, $headers);
    &subjectProc($group, $headers);

    if ($debug > 3) {
      print "    From: " . $headers->{"from"}       . "\n";
      print " subject: " . $headers->{"subject"}    . "\n";
      print "  msg_id: " . $headers->{"message-id"} . "\n";
      print "    refs: " . $headers->{"references"} . "\n";
      print "newsgrps: " . $headers->{"newsgroups"} . "\n";
    }
    
    &printHeaders($headers) if $debug >= 4;
  }
} # end groupProc();


#---------------------------------------------------------------------
# xpostProc(base_group, header_hashref) - process the information related
# to xposted articles
# 
sub xpostProc() {
  my ($base_grp, $headers) = @_;

  my @groups = split(',', $headers->{'newsgroups'});
  my $total_grps = $#groups + 1;
  my $xpost_grps = $total_grps - 1;


  if ($debug > 2) {
    print "xpostProc()\n";
    print '-' x 40 . "\n";
    print $headers->{'newsgroups'} . "\n";
    print "total_grps> $total_grps xposted_grps> $xpost_grps\n";
  }
  
  foreach my $grp (@groups) {
    next if $grp =~ /^$base_grp$/;
    # increment the counter for the %xpost_info HoH we'll walk this
    # structure later to determine who and where the prime offenders are
    if (! exists($xpost_info->{$base_grp}->{$grp}) ) {
      $group_info->{$base_grp}->{'xpost_grp_ct'}++;
      $xpost_info->{$base_grp}->{$grp}++; 
    } else {
      $xpost_info->{$base_grp}->{$grp}++; 
    }
  }
}


#---------------------------------------------------------------------
# subjectProc(base_group, $header_hashref) - process the information
# related to the subject. and update the associated global data struct.
#
sub subjectProc() {
  my ($base_grp, $headers) = @_;
  my $subject = $headers->{'subject'};

  if (! exists($subject_info->{$base_grp}->{$subject}) ) {
    $subject_info->{$base_grp}->{$subject}++;
    $group_info->{$base_grp}->{'uniq_subject_ct'}++;
  } else {
    $subject_info->{$base_grp}->{$subject}++;
  }
}


#---------------------------------------------------------------------
# authorProc(base_group, $header_hashref) - process the information
# related to the author of this article. update the global data struct.
#
sub authorProc() {
  my ($base_grp, $headers) = @_;

  my $author = $headers->{'from'};

  if (! exists($author_info->{$base_grp}->{$author}) ) {
    $author_info->{$base_grp}->{$author}++;
    $group_info->{$base_grp}->{'uniq_auth_ct'}++;
  } else {
    $author_info->{$base_grp}->{$author}++;
  }
}

#---------------------------------------------------------------------
# printHeaders($header_hashref) - dump the headers that are actualy in the
# header array that we have. this is pretty much useful for debugging
# large scale header oddness only and is should be accessible *only* via a
# very verbose debugging level
#
sub printHeaders() {
  my ($headers) = @_;
  foreach my $i (keys(%$headers)) {
    print "$i: $headers->{$i}\n";
  }
}

#---------------------------------------------------------------------
# parseHeaders(header_arrayref) - take an array of header lines and chunk
# it into a hash with the header as the key and the header contents as the
# value.  returns a hash ref.
#
sub parseHeaders() {
  my ($header_ref) = @_;

  my %header_hash = ();
  foreach my $i ( @$header_ref ) {
    $_ = $i;
    my ($header, $contents) = /^(\S+)\:\s+(.*)$/;
    $header =~ tr/A-Z/a-z/;
    $header_hash{$header} = $contents;
 }
  
  return \%header_hash;
}

#---------------------------------------------------------------------
# swrite() - this is a blatant hack to get around the oddness associated
# with write()'s and formats in perl.  this is handy but broke stuff. 
# i would recommend reading the camel book when reviewing this code. 
# formats are kinda mysterious.
#
sub swrite() {
  my $format = shift;
  $^A = "";
  formline $format, @_;
  return $^A;
} 

#---------------------------------------------------------------------

# dumpStructToFile() - 

sub dumpStructToFile() {
  my ($output_file, $data) = @_;

  open(OUTFILE, ">$output_file") || die "error opening: $output_file";
  print OUTFILE $data;
  close(OUTFILE);

}

#---------------------------------------------------------------------
# getStructFromFile() - load file from disk and return the serialized info
# for evaluation using dumper to recreate the data struct.
#
sub getStructFromFile() {
  my ($input_file) = @_;

  my $struct = "";
#  open(INFILE, "$input_file") || die "error opening: $input_file";
  open(INFILE, "$input_file") || return "";
  while(<INFILE>) { $struct .= $_; }
  close(INFILE);

  return($struct);
}



#---------------------------------------------------------------------
# initialize the structures that we have to minimize the amount of nntp
# server interation that we have to do in the future.  store the
# xpost_info hash as well as the group_info hash.  
#
sub initDataStructs() {
  my $xpost_file   = &getStructFromFile($xpost_db);
  my $author_file  = &getStructFromFile($author_db);
  my $group_file   = &getStructFromFile($group_db);
  my $subject_file = &getStructFromFile($subject_db);

  $author_info  = eval $author_file;
  $group_info   = eval $group_file;
  $xpost_info   = eval $xpost_file;
  $subject_info = eval $subject_file;

}

#---------------------------------------------------------------------
# closeDataStructs() - serialize the associated data structures and put
# them to disk.
#
sub closeDataStructs() {
  &dumpStructToFile($author_db, Dumper($author_info));
  &dumpStructToFile($xpost_db, 	Dumper($xpost_info));
  &dumpStructToFile($group_db, 	Dumper($group_info));
  &dumpStructToFile($subject_db,Dumper($subject_info));
}

