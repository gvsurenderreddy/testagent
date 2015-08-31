util = require 'util'
exec = require('child_process').exec

class Ping
	execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
        	util.log "Ping - Error : " + error
        	#util.log "Ping - stdout : " + stdout
        	util.log "Ping - stderr : " + stderr
        	if error
                callback error
            else
                callback stdout   
    parseResult : (data) ->        
        String output = data.toString()
        tmparr = []
        tmparr = output.split "\n"                    
        tmpvars = tmparr[3].split(/,/)        

        console.log "line " + tmparr[4]
        tmpvars1 = tmparr[4].split(/,/)        
        console.log "line arrray " + tmpvars1
        #result = []
        #result = tmpvars + tmpvars1
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

	runping : (command, callback) ->		
		@execute command,(result) =>      
            if result  instanceof Error
                return callback result
            data = @parseResult(result)
            callback data


module.exports = new Ping



#testping = new Ping
#testping.runping "ping -A -q -c 5 localhost",(result)->
#    console.log "result is ",result

