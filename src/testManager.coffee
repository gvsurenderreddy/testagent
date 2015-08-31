assert = require 'assert'
StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
async = require 'async'

ping = require('./pingdriver')

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
        #additionalProperties: true
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
###
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
###

class Test  
    constructor :() ->        
        @testData = {}
        #@sysconfig = {}
        @testResult = []
        #@statistics = {}        
        util.log "New Test is created" + JSON.stringify @testData

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
        @pingcommand = Basecommand + flags + @testData.destination
        console.log "ping comands is " + @pingcommand      

    create : (tdata)->
        @testData = extend {},tdata.data      
        @testData.createdTime = new Date
        @uuid = tdata.id
        util.log "Test created with " + JSON.stringify @testData       
        util.log  @testData.type
        if @testData.type is "ping"
            util.log  @testData.type
            @CreatePingCommand(@testData.config)   
    run : ()->
    	#check - start and stop condition of the test infinetely and trigger the testontime
        @testData.startedTime = new Date
        ping.runping @pingcommand,(result)=>
            @testData.completedTime = new Date
            console.log "ping result is " + result
            @testResult = result
            @testData.testResult = @testResult



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
        console.log "Test schema check is passed " + JSON.stringify testdata
        testObj = new Test        
        testObj.create testdata              
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