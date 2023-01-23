package TP_ParseCtl;

use strict;

## this package handles different parsing and listing 
##     methods.
######################################################

## OO me baby ########################################
sub new{
  my $self = {};
  bless $self, 'TP_ParseCtl';
  return $self;

}

#######################################################
## parse_playlist:
## - accepts a directory name as the argument.
## - returnts references to hashes that contain the 
##    parsed control file.
#######################################################

sub parse_playlist{
  my $self = shift;
  my $ctl_file = shift;

  ## arrays that will hold sections of the file
  my (@header, @body);

  ## these will hold the returned hashes
  my %header = ();
  my %body   = ();

  ## where are we in the control file
  my $marker = 0;

  ## just counters 
  my ($x, $y, $z) = 0;

  ######################################################
  ## check that the file exists, and start parsing..
  ######################################################
  if(-e $ctl_file){
    open(FILE, $ctl_file); ## add error logging here....
    while(<FILE>){
      chomp;

      #################################################
      ## try and skip all extraneous data
      ## check if the line is a comment or blank or if 
      ## declare new section just increment the marker
      #################################################
      if($_ =~ /^#|^$|^\n$/){
	 next;

       }elsif($_ =~ /<head>/i){
	 $marker = 0;
       }elsif($_ =~ /<body>/i){
	 $marker = 1;
       }elsif($marker == 0){
	 chomp;
	 $header[$x++] = $_; 
       }elsif($marker == 1){
	 chomp;
	 $body[$y++] = $_; 
       }else{
	 next;
       }
    }
    close(FILE);
  }

  ## Parse the header into a hash of arrays:
  ## - each hash element is keyd by name of the file
  ## - each value is the reference to an array that is
  ##    (in order) 
  ##    [length of clip], [motion clip], [card clip]
  ####################################################


  my ($name, $len, $motion, $card);

  foreach(@header){
    ($name, $len, $motion, $card) = split /-/, $_;
    $name    =~ s/\s//g;
    $len     =~ s/\s//g;
    $motion  =~ s/\s//g;

    my @tmp = ($len, $motion, $card);

    $header{$name} = \@tmp; 
  }

  ## Parse the body into a simple one-dimensional hash
  ## key is the time to play
  ## value is the name of the clip to play
  #####################################################

  foreach(@body){
    my $time;
    my $clip_name;
    ($time, $clip_name) = split / - /, $_;
    $body{$time} = $clip_name;
  }


  return (\%header, \%body);

}


#########################################################
## methods for listing directory files of a certain type 
#########################################################


## lists control files "*.ctl" ##########################
sub list_ctl_files($){
  my $self       = shift;
  my $screen_dir = shift;
  my $tmp = "";

  ## list all of the control files in the dir
  my @ctl_files  = `ls -1 $screen_dir/*.ctl`;
  
  foreach(@ctl_files){
    chomp;  
    ($tmp, $_) = split /\//, $_;
    s/\.ctl$//;
  }
  
  return \@ctl_files;
}




## lists pipe files "*.pipe" ##########################
sub list_pipe_files($){
  my $self       = shift;
  my $pipe_dir   = shift;
  my $tmp;
  my $file;

  ## list all of the control files in the dir
  my @pipe_files  = `ls -1 $pipe_dir/*.pipe`;
  
  foreach(@pipe_files){
    chomp;  
    ($tmp, $_) = split /\//, $_;
    $_ =~ s/\.pipe$//;
  }
  
  return \@pipe_files;
}




## lists MPEG files "*.mpg" ##########################
sub list_mpeg_files($){
  my $self       = shift;
  my $mpeg_dir   = shift;
  my $tmp;

  ## list all of the control files in the dir
  my @mpeg_files  = `ls -1 $mpeg_dir/*.mpg`;
  
  foreach(@mpeg_files){
    chomp;  
    ($tmp, $_) = split /\//, $_;
    s/\.mpeg$//;
  }
  
  return \@mpeg_files;
}

		 
1;
