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

module.exports.pingschema = pingschema
module.exports.iperftcpschema = iperftcpschema
module.exports.iperfudpschema = iperfudpschema