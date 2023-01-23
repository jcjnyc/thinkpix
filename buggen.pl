#!/usr/bin/perl
##########################################################################
#
# Bug Generator by Eric Rosenfield
# This program takes an argument about which bug and which bug and which
# ip the bug is associated with. It currently only accepts the "ping" and 
# plasma screen monitoring  programs
#
# and more need to be added as ways are figured out to accept bugs
# The program is executed in the following manner:
# ./buggen.pl bugtype ip
#
# Update: I have wired this up to send an HTTP signal to the helpdesk CGI
# on the database server, to open a ticket.
#
###########################################################################

use LWP::UserAgent;

$bugtype = shift;

$screen = shift;

$error = shift;

if ($bugtype eq "ping") {

    $filename = "pingbug.tpl";
    $bugname = "cantping";

} elsif ($bugtype eq "screen") {

    $filename = "screenbug.tpl";
    $bugname = "plasmascreenerr";

} elsif ($bugtype eq "player") {

    $filename = "playerbug.tpl";
    $bugname = "playererr";

} else {
    #if no known bugs
    exit;

}

open(FILE, "Bugs/bugnum.txt");

$num = join("", <FILE>);
$num =~ s/\n//g;


close(FILE);

print $num;
$num++;

open(FILE, ">Bugs/bugnum.txt");
print FILE $num;
close(FILE);

open(FILE, "Bugs/$filename");

$body = join("",<FILE>);

close(FILE);

$body =~ s/::SCREEN::/$screen/g;

if ($error) { $body =~ s/::ERROR::/$error/g; }

open(FILE, ">Bugs/$num.bug");
print FILE $body;
print $body;
close(FILE);

### Send an HTTP request to the helpdesk program on the database server and open a ticket

$ua = new LWP::UserAgent;
$ua->agent("AgentName/0.1 " . $ua->agent);

my $req = new HTTP::Request POST => 'http://64.59.32.37/cgi-bin/index.cgi/new';

$req->content_type('application/x-www-form-urlencoded');
$req->content("name=ping&email=dist\@thunder.posternet.net&username=buggen&domain=64.59.32.24&problem=$bugname$screen&priority=Highest");

my $res = $ua->request($req);

if ($res->is_success) {
    #print $res->content;
} else {
    open(FILE, ">>Bugs/$num.bug");
    print FILE "\nCan't reach HelpDesk program via web to start ticket.";
    close(FILE);
}

system("./bugmailer.pl $num");













