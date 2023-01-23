#!/usr/bin/perl

##################################################################
## player_control.pl:
##
## this script controls the assorted client/screen palyers
##  - at boot time, it must start and perform the following tasks.
##  1) check for existing control files
##  2) read and parse each of the control files present
##  3) open sockets that listen for a "start" signal from the clients
##  4) upon reception of the start signal, 
##      initiate the sending of play commands 
##

######## BASIC TEST OF PARSING, CALLING, AND WAITING #############
########   ALSO A SOLID TEST OF THE PARSER #######################

## modules #######################################################
use strict;       ## keep it clean, namespace i mean
use lib '.';      ## where to look library files (.pm)
use POSIX;        ## posix compliance
use Symbol; 
use TP_client;    ## calls to the player client on the node
use TP_ParseCtl;  ## read and parse the control files 


########## Instantiate the parser and client objects ##############
my $playlist = new TP_ParseCtl;
my $call_player = new TP_client;

########## This will be a config file someday #####################
my $bin_dir        = `pwd`; # present working directory
my $screen_dir     = 'Screens';  # directory with screen control files
my $mpeg_dir       = 'Clips';    # where the mpegs are held
my $pipe_dir       = 'Pipes';    # where fifo pipes are
my $shared_part    = 'Share';    # shared partition's root
my $log_dir        = 'Logs';     # directory where logs are held
chomp($bin_dir);
my $par_log_file   = $log_dir . "/player_control.log";

$| = 1;                          # auto flush buffers


########## SIGNAL HANDLERS #########################################
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = \&HUNTSMAN;


############# returns list of control files w/o ".ctl" suffix #######
my $ctl_files  = $playlist->list_ctl_files($screen_dir);

my %pids = ();
my $num_children = 0;


foreach(@$ctl_files){

  ## count the children
  ++$num_children;

  ## this will hold the process id keyd by the node ip
  ## it passes the args ip address, and directory where the screen control files are
  $pids{$_} = create_caller($_, $screen_dir);

  &logger($par_log_file, "starting child pid ==> $pids{$_} : ip ==> $_");

  sleep(1);              ## just to give the OS a second to catch up

}

&logger($par_log_file, "Total children: $num_children");


### the parent sleeps here...

while(1){
  ## sleep simply waits for a signal that will come upon a child's death
  sleep;   

  ## this will log the death of the child 
  &logger($par_log_file, "$$ recieved signal:: a child proc died\n");
  
  ## so here is how we find the child that died and the associated ip address
  ## 1 - since we have a hash keyed by ip address with the child process
  ## 2 - test each of the 
  foreach(sort keys %pids){
    &logger($par_log_file, "-- checking for child proc $pids{$_} to $_");
    unless(kill 0 => $pids{$_}){
      &logger($par_log_file, "child $pids{$_} for ip $_ died :-(");
      $pids{$_} = create_caller($_, $screen_dir);
      &logger($par_log_file, "starting child pid ==> $pids{$_} : ip ==> $_");
    }
      
  }

}

exit(0);



