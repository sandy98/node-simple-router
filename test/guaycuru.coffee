#!/usr/bin/env coffee

Router = require 'node-simple-router'
http   = require 'http'

router = Router({static_route: process.cwd(), served_by: "Guaycuru Web Server", version: '0.0.1'})
router.log "Working directory: #{router.static_route}"

server = http.createServer router
argv = process.argv.slice 2
server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000

addr = server?.address() or {address: '0.0.0.0', port: argv[0] or 8000}

router.log "Serving web content at #{addr.address}:#{addr.port}"

process.on "SIGINT", ->
  server.close()
  router.log "\n Server shutting up...\n"
  process.exit 0


