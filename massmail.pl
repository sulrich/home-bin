#!/opt/local/bin/perl

my $mail_list     = $ARGV[0];
my $mesg_template = $ARGV[1];

# Locations for important files
my $sendmail = "/usr/sbin/sendmail -t";
my @users = ();

# Get the list of users
open(LIST, "$mail_list") || die "Error Opening: $mail_list";
while(<LIST>) { push @users, $_; }  
close(LIST);

# get the template that contains the mail message
my $mesg = &getTemplate($mesg_template);

foreach my $user (@users) {
    
    # $user =~ s/\s//g;
    chop($user);

    my %uinfo = ();
    $uinfo{dest_email} = $user;
    
    my $email_message  = &filterVars($mesg, %uinfo);
    &sendMesg($email_message);    
    print "message sent to: $uinfo{dest_email}\n";

} 



#---------------------------------------------------------------------
# misc. subs


# filterVars(buffer, hash)
sub filterVars {
  my ($filterstream, %searchvars)   = @_;
  
  $filterstream =~ s/\<\%([a-zA-Z0-9_]+)\%\>/
    my $value = $searchvars{$1};
  if (!defined $value) {
    $value = "\<\% $1 - undefined \%\>"; # leave it as is
  }
  $value;
  /ge;
  return $filterstream;
}


# getTemplate(path)
sub getTemplate {
    my ($template_path) = @_;

    my $template = "";

    open(TEMPLATE_T, "$template_path") || die "error opening: $template_path";
    while (<TEMPLATE_T>) { 
        $template .= $_; 
    }
    close(TEMPLATE_T);

    return $template;
}


sub sendMesg() {

    my ($message) = @_;

    open(SENDMAIL, "|$sendmail") || die "cannot open $sendmail: $!"; 
    print SENDMAIL $message;
    close(SENDMAIL); 
}
