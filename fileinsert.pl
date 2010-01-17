#!/usr/bin/perl

################################################################################
# fileinsert.prl
# 
# A quick hack to insert a file where ever a specified string occurs
#
################################################################################


foreach $FileInput (@ARGV) {
    
    $FileOutput = "output/" . $FileInput;
    $RepFile = "/home/sulrich/meta.txt";
    $SearchString = "<HEAD>";
    
    open(FILE_IN, "$FileInput") || die "Cannot open Input File ($FileInput)";
    open(FILE_OUT, ">>$FileOutput") || die "Cannot open File ($FileOutput)";

    while (<FILE_IN>) {		
	if (/$SearchString/) {
            print FILE_OUT "$_\n";
            open (REPFILE, "$RepFile") || die "Cannot open Rep File ($RepFile)";
	    print FILE_OUT (<REPFILE>);
	    close (REPFILE);
	}		       
	else {
	    print FILE_OUT "$_";
	}
    }			       
    close(FILE_OUT);
    close(FILE_IN);
}
