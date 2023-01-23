#!/usr/bin/perl

use lib "/usr/local/thinkpix";
use TP_ParseCtl;
$screen_dir = "/usr/local/thinkpix/Screens";


my $playlist = new TP_ParseCtl;

my $ctl_files = $playlist->list_ctl_files($screen_dir);
foreach (@$ctl_files) {
    $_ =~ s/.ctl//g;
    print "shutting down screen " . $_ . "\n";
    sleep(1);
    `cd /usr/local/thinkpix;./player_server.pl "quit daemon" "$_";./admin_server.pl "system rebootit" "$_";`;
    print $_;
    sleep(60);

}

