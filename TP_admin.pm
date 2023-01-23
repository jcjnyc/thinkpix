package TP_admin;

###################################################################
#
# TP_admin - an object package for the admin program.
#
###################################################################

use strict;
use Socket;

######################################################
sub new{
  my $self = {};
  bless $self, 'TP_admin';
  return $self;

}

######################################################
## expects the self reference, the clip_id, and 
## the host ip address to be passed in.
######################################################
sub send_command{
  
  my $self        = shift; ## the class of the method
  my $clip_id     = shift; ## the name of the clip
  my $remote_host = shift; ## in dotted quad format
  my $remote_port = shift;

 #print $clip_id;
  #print $remote_host;
  #print $remote_port;
#exit;

  ## all play connections are to this port
  #my $remote_port = '3333';

  ## create a socket connection "TO_SERVER"
  socket(TO_SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
  
  ## build the address of the remote machine
  my $internet_addr = inet_aton($remote_host) 
    or return "can't convert $remote_host to address\n";
  
  ## buid the full port and host address
  my $paddr = sockaddr_in($remote_port, $internet_addr) 
    or return "port address problem \n";;
  
  connect(TO_SERVER, $paddr) 
    or return "can't connect to $remote_host:$remote_port $!\n";
  
  ## write to the socket ....
  print TO_SERVER "$clip_id:\n";
  #print "$remote_host $clip_id:\n";
  close(TO_SERVER);
  
  return $!;
  
}
    
1;




