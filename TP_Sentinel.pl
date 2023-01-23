#!/usr/bin/perl

## sentinel.pl 
## - this script is run as a cron job, it will handle several tasks
##
## - twice a day it will check for new files in the 'Screens' directory
##    if there are new .ctl files it will parse them, and look in the 
##    'Clips' directory for the movies associated with the particular server
##    and will create a copy of the control file and the clip in the correct
##    client directory.
##
## - once an hour it will check 'ping' each client to see that it is alive.
##
## - more .....????

use strict;
use lib '.';
use TP_ParseCtl;


### PREDEFINED VARS #############################################################
my $parser = new TP_ParseCtl; ## instatiate a copy of the parser object 
my $screens_dir = 'Screens';  ## where the screen ctl files are held 
my $clips_dir   = 'Clips';    ## where all of the mpeg (et al) clips are held
my $share_dir   = 'Share';    ## the shared partition, one for each of the clients



if($ARGV[0] eq 'update'){
  
  #################################
  ## list of screens in this cinema
  ##  in the Screens directory
  my @screen_list = ();
  
  #################################
  ## list of clips that are resident
  ##  in the Clips directory
  my @clip_list = ();
  
  ################################################
  ## these will hold the header and body elements 
  ##  from the parsed control file
  my ($header, $body);
  
  
  ################################################
  ## Get the list of all screens control files
  @screen_list = `ls -1 Screens/*.ctl`;
  
  ## foreach screen, read in the control file
  foreach(@screen_list){
    chomp;

    ($header, $body) = $parser->parse_playlist("$_");

    ## whittle down the directory to get just the IP of the client.
    my $screen_ip = $_;
    $screen_ip =~ s%^Screen/%%;
    $screen_ip =~ s%\.ctl$%%;
    
    #########################################################
    ## now just copy the clip (as defined in the header hash)
    ##  to the correct client directory.
    ## create the client directory if it doesn't exist.
    foreach(sort keys %$header){
      
    }


  }

  exit 0;
}


