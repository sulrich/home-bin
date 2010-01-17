#!/usr/local/bin/perl

my $template_dir = "$ENV{HOME}/bin/templates";

my $template = $ARGV[0] . ".txt"; # pass the 
my %resp_val = ();

my $header_chk = "X";

open(STDIN, "<-") || die "error receving from stdin";
while (<STDIN>) {
  # basic header checking code
  if ( ($header_chk eq "X") && ($_ =~ /^$/) ) { $header_chk = ""; }

  # slurp the from header
  if ( (/^From\:\s+(.*)$/i) &&  ($header_chk eq "X") ) {
    $resp_val{'return_addr'} = $1; 
  }
} 
close(STDIN);

my $response_body = &getTemplate("$template_dir/$template");
   $response_body = &filterVars($response_body, %resp_val);

&sendMesg( $response_body );
exit(0);



#---------------------------------------------------------------------
# sendMesg(MessageBuffer)
#
#
sub sendMesg {
  my ($message) = @_;
  
  open(MAIL, "|/usr/lib/sendmail -t") || die "error: opening sendmail";
  print MAIL $message, "\n";
  close(MAIL);
 
}1;


#-----------------------------------------------------------
# getTemplate(Template)
#
sub getTemplate {
    my ($templatefile) = @_;

    my $template     = "";

    open(TEMPLATE, $templatefile) || die ("Error Opening $templatefile");
    while(<TEMPLATE>) { $template .= $_; }
    close(TEMPLATE);

    return $template;
}


#-----------------------------------------------------------
# filterVars(Buffer, HashwRepVars)
#
#
sub filterVars {
    my ($FilterStream, %SearchVars)   = @_;
    
    $FilterStream =~ s/\<\% ([a-zA-Z0-9_]+) \%\>/
	my $Value = $SearchVars{$1};
    if(!defined $Value) {
	#$Value = "\<\% $1 \%\>"; # leave it as is
	print STDERR "\<\% $Value \%\>\n";
    }
    $Value;
    /ge;
    return $FilterStream;
}
