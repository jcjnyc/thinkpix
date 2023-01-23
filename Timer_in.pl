#!/usr/bin/perl 

use strict;
use lib '.';
use FileHandle;
use TP_ParseCtl;

########## Instantiate the parser object ##########################
my $playlist = new TP_ParseCtl;


########## This will be a config file someday #####################
my $bin_dir        = `pwd`; # present working directory
my $screen_dir     = 'Screens';  # directory with screen control files
my $mpeg_dir       = 'Clips';    # where the mpegs are held
my $pipe_dir       = 'Pipes';    # where fifo pipes are
my $shared_part    = 'Share';    # shared partition's root
my $log_dir        = 'Log';      # directory where logs are held
chomp($bin_dir);                 #
$| = 1;                          # unbuffered output


## get the start time  #############################################
## we want the hour minute, array elements are in the order
## sec, min, hour, day_month, month, ... other stuff ...  
my @start_time = localtime(time);

############# list the control file w/o ".ctl" #####################
my $ctl_files = $playlist->list_ctl_files($screen_dir);

my $in = shift;

############# list the control file w/o ".ctl" #####################
my $pipe_files = $playlist->list_pipe_files($pipe_dir);
if ($in) {
    undef @$pipe_files;
    $$pipe_files[0] = $in;
}

my @hold_handle;
my %write_handle;
my $i = 0;

foreach(@$pipe_files){

  if ( (-W "$pipe_dir/$_.pipe") && (defined $_) ){
    ### this essentialy holds the the pipe open so that there is never
    ### an EOF sent.
    $hold_handle[$i]  = new FileHandle "> $pipe_dir/$_.pipe\n";
    
    ## this will be opened and closed, the key is the path to the named pipe
    $write_handle{"$pipe_dir/$_.pipe"} = "1";
    
    print "$pipe_dir/$_.pipe\n";
    ++$i;
  }else{
    print STDERR "$pipe_dir/$_.pipe not writeable\n";
  
  }
}


while (1){
  my $in = "\n";
  
  foreach(sort keys %write_handle){

    print "$_\n";
    ## create a lock file so that the sensor won't write to the pipe
    my $lock = $_;
    $lock =~ s/pipe/lock/;
    print "locking $lock\n";
    open (LOCK, "> $lock") || die "can't create lock file $lock\n"; 
    print LOCK localtime(time) . "$_\n";
    close(LOCK);

    ## this will be opened and closed, the key is the path to the named pipe
    $write_handle{$_} = new FileHandle "> $_";
    $write_handle{$_}->print("$in") if defined $write_handle{$_};
    undef $write_handle{$_};
    
    ## remove the lock file, we are done...
    `rm $lock`;
    
  }
  sleep 60;
}

foreach(@hold_handle){
  undef $_;
}

