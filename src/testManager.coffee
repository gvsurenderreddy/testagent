StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
extend = require('util')._extend
validate = require('json-schema').validate
testrunner = require('./testRunner')
pingschema = require('./schema').pingschema
iperftcpschema = require('./schema').iperftcpschema
iperfudpschema = require('./schema').iperfudpschema

#---------------------------------------------------------------
#utility functions
ParsePingResultPackets = (data) ->
    String output = data.toString()
    #console.log "parseping packet " + output
    output = output.trim()
    #console.log "parseping packet " + output
    tmparr = output.split " "
    #console.log "parseping packet array " , tmparr
    return tmparr[0]

ParsePingResultTime = (data) ->            
    String output = data.toString()        
    output = output.trim()        
    tmparr = output.split " "        
    #console.log "ParsePingResultTime array " , tmparr
    return tmparr[1]

ParsePingResultRTT = (data) ->
    String output = data.toString()        
    output = output.trim()        
    tmparr = output.split "="
    tmparr1 = tmparr[1].split "/"
    return tmparr1

parsePingResult = (data) ->        
    String output = data.toString()
    tmparr = []
    tmparr = output.split "\n"                    
    tmpvars = tmparr[3].split(/,/)        
    #console.log "line " + tmparr[4]
    tmpvars1 = tmparr[4].split(/,/)        
    #console.log "line arrray " + tmpvars1  
    rtt = []
    rtt = ParsePingResultRTT(tmpvars1[0])
    #console.log "rtt output",rtt
    res =
        "transmitted" : ParsePingResultPackets(tmpvars[0])
        "received" : ParsePingResultPackets(tmpvars[1])
        "packetloss" : ParsePingResultPackets(tmpvars[2])
        "totaltime" : ParsePingResultTime(tmpvars[3])
        "rtt_min" : rtt[0]
        "rtt_max" : rtt[1]
        "rtt_avg" : rtt[2]
    res

parseTCPResult = (data) ->
    String output = data.toString()
    tmparr = []
    tmparr = output.split ","
    console.log "tmparray", tmparr

    transferredData = tmparr[7] / (1024*1024)
    transferredData += "MB"

    BW = tmparr[8] / (1000*1000)
    BW += "Mbps"

    result = 
        date : tmparr[0]
        senderip : tmparr[1]
        senderport : tmparr[2]
        receiverip : tmparr[3]
        receiverport : tmparr[4]
        iperf_test_id : tmparr[5]
        interval : tmparr[6]
        transfer : transferredData
        bandwidth : BW
    util.log "parseTCPResult output " + JSON.stringify result
    return result

parseUDPResult = (data) ->
    String output = data.toString()
    tmparr = []
    tmparr = output.split "\n"
    senderdata = tmparr[0].split ","
    reporteddata = tmparr[1].split ","
    #console.log "tmparray", tmparr
    transferredData =  reporteddata[7] / (1024*1024)
    transferredData += "MB"

    BW = reporteddata[8] / (1000*1000)
    BW += "Mbps"

    result = 
        date : reporteddata[0]
        senderip : reporteddata[1]
        senderport : reporteddata[2]
        receivedip : reporteddata[3]
        receiverport : reporteddata[4]
        test_id : reporteddata[5]
        interval : reporteddata[6]
        transfer : transferredData
        bandwidth : BW
        jitter : reporteddata[9]
        lostdatagrams : reporteddata[10]
        totaldatagrams : reporteddata[11]
        unknown1   : reporteddata[12]
        unknown2 : reporteddata[13]

    util.log "parseUDPResult output " + JSON.stringify result
    return result



#============================================================================================================
class TestRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            #log.debug "restoring #{key} with:",val
            entry = new TestData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof TestData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof TestData
            entry.data.id = entry.id
            entry.data
        else
            entry

#============================================================================================================

class TestData extends StormData
    TestSchema =
        name: "Test"
        type: "object"        
        properties:                        
            name: {type:"string", required:false}
            destination: {type:"string", required:true}
            type: {type:"string", required:true}            
            duration : {type:"string", required:false}
            config: 
                type: "object"
                required: false

    constructor: (id, data) ->
        super id, data, TestSchema

#============================================================================================================


