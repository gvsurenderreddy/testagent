

StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
extend = require('util')._extend
validate = require('json-schema').validate
netem = require('./builder/iproute2driver')

#============================================================================================================
class LinkconfigRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            #log.debug "restoring #{key} with:",val
            entry = new LinkconfigData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof LinkconfigData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof LinkconfigData
            entry.data.id = entry.id
            entry.data
        else
            entry

#============================================================================================================

class LinkconfigData extends StormData

    LinkconfigSchema =
        name: "netem"
        type: "object"
        properties:        
            interface:  {"type":"string", "required":true}            
            config: 
                type: "object"
                required: true
                properties:        
                    bandwidth:  {"type":"string", "required":true}
                    latency:  {"type":"string", "required":true}
                    jitter:  {"type":"string", "required":true}
                    pktloss:  {"type":"string", "required":true}


    constructor: (id, data) ->
        super id, data, LinkconfigSchema

#============================================================================================================


class Linkconfig  
    constructor :() ->        
        @linkData = {}        
        #@testResult = []        
        #util.log "New Test is created"
 

    create : (tdata)->
        @linkData = extend {},tdata.data      
        @linkData.createdTime = new Date
        @uuid = tdata.id
        util.log "Link Config created with " + JSON.stringify @linkData               
        netem.setLinkChars @linkData.interface, @linkData.config, (result)=>
            console.log "result is ", result
            @linkData.status = result
        true
    get : ()->        
    	@linkData
    del : ()->
    	netem.delLink @linkData.interface, (result)=>
            console.log "link delete", result

#============================================================================================================
class LinkconfigManager 
    constructor :()->
        @registry = new LinkconfigRegistry
        @linkconfigobjs = {}

    create :(data, callback)->
        try    
            linkconfigdata = new LinkconfigData null, data    
        catch err
            console.log "linkconfigData - invalid schema " + JSON.stringify err
            return callback new Error "Invalid Schema Input "
        finally
            console.log "linkconfigData  created " + JSON.stringify linkconfigdata 

        #finally create a project                    
        #console.log "Test schema check is passed " + JSON.stringify testdata
        obj = new Linkconfig        
        result = obj.create linkconfigdata              
        return callback result if result instanceof Error        
        @linkconfigobjs[obj.uuid] = obj        
        return callback @registry.add linkconfigdata    

    put : (id, data, callback)->

    del : (id, callback) ->
        obj = @linkconfigobjs[id]
        if obj? 
            #remove the registry entry
            @registry.remove obj.uuid           
            result = obj.del()
            return callback result
        else
            return callback new Error "Unknown linkobject ID"

    get : (id, callback) ->
        obj = @linkconfigobjs[id]
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown linkobject ID"
    
    list : (callback) ->
        return callback @registry.list()
#============================================================================================================
module.exports =  new LinkconfigManager
