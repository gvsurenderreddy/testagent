StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
extend = require('util')._extend
validate = require('json-schema').validate
testrunner = require('./testRunner')

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
pingschema =
    name : "ping"
    type : "object"
    required : true
    properties:
        adaptive: {"type": "string", "required":true} 
        flood: {"type": "string", "required":true} 
        count: {"type": "number", "required":true} 
        packetsize: {"type":"number", "required":true} 
        interval : {"type":"number", "required":false} 

iperftcpschema =
    name : "iperftcp"
    type : "object"
    required : true
    properties:
        windowsize: {"type": "number", "required":false} 
        packetsize: {"type": "number", "required":false} 
        port: {"type": "number", "required":false} 


iperfudpschema =
    name : "iperfudp"
    type : "object"
    required : true
    properties:
        bandwidth: {"type": "string", "required":false} 
        packetsize: {"type": "number", "required":false} 
        port: {"type": "number", "required":false} 


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
        if @testData.config.flood is "yes"
            flags = "-f " 
        else if @testData.config.adaptive is "yes"
            flags = " -A " 
        else
            flags = " "
        flags += " -c #{@testData.config.count}" if @testData.config.count?
        flags += " -s #{@testData.config.packetsize}" if @testData.config.packetsize?
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

    run : ()->
    	#check - start and stop condition of the test infinetely and trigger the testontime
        @testData.startedTime = new Date
        @testData.status = "started"
        switch @testData.type
            when "ping"
                testrunner.runping @command,(result)=>
                    console.log "ping result is " + result                    
                    @testData.testResult = result
                    @testData.status = "completed"
                    @testData.completedTime = new Date
            when "tcp"
                testrunner.runtcp @command,(result)=>
                    console.log "tcp result is " + result                    
                    @testData.testResult = result
                    @testData.status = "completed"
                    @testData.completedTime = new Date
            when "udp"
                testrunner.runudp @command,(result)=>
                    console.log "udp result is " + result                    
                    @testData.testResult = result
                    @testData.status = "completed"
                    @testData.completedTime = new Date

    get : ()->        
    	@testData
    del : ()->
    	true

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



###
ping
config = 
    destination:
    config :
        adpative: yes
        flood : yes
        count : 20
        packetsize : 1400
        interval : 23



-c  <count>
-A  adpative ping --- kind of flood
-s  <package size>
-f   flood ping 
-q   quite mode -- only summary output    

iperf udp client

config =
    destination:
    duration : 300
    config:
        bandwitdh: 128kb
        packetsize: 1000
        port: 5001


iperf tcp client

config =
    destination:
    duration : 300
    config:
        windowsize: 100
        packetsize: 1000           
        port: 5001

###