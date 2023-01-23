#!/usr/bin/perl
#################################################################
# TP_Stop_system.pl by Eric Rosenfield
#
# This program kills all the program process beginning with "TP_" 
# (eg TP_Player_control.pl, TP_Sensor_server.pl, 
# TP_screen_watcher.pl, etc.). It is used to stop the system.
#
##################################################################

$processes = `ps -a`;

@dat = split(/\n/,$processes);

my $killers;

foreach (@dat) {

    my @data = split(' ', $_);
    #print $data[5];
    foreach my $dat (@data) {
	if ($dat =~ /TP_Stop_/) {
	    next;
	}
	elsif ($dat =~ /TP_/) {
	    $killers .= " " . $data[0];
	}
    }
    
}

if ($killers) {
    print `kill -9$killers` . "\n";
}




