# First shot at WAMP (Web Application Messaging Protocol) implementation.

ws = require './ws'

class WampServer extends ws.WebSocketServer





test = ->
  wampServer = new WampServer (wsock) ->
    wsock.send "Welcome! " + (Math.floor(Math.random() * 100) + 1)

  console.log "WAMP Server listening on port 8000"
  wampServer.listen 8000

module?.exports = {WampServer}


test() if not module?.parent