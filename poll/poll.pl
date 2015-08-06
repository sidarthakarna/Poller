#!/usr/bin/perl

use POSIX ":sys_wait_h";
use strict;
use warnings;
use NanoMsg::Raw;
use Carp::Assert;

my $socket_address = 'ipc:///tmp/pubsub.ipc';


sub listen_nano {
    
    $|=1;
    my $ret;
    my $sub = nn_socket(AF_SP, NN_SUB);
    my $logInitial = "Process $$";

    print "Child:$$\n";
    
    assert($sub>= 0, 'Cannot Child - Subscribe:'. nn_strerror($sub));

    $ret = nn_setsockopt( $sub, NN_SUB, NN_SUB_SUBSCRIBE, '' );
    assert($ret >= 0, "Setting subscribe option failed - " . nn_strerror($ret));

    $ret= nn_setsockopt($sub, NN_SOL_SOCKET,NN_RCVTIMEO, 3000);
    assert($ret>=0, "Setting Recieve socket timeout failed:" . nn_strerror($ret));
    
    unless(nn_connect($sub, $socket_address) >= 0){
	die "Cannot set socket";
    }
    my $buf;

    while(nn_recv($sub, $buf, NN_MSG, ETIMEDOUT)){
	print "$logInitial: Buf: $$: $buf\n";
	sleep 1;
    }
    print "$logInitial: done\n";
 #    is $buf, "1";
 #   is 1, 2;
    nn_close $sub;
}

my $ret;

my @pids;
my $parent = $$;
$|=1;

for (1..4){
    if ( $$ == $parent ){
	my $pid = fork();
	if(not $pid) {
	    listen_nano;
	}
    }
}

if ($parent == $$) {
#    sleep 2;
    my $pub = nn_socket(AF_SP, NN_PUB);
    assert( $pub>=0,  "Publish Socket failed - " . nn_strerror($pub) );
    
    $ret = nn_bind($pub, $socket_address);
    assert($ret >= 0, 'Bind failed:' . nn_strerror($ret));
    
    for(1..10){
	$ret = nn_send($pub, "1");
	assert($ret>0, 'Send failed: ' . nn_strerror($ret));
    }
    
    nn_shutdown($pub, 0);
    print "Waiting for child to finish\n";
 #   while (wait() != -1) {}
    wait();
    nn_close $pub;
    exit 0;
}





