#!/usr/bin/env coffee

try 
  Router = require '../../src/router'
catch e
  Router = require '../../lib/router'
  
http = require 'http'

router = Router(list_dir: true)

###
Example routes
###

#router.get "/", (req, res) ->
#  res.end "Home"

router.get "/hello", (req, res) ->
  res.end "Hello, World!, Hola, Mundo!"

router.get "/users", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end "<h1 style='color: navy; text-align: center;'>Active members registry</h1>"


router.post "/users", (req, res) ->
  router.log "\n\nBody of request is: #{req.body.toString()}\nRequest content type is: #{req.headers['content-type']}"
  router.log "\nRequest Headers"
  router.log "#{key} = #{val}" for key, val of req.headers
  router.log "\nRequest body object properties"
  res.write "\nRequest body object properties\n"
  try
    router.log "#{key}: #{val}" for key, val of req.body
  catch e
    res.write "Looks like you did something dumb: #{e.toString()}\n"
  for key, val of req.body
    res.write "#{key} = #{val}\n"
  res.end()

router.get "/users/:id", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end "<h1>User No: <span style='color: red;'>#{req.params.id}</span></h1>"

router.get "/crashit", (req, res) ->
  throw new Error("Crashed on purpose...")

###
End of example routes
###

#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

server.on 'listening', ->
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at #{addr.address}:#{addr.port}"
      
process.on "SIGINT", ->
  server.close()
  router.log "\n Server shutting up...\n"
  process.exit 0

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000


