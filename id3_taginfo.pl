#!/usr/local/bin/perl

use Getopt::Long;

use MP3::Tag;
use File::Copy;
use File::Find;

my $debug = 0;

#
#  - recursively search a directory tree.  
# 
#  - foreach element in the directory tree extract the ID3 tag and
#    populate a HoHs with the contents of the ID3 tag.  
# 
#  - if the file contains a malformed ID3 tag determine the contents of
#    the file based on the directory location info.
#    
#  - the correct directory format for this should be as follows ....
# 
#  + artist  - directory
#  |
#  |-+ album - directory 
#    |
#    +- <track number> - <song title>
#    +- <track number> - <song title>
#    +- <track number> - <song title>
#  
#  e.g.: 
#  
#  + rage against the machine
#  |
#  |-+ the battle of los angeles
#    |
#    +- 01 - testify.mp3
#    +- 02 - guerilla radio.mp3
#    +- 03 - calm as a bomb.mp3
#    +- 04 - mic check.mp3
#    +- 05 - sleep now in the fire.mp3
#    +- 06 - broken man.mp3
#    +- 07 - born as ghosts.mp3
#    +- 08 - maria.mp3
#    +- 09 - voice of the voiceless.mp3
#    +- 10 - hungry people.mp3
#    +- 11 - ashes in fall.mp3
#    +- 12 - war within a breath.mp3
# 

my %opts = ();

# process command line option(s)
# -print - print only take no action
# -input_dir  - <input_directory>
# -output_dir - <output_directory>
#
GetOptions('input_dir=s'  => \$opts{input_dir},
	   'output_dir=s' => \$opts{output_dir},
	   'print'        => \$opts{print},
	  );

if (
    (!defined($opts{input_dir} ) ) ||
    (!defined($opts{output_dir}) )
   ) {
  &printUsage();
  exit(1);
}

find(\&processMP3, $opts{input_dir});


sub processMP3 {
  print "$File::Find::dir\n" if $debug > 1;

  if (! -d $_ ) {
    # print "track filename: $_\n";

    # sanity check to make sure that we're dealing with an MP3 file here
    next if $_ !~ /.*mp3$/;


    my $mp3  = MP3::Tag->new("$_");
    my @tags = $mp3->get_tags();

    if (exists $mp3->{ID3v2}) {
      my $id3v2     = $mp3->{ID3v2};
      my $frame_ids = $id3v2->get_frame_ids;

      if (defined($opts{print})) {
	print  "-" x 30 . "\n";
	print "   song: " .$id3v2->song    . "\n";
	print " artist: " .$id3v2->artist  . "\n";
	print "  album: " .$id3v2->album   . "\n";
	print "  track: " .$id3v2->track   . "\n";
	
	print  "-" x 30 . "\n";
      
	foreach my $frame (keys %$frame_ids) {
	  my ($frame_val, $frame_key) =  $id3v2->get_frame($frame);
	  
	  if ((ref $frame_val) && (defined($opts{print}))) {
	    # iterate through the contents of the frame
	    while ( my ($sub_key, $sub_val) = each %$frame_key ) {
	      print " --> $sub_key : $sub_val\n"; 
	    } 
	  } else { print "$frame_key : $frame_val\n"; }
	}
      } # end of verbose output

      #assemble the output directory (to enable us to test for it)
      my $output_dir  = "$opts{output_dir}/" . $id3v2->artist . '/';
         $output_dir .= $id3v2->album; 

      $output_dir =~ s/ /\\ /g;
	
      # handle any padding of the track
      my $track = $id3v2->track;
      if (length($track) == 1 ) {
	$track = "0" . $track;
      }
      
      # assemble output
      my $output_file = $output_dir  . "/" . $track . ' - ' . 
                        $id3v2->song . ".mp3";


      print "$File::Find::name\n";
      print "$output_file\n";

      if (-d $output_dir) {
	File::Copy::copy($File::Find::name, $output_file);
      } else {

	print "directory: $output_dir doesn't exist\n";
	print "output directory: $output_dir\n";
	mkdir($output_dir) || die "error: $!\n";
	File::Copy::copy($File::Find::name, $output_file);
      }

    } elsif (exists $mp3->{ID3v1}) {
      print "version 1 tag\n";

      my $id3v2 = $mp3->{ID3v1};

      print "   song: " .$id3v1->song    . "\n";
      print " artist: " .$id3v1->artist  . "\n";
      print "  album: " .$id3v1->album   . "\n";
      print "comment: " .$id3v1->comment . "\n";
      print "   year: " .$id3v1->year    . "\n";
      print "  genre: " .$id3v1->genre   . "\n";
      print "  track: " .$id3v1->track   . "\n";

    } else { # malformed id3 tag
      print "malformed id3v2 tag\n";
      print " directory: $File::Find::dir\n";
      print "track file: $_\n";
    }
  } # end of file operations
}

# since we have the relevant song information available to us via the
# ID3 information. it does make some sense to try and correlate that
# against the information which we can discern from the path.  


sub printUsage() {
  print <<EOF;
 usage: 

 --print         - print only take no action
 --input_dir=%s  - <input_directory>
 --output_dir=%s - <output_directory>


EOF
}
