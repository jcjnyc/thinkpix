#!/usr/bin/perl

###########################################################################
# TP_screen_watcher.pl by Eric Rosenfield
###########################################################################
#
# This program opens a port connection to each of the node computers and
# listens to see if something is wrong with the plasma screen. If something
# is wrong, it sends email.
# 
#######################################################################


use Socket;
use POSIX;
use Symbol;

########## SIGNAL HANDLERS #########################################
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = \&HUNTSMAN;

#$server_host = '127.0.0.1';

$files = `ls /usr/local/thinkpix/Screens`;
my @filetemp;
@filetemp = split(/\n/,$files);
my @ips;
my $i = 0;
foreach (@filetemp) {
    if ($_ =~ /.ctl/) {
	$ips[$i] = $_;
	$ips[$i] =~ s/.ctl//g;
	print $ips[$i];
	$i++;
    }
}
my %pids;
foreach my $ip (@ips) {
    print "\n" .$ip . "\n";
   $pids{$ip} =  &makesocket($ip);
}

#my $pids = &makesocket($ip); 

sub makesocket {
    $sigset = POSIX::SigSet->new(SIGINT);

  sigprocmask(SIG_BLOCK, $sigset)
      or die "can't block SIG_INT for $$ $!\n";

    die "fork: can't fork $!\n" unless defined ($pid = fork);


    if ($pid){
	## parent records the childs birth and returns pid
	## parent records the childs birth and returns pid
	sigprocmask(SIG_UNBLOCK, $sigset) or
	die "can't unblock SIGINT for child $pid\n";
	return $pid;

    } else {

	## Reset the interupt signal so the child won't trap kills
	$SIG{INT} = 'DEFAULT';

	sigprocmask(SIG_UNBLOCK, $sigset) or
	    die "can't unblock SIGINT for child $pid\n";

	my $ip_add = shift;

	my ($junk, $junk2, $junk3, $num) = split(/\./,$ip_add);
	my $server_port = "60" . $num;

## create a socket 
##  ARGS( FILE_HANDLE, socket type, communications type, protoclo )
	socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

## this allows us to restart the server quickly..
	setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);

## build up my socket address
	$my_addr = sockaddr_in($server_port, INADDR_ANY);

	bind(SERVER, $my_addr) or print "can't bind to $server_port\n";

	listen(SERVER, SOMAXCONN) or print "can't listen to $server_port\n";

	$| = 1;
	open(HOLD, "> Pipes/$ip_add.pipe") or die $!;

### args to accept are: 
###         (TO HANDLE, FROM HANDLE)
	while (accept(CLIENT, SERVER)){
	    while ($buf = <CLIENT>){
		if ($buf) { 
		    if ($buf =~ /err/) {
			`./buggen.pl "screen" "$ip_add" "$buf"`;
		    }
		    print $buf;
		    undef $buf;
		}
	    }
	}

	close(SERVER);
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

## this shoulc kill all the children
sub HUTSMAN {
    local($SIG{CHLD}) = 'IGNORE';
    my %children;
    kill 'INT' => keys %children;
    exit;
}








