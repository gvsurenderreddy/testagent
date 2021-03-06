#This file is used by kaanalnet package also. if any change in this file, copy it 
# in to the kaanalnet package
#
#version-1.0
pingschema =
    name : "ping"
    type : "object"
    required : true
    properties:
        adaptive: {"type": "string", "required":false} 
        flood: {"type": "string", "required":false} 
        count: {"type": "number", "required":false} 
        packetsize: {"type":"number", "required":false} 
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


linkconfigSchema =
    name: "netem"
    type: "object"
    properties:        
        interface:  {"type":"string", "required":true}       
        config: 
            type: "object"
            required: true
            properties:        
                bandwidth:  {"type":"string", "required":true}
                latency:  {"type":"string", "required":false}
                jitter:  {"type":"string", "required":false}
                pktloss:  {"type":"string", "required":false}

testschema =
    name: "Test"
    type: "object"
    properties:
        name: {type:"string", required:false}
        destination: {type:"string", required:true}
        type: {type:"string", required:true}            
        duration : {type:"number", required:true}
        config: 
            type: "object"
            required: false


bondingSchema =
    name: "bonding"
    type: "object"
    properties:
        bondname: {type:"string", required:true}
        bondmac: {type:"string", required:true}
        ipaddress: {type:"string", required:true}
        gateway : {type:"string", required:false}
        interfaces: 
            type: "array"
            required: true
            items:
                type:"string"
                required:true




module.exports.pingschema = pingschema
module.exports.iperftcpschema = iperftcpschema
module.exports.iperfudpschema = iperfudpschema
module.exports.linkconfigSchema = linkconfigSchema
module.exports.testschema = testschema
module.exports.bondingSchema = bondingSchema