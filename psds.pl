#!/usr/bin/perl
###########################################################################
#
# PLayer Server by Eric Rosenfield modified by DS
#
###########################################################################
#
# Takes commands through Standard In and sends them to the admin program on the
# specified node computer through the port connection. 
# the program is called in the following way: 
# ./admin_server.pl "command" "ip_address"
# If the "ip_adress" is set to "all" then it reads all the ip addresses from
# the control files (in the "Screens" folder) and sends the command to all of
# them simultaneously.
#
############################################################################


use lib "/usr/local/thinkpix";
use TP_admin;
use TP_ParseCtl;

$command = shift;
$ip = shift;
$screen_dir = "Screens";

if ($command eq "" || $ip eq "") {
    print "\n use: ./admin_server.pl command ip_address \n\n";
    exit;
}

$admin = new TP_admin;

if ($ip = "all") {
    my $playlist = new TP_ParseCtl;
    my $ctl_files = $playlist->list_ctl_files($screen_dir);
    foreach (@$ctl_files) {
	$_ =~ s/.ctl//g;
	$admin->send_command($command,$_, 4446);
    }
} else {
    $admin->send_command($command, $ip, 4446);
}




















