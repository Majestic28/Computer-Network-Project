set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    CMUPriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 50                         ;# max packet in ifq
set val(nn)     6                          ;# number of mobilenodes
set val(rp)     DSR                       ;# routing protocol
set val(x)      1000                      ;# X dimension of topography
set val(y)      1000                     ;# Y dimension of topography
set val(stop)   20                        ;# time of simulation end


#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Open the NS trace file
set tracefile [open tcpReno.tr w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open tcpReno.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel


#     Mobile node parameter setup

$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON

#Create 6 nodes
set n0 [$ns node]
$n0 set X_ 599
$n0 set Y_ 601
$n0 set Z_ 0.0
$ns initial_node_pos $n0 20
set n1 [$ns node]
$n1 set X_ 799
$n1 set Y_ 601
$n1 set Z_ 0.0
$ns initial_node_pos $n1 20
set n2 [$ns node]
$n2 set X_ 599
$n2 set Y_ 401
$n2 set Z_ 0.0
$ns initial_node_pos $n2 20
set n3 [$ns node]
$n3 set X_ 799
$n3 set Y_ 401
$n3 set Z_ 0.0
$ns initial_node_pos $n3 20
set n4 [$ns node]
$n4 set X_ 556
$n4 set Y_ 368
$n4 set Z_ 0.0
$ns initial_node_pos $n4 20
set n5 [$ns node]
$n5 set X_ 837
$n5 set Y_ 635
$n5 set Z_ 0.0
$ns initial_node_pos $n5 20

$ns at 5 " $n4 setdest 556 500 50 " 
$ns at 10 " $n5 setdest 700 635 50 " 
$ns at 10 " $n4 setdest 550 360 50 " 
$ns at 15 " $n3 setdest 700 500 50 " 

#        Agents Definition        
set tcp [new Agent/TCP/Reno]
$ns attach-agent $n4 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n5 $sink
$ns connect $tcp $sink
$tcp set packetSize_ 1500
$tcp set maxcwnd_ 16
$tcp set windowInit_ 1

#        Applications Definition        
#Setup a FTP Application over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 1.0 "$ftp start"


#        Termination        
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam tcpReno.nam &
    exit 0
}
proc plotting {tcpsource file1} {
	global ns
	set conges [$tcpsource set cwnd_]
	set now [$ns now]
	puts $file1 "$now $conges"
	$ns at [expr $now+0.1] "plotting $tcpsource $file1"
}
set print [open tcpRenoconges.xg w]
$ns at 0.0 "plotting $tcp $print"
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$n$i reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns run
