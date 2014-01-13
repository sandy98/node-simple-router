#!/usr/bin/env coffee

fs = require 'fs'

fs.mkdirSync 'public/uploads' unless fs.existsSync 'public/uploads'

#Err... sorry for the monkey patching ;-)
String.prototype.repeat = String.prototype.repeat or (times) ->
  (@ for n in [1..times]).join('')


try   
  Router = require '../../src/router'
catch e
  Router = require '../../lib/router'
  
http = require 'http'
router = Router(list_dir: true)

router.post "/upload", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  if req.post['multipart-data']
    res.write "<h2>Multipart Data</h2>"
    for part in req.post['multipart-data']
      for key, val of part
          res.write "#{key} = #{val}<br/>" unless ((key is 'fileData') and part.fileName)
      if part.fileName
        fullname = "#{__dirname}/public/uploads/#{part.fileName}"
        #router.log "BUFFER:", part.fileData
        #router.log "First char (hex):", new Buffer(part.fileData)[0]
        if part.contentType.indexOf('text') >= 0
          fs.writeFileSync fullname, part.fileData
        else
          #buffer = new Buffer(part.fileData, 'binary')
          #fs.writeFileSync fullname, buffer, 'binary'
          fs.writeFileSync fullname, part.fileData, 'binary'
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
