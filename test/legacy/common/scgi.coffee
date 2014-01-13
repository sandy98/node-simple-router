#!/usr/bin/env coffee

Router = require '../../src/router'

spawn = require('child_process').spawn
domain = require 'domain'
querystring = require 'querystring'
net = require 'net'
http = require 'http'
router = Router(list_dir: true)
fs = require 'fs'

#
#Example routes
#

router.get "/", (request, response) ->
  router.scgi_pass '/tmp/hello_scgi_py.sk', request, response

router.get "/hellonode", (request, response) ->
  router.scgi_pass '/tmp/node_scgi.sk', request, response
      
#
#End of example routes
#


#Ok, just start the server!

#console.log __dirname


childPath = "#{__dirname}/public/scgi/hellonode/hello.coffee"
if fs.existsSync childPath
  router.log "Going to spawn child #{childPath}"
  child = spawn childPath, []
  child.stdout.pipe process.stdout

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
