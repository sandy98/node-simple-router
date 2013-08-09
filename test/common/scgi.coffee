#!/usr/bin/env coffee

try
  Router = require 'node-simple-router'
catch e
  Router = require '../lib/router'


http = require 'http'
router = Router(list_dir: true)

#
#Example routes
#
router.get "/", (request, response) ->
  response.writeHead 200, 'Content-Type': 'text/html'
  response.end '<title>Home Page</title><div style="text-align: center;">Home, sweet home..</div>'

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
