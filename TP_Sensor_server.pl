#!/usr/bin/perl

###########################################################################
# TP_Sensor_server.pl by Eric Rosenfield
# - amended by james jackson <jcj@slack.net>
#
###########################################################################
#
# This program monitors all instances of the motion sensor being activated, on
# each of the node computers as listed in the Screens directory.
# When it gets a motion sensor instance, it passes that information on to
# To TP_Player_control through the pipes (in the Pipes folder), which then
# decides whether to play or not play a movie.
#
## jcj - notes
# - bascially i employed some of the methods i built for standard routines
#   that will make the code easier to manage.
#
#######################################################################

use lib '.';
use strict;
use Socket;
use POSIX;
use Symbol;
use TP_ParseCtl;

########## Instantiate the parser object ##############################
my $playlist = new TP_ParseCtl;


########## This will be a config file someday #####################
my $bin_dir        = `pwd`; # present working directory
my $screen_dir     = 'Screens';  # directory with screen control files
my $pipe_dir       = 'Pipes';    # where fifo pipes are
my $log_dir        = 'Logs';     # directory where logs are held
my $par_log_file   = $log_dir . "/sensor_server.log";
chomp($bin_dir);

my %pids;
my $log_file;


$| = 1;                          # auto flush buffers

########## SIGNAL HANDLERS #########################################
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = \&HUNTSMAN;

############# returns list of control files w/o ".ctl" suffix #######
my $ctl_files  = $playlist->list_ctl_files($screen_dir);

## open a socket for listiening for each ip address
foreach my $ip (@$ctl_files) {
  $pids{$ip} =  &makesocket($ip);
}


while(1){
  sleep;

  ## this will log the death of the child 
  &logger($par_log_file, "$$ recieved signal:: a child proc died");
  
  ## so here is how we find the child that died and the associated ip address
  ## 1 - since we have a hash keyed by ip address with the child process
  ## 2 - test each of the 
  foreach(sort keys %pids){
      &logger($par_log_file, "-- checking for child proc $pids{$_} to $_");
      
      unless(kill 0 => $pids{$_}){
	  &logger($par_log_file, "child $pids{$_} for ip $_ died :-(");
	  $pids{$_} = &makesocket($_);
	  &logger($par_log_file, "starting child pid ==> $pids{$_} : ip ==> $_");
      }
      
  }
}

exit(0);



sub makesocket {

  my $ip_add = shift;
  
  my ($quad1, $quad2, $quad3, $quad4) = split(/\./,$ip_add);
  my $server_port = "50" . $quad4;
  
  ## build the log file name
  $log_file = $log_dir . "/" . $ip_add . "-" . $server_port . "_sensor.log";
  &logger($log_file, "listening for connect from $ip_add on port $server_port");


  my $sigset = POSIX::SigSet->new(SIGINT);
  
  sigprocmask(SIG_BLOCK, $sigset)
    or die "can't block SIG_INT for $$ $!\n";
  my $pid;

  die "fork: can't fork $!\n" unless defined ($pid = fork);
  
  
  if ($pid){

    ## parent records the childs birth and returns pid
    sigprocmask(SIG_UNBLOCK, $sigset) or
      die "can't unblock SIGINT for child $pid\n";
    return $pid;
    
  } else {
    
    ## Reset the interupt signal so the child won't trap kills
    $SIG{INT} = 'DEFAULT';
    
    sigprocmask(SIG_UNBLOCK, $sigset) or
      die "can't unblock SIGINT for child $pid\n";
    
    ## create a socket 
    ##  ARGS( FILE_HANDLE, socket type, communications type, protoclo )
    socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
    
    ## this allows us to restart the server quickly..
    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
    
    ## build up my socket address
    my $my_addr = sockaddr_in($server_port, INADDR_ANY);
    
    bind(SERVER, $my_addr) or print "can't bind to $server_port\n";
    
    listen(SERVER, SOMAXCONN) or print "can't listen to $server_port\n";
    
    $| = 1;
    open(HOLD, "> Pipes/$ip_add.pipe") or die $!;
    
    my $buf;

    ### args to accept are: 
    ###         (TO HANDLE, FROM HANDLE)
    while (accept(CLIENT, SERVER)){
      while ($buf = <CLIENT>){
	chomp($buf);
	$buf =~ s/\r//g;
	$buf =~ s/\n//g;
	$buf = int($buf);
        &logger($log_file, "$ip_add:$server_port - distance --> $buf");
	
	## write a signal to the pipe if 
	##   the distance is less than or equal to 4000
	##   also, check for a lock file before writting to the pipe
	#############################################################
	if ($buf != 0 && !-e "Pipes/$ip_add.lock") { 
	  open(FIFO, "> Pipes/$ip_add.pipe") or die "$!";
	  print FIFO "motion\n" if $buf <= 4000;
          &logger($log_file, "--> $buf <--");
	  close(FIFO);
	  undef $buf;
	  sleep(2);   ## give the other side a few seconds to react 
	}
	
	
      }
    }
    
    close(SERVER);
    close(HOLD);
  }
  exit;
}

## if a child dies this should start a new one???
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

## 
sub logger($$){
  my $log_file = shift;
  my $message  = shift;
  my $stamp    = localtime(time);

  ########## OPEN A LOG FILE #########################################
  open(LOG, ">> $log_file") or die "can't open $log_file: $!\n";
  print LOG "$stamp :: $message\n";
  close(LOG);
}






