#!/usr/bin/env coffee

Router = require '../src/router'

http = require 'http'
router = Router(list_dir: true)
#
#Example routes
#

router.get "/hello", (req, res) ->
 res.end 'Hello, World!, Hola, Mundo!'

router.get "/users", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end '<h1 style="color: navy; text-align: center;">Active members registry</h1>'

router.get "/users/:id", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end "<h1>User No: <span style='color: red;'>" + req.params.id + "</span></h1>"

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
