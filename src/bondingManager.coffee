
util = require('util')
extend = require('util')._extend
validate = require('json-schema').validate
keystore = require('mem-db')
bondingSchema = require('./schema').bondingSchema
testrunner = require('./testRunner')
async = require('async')


createbonding = (config, callback)->
#step1 :
    console.log "createbonding input data ", JSON.stringify config
    async.series([
        (callback)=>
            console.log "create bonding interface"
            command = "ip link add #{config.bondname} type bond"
            testrunner.runCommand command,(result)=>
                console.log "Result ", result
                if result instanceof Error
                    callback new Error ('create bonding interface') 
                else
                    callback(null,"create bonding interface success") 
        ,
        (callback)=>
            console.log "attaching ethernet interfaces to bond interface"
            console.log config.interfaces
            async.each config.interfaces, (ifname,callback) =>
                console.log "interface  #{ifname}"
                command = "ip link set #{ifname} down"
                testrunner.runCommand command,(result)=>
                    #callback new Error ('attaching  interface failed ') if result instanceof Error
                    callback result if result instanceof Error
                    command = "ip link set #{ifname} master #{config.bondname}"
                    testrunner.runCommand command,(result)=>
                        console.log "Result ", result
                        if result instanceof Error
                            callback result                         
                        else
                            callback (null)
            ,(err) =>
                if err
                    console.log  "attaching ethernet interfaces - error occured " + JSON.stringify err
                    callback err
                else
                    console.log  "attaching ethernet interfaces - success "
                    callback(null,"attaching ethernet interfaces - success")
        ,
        (callback)=>
            console.log "setting the ip address to the bond interface"
            #ip addr add 10.10.10.2/24 dev bond0
            command = "ip addr add #{config.ipaddress}/24 dev #{config.bondname}"
            testrunner.runCommand command,(result)=>
                console.log "Result",result
                if result instanceof Error
                    callback new Error ('setting the bond ip address failed') 
                else
                    callback(null,"setting the bond ip address - success")
        ,
        (callback)=>
            console.log "enabling the bond interface "   
            command = "ip link set #{config.bondname} up"
            testrunner.runCommand command,(result)=>
                if result instanceof Error
                    callback new Error ('enabling the bond interfae failed') 
                else
                    callback(null,"enabling the bondinterace- success")
        ],
        (err,result)=>
            console.log "Bonding -  RUN result is  %s ", result
            return callback false if err
            return callback true unless err

        )


#ip link add bond0 type bond
#ip link set eth1 down
#ip link set eth2 down
#ip link set eth1 master bond0
#ip link set eth2 master bond0
#ip addr add 10.10.10.2/24 dev bond0
#ip link set bond0 up


#============================================================================================================
class bondingManager 
    constructor :()->
        @registry = new keystore "bonding",bondingSchema
        @bondingobjs = {}

    create :(data, callback)->
        id = @registry.add data         
        return callback new Error "invalid Schema" if id instanceof Error or false
        console.log "new bonding config created - id " + id
        createbonding data,(result)->
            return callback {"id":id, "status":"created"} if result is true
            return callback {"id":id, "status":"failed"} if result is false

    get : (id, callback) ->
        return callback @registry.get id

    list : (callback) ->
        return callback @registry.list()



#============================================================================================================
module.exports =  new bondingManager