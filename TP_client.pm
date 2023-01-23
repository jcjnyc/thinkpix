package TP_client;

use strict;
use Socket;

######################################################
sub new{
  my $self = {};
  bless $self, 'TP_client';
  return $self;

}

######################################################
## expects the self reference, the clip_id, and 
## the host ip address to be passed in.
######################################################
sub play_clip{
  
  my $self        = shift; ## the class of the method
  my $clip_id     = shift; ## the name of the clip
  my $remote_host = shift; ## in dotted quad format

  ## all play connections are to this port
  my $remote_port = '4444';

  ## create a socket connection "TO_SERVER"
  socket(TO_SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
  
  ## build the address of the remote machine
  my $internet_addr = inet_aton($remote_host) 
    or die "can't convert $remote_host to address\n";
  
  ## buid the full port and host address
  my $paddr = sockaddr_in($remote_port, $internet_addr) 
    or die "port address problem \n";;
  
  connect(TO_SERVER, $paddr) 
    or die "can't connect to $remote_host:$remote_port $!\n";
  
  ## write to the socket ....
  print TO_SERVER "play $clip_id:\n";
  print "$remote_host play $clip_id:\n";
  close(TO_SERVER);
  
  return $!;
  
}

1;
