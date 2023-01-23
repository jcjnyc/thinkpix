#!/usr/bin/perl
####################################################################
#
# TP_ping_monitor.pl
#
# This program "pings" each of the node computers, based on their IPs
# in the "Screens" folder. If the ping returns negative (the box does not
# respond, it sends the appropriate message to buggen.pl.
#
# This program MUST be run as root, because of the ping method, and
# is set in the crontab to run every 5 minutes.
#
#####################################################################

use lib "/usr/local/thinkpix";
use Net::Ping;
use TP_ParseCtl;
use strict;

my $screen_dir = '/usr/local/thinkpix/Screens';
my $errorlog = "/usr/local/thinkpix/Logs/ping_errors.txt";


my $playlist = new TP_ParseCtl;
my $ctl_files = $playlist->list_ctl_files($screen_dir);
my $p = Net::Ping->new("icmp",30);

### if it doesn't exist, make it
if (-e "$errorlog") {
    open(FILE, "<$errorlog");
    close(FILE);
}

### ping and log if error
open(MYERRLOG, ">>$errorlog");
foreach (@$ctl_files) {
    #print $_ . "\n";
    $_ =~ s/.ctl//g;

    #check to see if locking file is there, which would mean that the bug is being looked into
    if (!-e "Bugs/$_.pinglock") {
	system("./buggen.pl ping $_") if !$p->ping("$_");

	print MYERRLOG "Could not ping host $_, email sent" if !$p->ping("$_");
    }
}
close(MYERRLOG);
$p->close;















































































