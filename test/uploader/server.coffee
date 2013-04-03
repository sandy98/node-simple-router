#!/usr/bin/env coffee

fs = require 'fs'

#Err... sorry for the monkey patching ;-)
String.prototype.repeat = String.prototype.repeat or (times) ->
  (@ for n in [1..times]).join('')

   
###
try
  Router = require 'node-simple-router'
catch e
  Router = require '../lib/router'
###

Router = require '../../src/router'

http = require 'http'
router = Router(list_dir: true)
#
#Example routes
#

router.post "/upload", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  if req.post['multipart-data']
    res.write "<h2>Multipart Data</h2>"
    for part in req.post['multipart-data']
      for key, val of part
        if key isnt 'fileData'
          res.write "#{key.toUpperCase()} = #{val}<br/>"
      if part.fileName
        fullname = "#{__dirname}/public/uploads/#{part.fileName}"
        router.log "BUFFER:", part.fileData
        fs.writeFileSync fullname, part.fileData
        res.write '<div style="text-align:center; padding: 1em; border: 1px solid; border-radius: 5px;">'
        if part.contentType.indexOf('image') >= 0
          res.write "<img src='uploads/#{part.fileName}' />"
        else
          res.write "<pre>#{part.fileData}</pre>"
        res.write '</div>' 
      res.write "<hr/>"
  else
    res.write "<h2>Form Data</h2>"
    res.write "#{JSON.stringify(req.post)}<br/><hr/>"

  res.end """
          <div style="text-align: center;"><button onclick="history.back();">Back</button></div>
	      """ 

  #router.log "Someone is trying to upload something"
  
  ###
  for key, val of req.post
    console.log "@#{key.toUpperCase().replace('\n', '#')}@ === #{val.replace('\n','|')}"
    console.log "\n\n\n"
  
  router.log "Request IP: #{req.connection.remoteAddress}"
  router.log "Request URL: #{req.url}"
  router.log "Request headers:\n#{JSON.stringify req.headers}\n\n"
  router.log "Request content-type: #{req.headers['content-type']  or 'content-type not found'}"
  router.log "#".repeat 20
  router.log "Raw Request data:"
  router.log "=".repeat 100
  router.log JSON.stringify req.post
  router.log "=".repeat 100
  router.log "Request data:"
  router.log "=".repeat 100
  body = ""
  for key, val of req.post
    body += val
  for line in body.split('\r\n')
    router.log line
    router.log "#".repeat 20
  router.log "=".repeat 100
  ###
      
#
#End of example routes
#



#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

server.on 'listening', ->
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at " + addr.address + ":" + addr.port  

process.on "SIGINT", ->
  server.close()
  router.log ' '
  router.log "Server shutting up..."
  router.log ' '
  process.exit 0

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000
