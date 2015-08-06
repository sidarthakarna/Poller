#!/usr/bin/perl

use POSIX ":sys_wait_h";
use strict;
use warnings;
use NanoMsg::Raw;
use Test::More;

my $socket_address = 'ipc:///tmp/pubsub.ipc';
my $pid = fork();
$|=1;
if(not $pid) {
    $|=1;
    my $sub = nn_socket(AF_SP, NN_SUB);
    
    ok($sub>= 0, "Child - Subscribe");
    
    unless(nn_setsockopt( $sub, NN_SUB, NN_SUB_SUBSCRIBE, '' ) >= 0){ 
	die 'Cannot set socket'; 
    }
    
    unless(nn_connect($sub, $socket_address) >= 0){
	die "Cannot set socket";
    }
    my $buf;
    print "Hello";

    unless(nn_recv($sub, $buf, 3, 0) >= 0){
	die 'Cannot recieve';
    }
    print "Buf: $buf";
    is $buf, "1";
 #   is 1, 2;
    nn_close $sub;
}
else {
#    sleep 2;
    my $pub = nn_socket(AF_SP, NN_PUB);
    ok ( $pub>=0,  "Publish Socket");
    ok(nn_bind($pub, $socket_address)>=0, 'Bind');
    ok(nn_send($pub, "1")>0, "Send");
    
    nn_shutdown($pub, 0);
    print "Waiting for child to finish";
 #   while (wait() != -1) {}
    wait();
    nn_close $pub;
}

done_testing();

