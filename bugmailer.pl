#!/usr/bin/perl

$mailprog = '/usr/sbin/sendmail';

$reportnum = shift;

open(FILE, "Bugs/$reportnum.bug") or die "Can't open bug report $reportnum.bug $!";

$file = join("", <FILE>);

($subject, $email, $body) = split(/\n\n/, $file);

my @addresses;

if ($email =~ /\,/) {
    @addresses = split(/\,/,$email);
} else { 
    $addresses[0] = $email;
}

print $subject . "\n" . $email . "\n" . $body . "\n";

print qq("$email"\n);

close(FILE);




foreach (@addresses) {
    open(MAIL,"|$mailprog -t") or die "can't open mail program $!";  
    print $_ . "\n";
    print MAIL "To: $_\n";
    print MAIL "From: BugProgram\@thinkpix.com\n";
    print MAIL "Subject: $subject\n";
    print MAIL "$body\n";
    close(MAIL);
}





