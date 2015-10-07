
util = require('util')
extend = require('util')._extend
validate = require('json-schema').validate
tcqdisc = require('linuxtcdriver')
keystore = require('mem-db')
linkconfigSchema = require('./schema').linkconfigSchema

#============================================================================================================
class LinkconfigManager 
    constructor :()->
        #@registry = new LinkconfigRegistry
        @registry = new keystore "LinkConfig",linkconfigSchema
        @linkconfigobjs = {}

    create :(data, callback)->
        id = @registry.add data         
        return callback new Error "invalid Schema" if id instanceof Error or false
        console.log "new link config created - id " + id
        tcobj = new tcqdisc data.interface, data.config                          
        @linkconfigobjs[id] = tcobj        
        tcobj.run (result)->        
        return callback {"id":id, "status":"created"}

    del : (id, callback) ->
        obj = @linkconfigobjs[id]
        if obj? 
            #remove the registry entry
            obj.del()
            @registry.del id                       
            return callback {"id":id, "status":"deleted"}
        else
            return callback new Error "Unknown linkobject ID"

    get : (id, callback) ->
        obj = @linkconfigobjs[id]
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown linkobject ID"
    
    statistics :(id,callback)->
        obj = @linkconfigobjs[id]
        if obj? 
            obj.statistics (result)=>
                return callback result
        else
            return callback new Error "Unknown linkobject ID"


    list : (callback) ->
        return callback @registry.list()
#============================================================================================================
module.exports =  new LinkconfigManager