package TP_server;

use strict;
use Socket;

######################################################
sub new{
  my $self = {};
  bless $self, 'TP_server';
  return $self;

}

######################################################
## log motion events... this has to somehow tell the
##  player that there is an event to pay attention to...
sub motion_server{
  my $self      = shift;
  my $accept_ip = shift;
  my @dot_quad  = split /\./, $accept_ip;

  my $server_host = 'localhost';
  my $server_port = 3000 + $dot_quad[3];

  ## create a socket 
  socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
  
  ## this allows us to restart the server quickly..
  setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
  
  ## build up my socket address
  my $my_addr = sockaddr_in($server_port, INADDR_ANY);
  
  bind(SERVER, $my_addr) or die "can't bind to $server_port\n";
  
  listen(SERVER, SOMAXCONN) or die "can't listen to $server_port\n";

  my $buf;
  while (accept(CLIENT, SERVER)){
    while ($buf = <CLIENT>){
      print $buf;
    }
  }
  
  close(SERVER);
}


######################################################
sub card_server{

  my $self      = shift;
  my $accept_ip = shift;
  my @dot_quad  = split /\./, $accept_ip;

  my $server_host = 'localhost';
  my $server_port = 4000 + $dot_quad[3];

  ## create a socket 
  socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
  
  ## this allows us to restart the server quickly..
  setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
  
  ## build up my socket address
  my $my_addr = sockaddr_in($server_port, INADDR_ANY);
  
  bind(SERVER, $my_addr) or die "can't bind to $server_port\n";
  
  listen(SERVER, SOMAXCONN) or die "can't listen to $server_port\n";

  my $buf;
  while (accept(CLIENT, SERVER)){
    while ($buf = <CLIENT>){
      print $buf;
    }
  }
  
  close(SERVER);
}


######################################################
sub screen_status_server{

  my $self      = shift;
  my $accept_ip = shift;
  my @dot_quad  = split /\./, $accept_ip;

  my $server_host = 'localhost';
  my $server_port = 5000 + $dot_quad[3];

  ## create a socket 
  socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
  
  ## this allows us to restart the server quickly..
  setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
  
  ## build up my socket address
  my $my_addr = sockaddr_in($server_port, INADDR_ANY);
  
  bind(SERVER, $my_addr) or die "can't bind to $server_port\n";
  
  listen(SERVER, SOMAXCONN) or die "can't listen to $server_port\n";

  my $buf;
  while (accept(CLIENT, SERVER)){
    while ($buf = <CLIENT>){
      print $buf;
    }
  }
  
  close(SERVER);
}


1;