class Test  
    constructor :() ->        
        @testData = {}        
        @testResult = []        
        util.log "New Test is created"

    CreateIperfTcpClient : ()->
        Basecommand = "iperf -c #{@testData.destination} -y C "
        flags = " "        
        flags += " -w #{@testData.config.windowsize} " if @testData.config.windowsize?
        flags += " -l #{@testData.config.packetsize} " if @testData.config.packetsize?
        flags += " -p #{@testData.config.port} "if @testData.config.port?
        if @testData.duration?
            flags += " -t #{@testData.duration} "
        else
            flags += " -t 60 "
        Basecommand += flags
        @command = Basecommand
        util.log "IPERF TCP CLIENT " + @command

    CreateIperfUdpClient : ()->   
        Basecommand = "iperf -c #{@testData.destination} -u -y C "
        flags = " "        
        flags += " -b #{@testData.config.bandwitdh} " if @testData.config.bandwitdh?
        flags += " -l #{@testData.config.packetsize} " if @testData.config.packetsize?
        flags += " -p #{@testData.config.port} "if @testData.config.port?
        if @testData.duration?
            flags += " -t #{@testData.duration} "
        else
            flags += " -t 60 "

        Basecommand += flags
        @command = Basecommand
        util.log "IPERF UDP CLIENT " + @command

    CreatePingCommand : ()->
        Basecommand = "ping"
        flags = " "
        flags += "-f " if @testData.config.flood? and @testData.config.flood is "yes"
        flags += "-A " if @testData.config.adaptive? and  @testData.config.adaptive is "yes"
        flags += " -s #{@testData.config.packetsize}" if @testData.config.packetsize?
        if @testData.config.count?
            flags += " -c #{@testData.config.count}" 
        else
            flags += " -c #{@testData.duration}"
        flags += " -q "
        @command = Basecommand + flags + @testData.destination
        console.log "ping comands is " + @command      

    create : (tdata)->
        @testData = extend {},tdata.data      
        @testData.createdTime = new Date
        @uuid = tdata.id
        util.log "Test created with " + JSON.stringify @testData       
        util.log  @testData.type

        switch @testData.type
            when "ping"
                chk = validate @testData.config, pingschema
                console.log 'pingSchema validate result ', chk
                unless chk.valid
                    return new Error "ping schema check failed" +  chk.valid
                @CreatePingCommand()   
            when "tcp"
                chk = validate @testData.config, iperftcpschema
                console.log 'iperftcpSchema validate result ', chk
                unless chk.valid
                    return new Error "tcp schema check failed" +  chk.valid
                @CreateIperfTcpClient()  
            when "udp"
                chk = validate @testData.config, iperfudpschema
                console.log 'iperfudpSchema validate result ', chk
                unless chk.valid
                    return  new Error "udp schema check failed" +  chk.valid
                @CreateIperfUdpClient()
        true

    parseResult : (result)->
        switch @testData.type
            when "ping"
                data = parsePingResult(result)                
            when "tcp"
                #console.log "tcp test is get parsed"
                data = parseTCPResult(result)
            when "udp"
                data = parseUDPResult(result)
        return data

    run : ()->
        #check - start and stop condition of the test infinetely and trigger the testontime
        @testData.startedTime = new Date
        @testData.command = @command
        @testData.status = "started"
        testrunner.runCommand @command,(result)=>
            @testData.rawTestResult = result
            @testData.completedTime = new Date
            if result instanceof Error
                @testData.status = "Error"                
            else
                @testData.status = "completed"       
                @testData.testResult = @parseResult(result) 

    get : ()->        
    	@testData
    del : ()->
    	true

#============================================================================================================
class TestManager 
    constructor :()->
        @registry = new TestRegistry
        @testObjs = {}

    create :(data, callback)->
        try    
            testdata = new TestData null, data    
        catch err
            console.log "TestData - invalid schema " + JSON.stringify err
            return callback new Error "Invalid Schema Input "
        finally
            console.log "TestData  created " + JSON.stringify testdata 

        #finally create a project                    
        #console.log "Test schema check is passed " + JSON.stringify testdata
        testObj = new Test        
        result = testObj.create testdata              
        return callback result if result instanceof Error        
        @testObjs[testObj.uuid] = testObj        
        testObj.run()
        return callback @registry.add testdata    

    del : (id, callback) ->
        obj = @testObjs[id]
        if obj? 
            #remove the registry entry
            @registry.remove obj.uuid           
            result = obj.del()
            return callback result
        else
            return callback new Error "Unknown Test ID"

    get : (id, callback) ->
        obj = @testObjs[id]
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown Test ID"
    
    list : (callback) ->
        return callback @registry.list()
#============================================================================================================
module.exports =  new TestManager
