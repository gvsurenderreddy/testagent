restify = require 'restify'
util = require('util')
fs = require 'fs'

testmgr = require('./testManager')

#Test Specific REST APIs
testPost = (req,res,next)->   
    console.log "REST API - POST /Test received, body contents - " + JSON.stringify req.body
    testmgr.create req.body, (result) =>
        console.log "POST /Test result " + JSON.stringify result 
        res.send result        
        next()

testList = (req,res,next)->
	console.log "REST API  GET /Test received"
	testmgr.list (result) =>
		console.log "list " + JSON.stringify result
		res.send result
		next()

testGet = (req,res,next)->
	console.log "REST API  GET /Test received"
	testmgr.get req.params.id, (result) =>
		console.log "list " + JSON.stringify result
		res.send result
		next()


testDelete = (req,res,next)->


#---------------------------------------------------------------------------------------#
# REST Server routine starts here
#---------------------------------------------------------------------------------------#
server = restify.createServer()
server.use(restify.acceptParser(server.acceptable));
server.use(restify.queryParser());
server.use(restify.jsonp());
server.use(restify.bodyParser());


server.post '/Test', testPost
server.get '/Test', testList
server.get '/Test/:id', testGet
server.del '/Test/:id', testDelete

server.listen 5051,()->
    console.log 'testAgent listening on port : 5051.....'