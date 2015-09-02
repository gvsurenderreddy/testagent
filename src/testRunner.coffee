util = require 'util'
exec = require('child_process').exec

class testrunner
    execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
            util.log "Execution- Error : " + error
            #util.log "Ping - stdout : " + stdout
            util.log "Execution - stderr : " + stderr
            if error
                callback error
            else
                callback stdout   
    runCommand : (command,callback) ->
        @execute command,(result) => 
            return callback result

module.exports = new testrunner