sub create_caller{
  my $client_ip  = shift;
  my $screen_dir = shift;
  my $log_file   = "Logs/$client_ip" . ".log";
  my $pipe       = "Pipes/$client_ip" . ".pipe";
  my $pid;
  my $sigset;
  my $data;

  $sigset = POSIX::SigSet->new(SIGINT);

  sigprocmask(SIG_BLOCK, $sigset) 
    or die "can't block SIG_INT for $$ $!\n";

  ## fork off the process here
  die "fork: can't fork $!\n" unless defined ($pid = fork);


  if($pid){
    ## parent records the childs birth and returns pid
    sigprocmask(SIG_UNBLOCK, $sigset) or 
      die "can't unblock SIGINT for child $pid\n";
    return $pid;


  }else{
    ##################################################################
    ###   CHILD is NOT allowed to return from this subroutine ########
    ##################################################################

    
    ############# parse the correct control file #####################
    my ($header, $body) = 
      $playlist->parse_playlist("$screen_dir/$client_ip.ctl");


    ## Reset the interupt signal so the child won't trap kills
    $SIG{INT} = 'DEFAULT';  

    sigprocmask(SIG_UNBLOCK, $sigset) or 
      die "can't unblock SIGINT for child $pid\n";

    #### start message to log file ###################################
    &logger($log_file, "$$ opening pipe $pipe for reading");

    ## start reading from the pipe, looking for the signal to play the next file.
    open(FIFO_IN, "$pipe") or die "can't open pipe file $pipe\n";

    
    ## variable for accepting input from the pipe file 
    my $in;

    ## time that an interuptible clip will be done
    my (@time_now, $time_string); ## hold the time strings
    my $time_complete;            ## final completion time
    my $time_stamp;               ## time in seconds since epoch

    ## sentinel to determine if the clip is 
    my $interupt = 0;         

    ## just wait for the new line, then act 
    ####################################################################
    while (defined ($in = <FIFO_IN>)){


      ## TIMMING IS EVERYTHING:
      ##
      ## - this will generate the hash key that will identify the clip
      ##   that will be sent to the player on the other end
      ##   (sec, min, hr, day month, month, year, day week, day year,)
      @time_now    = localtime(time);
      
      ## format the time in [hh:mm] there should always be 2 digits for each
      ##  so we append a zero for sub 10 instances
      $time_now[2] = "0" . $time_now[2] unless $time_now[2] >= 10;
      $time_now[1] = "0" . $time_now[1] unless $time_now[1] >= 10;
      $time_string = "$time_now[2]:$time_now[1]";

      ## the time that it is now in seconds
      $time_stamp = localtime(time);

      ## now decide what to play, when to play it....
      
      ## if just a new line is the signal, 
      if( ($in eq "\n") && ($$body{$time_string} =~ /\.p\.mpg/) ){ 
	## this is a timed poster
	$interupt = 1;

	## tell the client/node a play the poster that is associated with this time
	$call_player->play_clip($$body{$time_string}, $client_ip);

	## this is the time in seconds untill the clip will be done
	$time_complete = time();

	&logger($log_file, "$$: timed playing of poster $$body{$time_string}");


      }elsif( ($in eq "\n") && 
	      ($$body{$time_string} =~ /\.m\.mpg/) ){
 
	## this is a timed clip and can't be interupted
	$interupt = 0;
	
	## tell the client/node a play the clip that is associated with this time
	$call_player->play_clip($$body{$time_string}, $client_ip);

	## this is the time in seconds untill the clip will be done
	$time_complete = time() + $$header{ $$body{$time_string} }[0];

	&logger($log_file, "$$: timed playing of $$body{$time_string}");
	&logger($log_file, "$$: -- will be complete at $time_complete");
	
      }elsif( ($in eq "motion\n") && 
	      ($interupt == 1) ){
	
	## this is a motion event, it can't be interupted
	$interupt = 0;
	
	## play a clip that is associated with the presently playing clip
	##  for a motion event 
	$call_player->play_clip($$header{$$body{$time_string}}[1], $client_ip);

	## this is the time in seconds untill the clip will be done
	$time_complete = time() + $$header{ $$body{$time_string} }[0];

	&logger($log_file, "$$: motion event *** ");
	&logger($log_file, "$$: -- $$header{$$body{$time_string}}[1]");
	&logger($log_file, "$$: -- will be complete at $time_complete");

	
      }elsif( ($in eq "card\n") && ($time_complete < $time_stamp ) ){
	
	## this is a card event, it can't be interupted
	$interupt = 0;

	## play a clip that is associated with the presently playing clip
	##  for a motion event 
	$call_player->play_clip($$header{$$body{$time_string}}[1], $client_ip);
	
	## this is the time in seconds untill the clip will be done
	$time_complete = time() + $$header{ $$body{$time_string} }[0];

      }else{
	&logger($log_file, "$$ ignoring play request [$interupt] --> $in");

      }

      
    }

    close(FIFO_IN);
    
    &logger($log_file, "-- LAST TIME: $time_string");
    
    exit;
  }

}


sub REAPER{
  $SIG{CHLD} = \&REAPER;
  my $pid = wait;
  my $children;
  $children--;
  my %children;
  delete $children{$pid};

}

## this should kill all the children
sub HUTSMAN {
  local($SIG{CHLD}) = 'IGNORE';
  my %children;
  kill 'INT' => keys %children;
  exit;
}


sub logger($$){
  my $log_file = shift;
  my $message  = shift;
  my $stamp    = localtime(time);

  ########## OPEN A LOG FILE #########################################
  open(LOG, ">> $log_file") or die "can't open $log_file: $!\n";
  print LOG "$stamp :: $message\n";
  close(LOG);
}

