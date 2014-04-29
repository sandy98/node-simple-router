# First shot at WAMP (Web Application Messaging Protocol) implementation.

ws = require './ws'

#Message Constants

HELLO	= 1
WELCOME = 2
ABORT	= 3
CHALLENGE = 4
AUTHENTICATE = 5
GOODBYE = 6
HEARTBEAT = 7
ERROR = 8
PUBLISH = 16
PUBLISHED = 17
SUBSCRIBE = 32
SUBSCRIBED = 33
UNSUBSCRIBE = 34
UNSUBSCRIBED = 35
EVENT = 36
CALL = 48
CANCEL = 49
RESULT = 50
REGISTER = 64
REGISTERED = 65
UNREGISTER = 66
UNREGISTERED = 67
INVOCATION = 68
INTERRUPT = 69
YIELD = 70

#End of Message Constants

isValidURI = (uri_string) -> !!uri_string.match(/^(([0-9a-z_]{2,}\.)|\.)*([0-9a-z_]{2,})?$/)

randomNum = (len) ->
  parseInt ((Math.floor(Math.random() * 10)).toString() for n in [1..len]).join('')

genId = ->
  randomNum 15

class WampRouter

  _wsockHandler: (wsock) =>
    wsock.id = @nextSessionId.toString()
    wsock.transport = 'websocket'
    @connections[@nextSessionId.toString()] = wsock
    @nextSessionId += 1
    wsock.on 'open', (evt) =>
      console.log 'server socket opened.'
    wsock.on 'data', (opcode, data) =>
      @processMessage wsock, wsock.transport, data
    wsock.on 'close', (evt) =>
      delete @connections[wsock.id]
      console.log "Socket closed with following data\nwasClean: #{evt?.wasClean}, code: #{evt?.code}, reason: #{evt?.reason}"
    wsock.send "Welcome! " + (Math.floor(Math.random() * 100) + 1) if wsock.readyState is 'open'

  constructor: ->
    @realms = {}
    @nextSessionId = genId()
    @connections = {}
    @webSocketServer = new ws.WebSocketServer @_wsockHandler

  listen: () =>
    ws.WebSocketServer::listen.apply @webSocketServer, Array::slice.call(arguments)

  processMessage: (transmitter, transport, data) =>
    @sendMessage transmitter, transport, data

  sendMessage: (transmitter, transport, data) =>
    if transport is 'websocket'
      return transmitter.send data.split('').reverse().join('')
    if transport is 'direct'
      return transmitter.processMessage @, 'direct', data


class WampClient

  constructor: (@options) ->
    for key, val of @options
      @[key] = value
    raise new Error "An URL or a WAMP router instance must be provided for the client to connect" if (not @url) and not (@router)
    raise new Error "Must provide either URL or a WAMP router instance, but not both" if @url and @router
    raise new Error "A realm must be provided for the client to attach to" if not @realm
    @transport = if @url then 'websocket' else 'direct'
    @roles = {publisher: {}, subscriber: {}, caller: {}, callee: {}} if not @roles
    if @transport is 'websocket'
      @webSocket = new ws.WebsocketClientConnection @url, 'Sec-WebSocket-Protocol': 'wamp.2.json'
      @webSocket.on 'data', (opcode, data) =>
        @processMessage data

  processMessage: (data) =>

  sendMessage: (message) =>



test = ->
  wampRouter = new WampRouter
  console.log "WAMP Router listening on port 8000"
  wampRouter.listen 8000

module?.exports = {WampRouter, WampClient}


test() if not module?.parent

