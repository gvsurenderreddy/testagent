util = require 'util'
exec = require('child_process').exec
fs = require('fs')
validate = require('json-schema').validate

Schema =
    name: "netem"
    type: "object"
    required: true
    properties:        
        bandwidth:  {"type":"string", "required":true}
        latency:  {"type":"string", "required":true}
        jitter:  {"type":"string", "required":true}
        pktloss:  {"type":"string", "required":true}


class IPRoute2	

    setDelayLoss : (ifname, data , callback)->  
        #return callback false unless data instanceof netemData        
        latency = data.latency
        distribution = "normal"
        variation = data.jitter
        correlation = "10%"
        loss = data.pktloss
        correlation = "10%"

        command = "tc qdisc add dev #{ifname} root handle 1:0  netem delay #{latency} #{variation} #{correlation} distribution #{distribution} loss #{loss} #{correlation}" 
        util.log "netstats executing #{command}..."
        exec command, (error, stdout, stderr) =>
            util.log "netstats: execute - Error : " + error if error?
            util.log "netstats: execute - stdout : " + stdout if stdout?
            util.log "netstats: execute - stderr : " + stderr if stderr?
            callback(true)

    setBandwidth : (ifname, data, callback)->
        #bandwidth routine
        # tc qdisc add dev eth1 root handle 1: cbq avpkt 1000 bandwidth 10Mbit
        #return callback false unless data instanceof netemData        
        avgpkt = "1000"
        bandwidth = data.bandwidth
        command = "tc qdisc add dev #{ifname} parent 1:1 handle 10: tbf rate  #{bandwidth} buffer 1600 limit 3000"
        # tc qdisc add dev eth0 parent 1:1 handle 10: tbf rate 256kbit buffer 1600 limit 3000
        util.log "netstats executing #{command}..."
        exec command, (error, stdout, stderr) =>
            util.log "netstats: execute - Error : " + error if error?
            util.log "netstats: execute - stdout : " + stdout if stdout?
            util.log "netstats: execute - stderr : " + stderr if stderr?
            callback(true)                


    setLinkChars : (ifname,data, callback) ->
        util.log "iproute2drive setlink chars input - #{ifname}  - " + JSON.stringify data
        chk = validate data, Schema
        console.log 'validate result ', chk
        unless chk.valid
            throw new Error "schema check failed"+  chk.valid
            return callback false
        callback true
        #util.log "setLinkChars data input " + JSON.stringify data
        @setDelayLoss ifname, data , (result)=>
            util.log "setDelay result" + result
            #setLoss data.data, (result)=>
            #   util.log "setLoss result" + result
            @setBandwidth ifname, data, (result)=>
                util.log "setBandwidth result " + result     


    addTapLink : (ifname1,ifname2,callback)->
        command = "ip link delete #{ifname}"        
        util.log "executing #{command}..."
        exec command, (error, stdout, stderr) =>
            util.log "link remove: execute - Error : " + error if error?
            util.log "link removal: execute - stdout : " + stdout if stdout?
            util.log "link removal: execute - stderr : " + stderr if stderr?
            callback(true) unless error?
            callback(false) if error?

    delLink : (ifname,callback)->
        command = "ip link delete #{ifname}"        
        util.log "executing #{command}..."
        exec command, (error, stdout, stderr) =>
            util.log "link remove: execute - Error : " + error if error?
            util.log "link removal: execute - stdout : " + stdout if stdout?
            util.log "link removal: execute - stderr : " + stderr if stderr?
            callback(true) unless error?
            callback(false) if error?


module.exports = new IPRoute2

#  Notes
#
#
#Delay
#1.
#  tc qdisc add dev eth0 root netem delay 100ms
#2.
#Real wide area networks show variability so it is possible to add random variation.
#tc qdisc change dev eth0 root netem delay 100ms 10ms
#3.
#This causes the added delay to be 100ms ± 10ms. Network delay variation isn't purely random, so to emulate
# that there is a correlation value as well
# tc qdisc change dev eth0 root netem delay 100ms 10ms 25%
#tc qdisc add dev <interface> root netem delay <delay in ms> <delay variation in ms>  <delay variation correlation %>



#Delay distribution
#1. tc qdisc change dev eth0 root netem delay 100ms 20ms distribution normal


#packet loss
 # tc qdisc change dev eth0 root netem loss 0.1%
 #packetloss co-rrelation
 # tc qdisc change dev eth0 root netem loss 0.3% 25%


 #packet duplication
# tc qdisc change dev eth0 root netem loss 0.3% 25%

 #packet corruption
#tc qdisc change dev eth0 root netem corrupt 0.1% 

 #packet re-ordering
#tc qdisc change dev eth0 root netem gap 5 delay 10ms
#tc qdisc change dev eth0 root netem delay 10ms reorder 25% 50%
#
# tc qdisc change dev eth0 root netem delay 100ms 75ms

# tc qdisc change dev eth0 root netem
#                                       delay
#                                       loss
#                                       corrupt

#final commands
#reference:
#http://www.linuxfoundation.org/collaborate/workgroups/networking/netem
#  tc qdisc add dev eth0 root handle 1:0 netem delay 100ms
# tc qdisc add dev eth0 parent 1:1 handle 10: tbf rate 256kbit buffer 1600 limit 3000