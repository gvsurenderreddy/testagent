util = require 'util'
exec = require('child_process').exec

class testrunner
    execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
            util.log "Execution- Error : " + error
            #util.log "Ping - stdout : " + stdout
            util.log "Execution - stderr : " + stderr
            if error
                callback error
            else
                callback stdout   
    parsePingResult : (data) ->        
        String output = data.toString()
        tmparr = []
        tmparr = output.split "\n"                    
        tmpvars = tmparr[3].split(/,/)        

        console.log "line " + tmparr[4]
        tmpvars1 = tmparr[4].split(/,/)        
        console.log "line arrray " + tmpvars1        
        result1 =
            transmitted : tmpvars[0]
            received : tmpvars[1]
            packetloss : tmpvars[2]
            totaltime: tmpvars[3]
            rtt_min : tmpvars1[0]
            rtt_max : tmpvars1[0]
            rtt_avg : tmpvars1[0]
            rtt_mdev : tmpvars1[0]
            ipg: tmpvars1[1]
            ewma: tmpvars1[1]
        return result1     

    parseTCPResult : (data)->
        String output = data.toString()
        tmparr = []
        tmparr = output.split ","
        console.log "tmparray", tmparr
        result = 
            date : tmparr[0]
            senderip : tmparr[1]
            senderport : tmparr[2]
            receiverip : tmparr[3]
            receiverport : tmparr[4]
            iperf_test_id : tmparr[5]
            interval : tmparr[6]
            transfer : tmparr[7]
            bandwidth : tmparr[8]
        util.log "parseTCPResult output " + JSON.stringify result
        return result

    parseUDPResult : (data)->
        String output = data.toString()
        tmparr = []
        tmparr = output.split "\n"
        senderdata = tmparr[0].split ","
        reporteddata = tmparr[1].split ","

        console.log "tmparray", tmparr
        result = 
            sender_date : senderdata[0]
            sender_senderip : senderdata[1]
            sender_senderport : senderdata[2]
            sender_receiverip : senderdata[3]
            sender_receiverport : senderdata[4]
            sender_iperf_test_id : senderdata[5]
            sender_interval : senderdata[6]
            sender_transfer : senderdata[7]
            sender_bandwidth : senderdata[8]
            reported_date : reporteddata[0]
            reported_senderip : reporteddata[1]
            reported_senderport : reporteddata[2]
            reported_receivedip : reporteddata[3]
            reported_receiverport : reporteddata[4]
            reported_iperf_test_id : reporteddata[5]
            reported_interval : reporteddata[6]
            reported_transfer : reporteddata[7]
            reported_bandwidth : reporteddata[8]
            reported_jitter : reporteddata[9]
            reported_lostdatagrams : reporteddata[10]
            reported_totaldatagrams : reporteddata[11]
            reported_unknown1   : reporteddata[12]
            reported_unknown2 : reporteddata[13]

        util.log "parseUDPResult output " + JSON.stringify result
        return result


    runping : (command, callback) ->
        @execute command,(result) =>      
            if result  instanceof Error
                return callback result
            data = @parsePingResult(result)
            callback data
    runtcp : (command, callback) ->        
        @execute command,(result) =>      
            if result  instanceof Error
                return callback result
            data = @parseTCPResult(result)
            callback data

    runudp : (command, callback) ->        
        @execute command,(result) =>      
            if result  instanceof Error
                return callback result
            data = @parseUDPResult(result)
            callback data

module.exports = new testrunner
