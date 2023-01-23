#!/usr/bin/perl

$times = `sum Clips/*`;

@dat = split(/\n/,$times);

my %timehash;

foreach (@dat) {
    my @data = split(/ /,$_);
    my $time = $data[1] * 0.01;
    $time = $time * 8;
    my $filename = $data[2];
    $filename =~ s/Clips\///g;
    $timehash{$filename} = $time;
}

`./admin_server.pl "ftp files" all`;

foreach (sort keys %timehash) {
    print "Waiting for file $_ - $timehash{$_} seconds";
    sleep($timehash{$_});
}

`./admin_server.pl "launch player" all`;
`./admin_server.pl "launch motion" all`;
`./admin_server.pl "launch screen" all`;

`./startsystem.pl`;





