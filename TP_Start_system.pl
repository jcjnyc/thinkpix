#!/usr/bin/perl

`./TP_Player_control.pl &` or print $!;
sleep(10);
`./TP_Sensor_server.pl &` or print $!;
sleep(10);
`./TP_Timer.pl &` or print $!;

print "System Started\n\n";


