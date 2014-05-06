# First shot at WAMP (Web Application Messaging Protocol) implementation.

events = require 'events'
util = require 'util'
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

class WampRouter extends events.EventEmitter

  _wsockHandler: (wsock) =>
    wsock.transport = 'websocket'
    @connections[@nextSessionId.toString()] = wsock
    wsock.on 'open', (evt) =>
      #console.log 'server socket opened.'
    wsock.on 'data', (opcode, data) =>
      console.log "Server going to process message:", data
      @processMessage wsock, wsock.transport, data
    wsock.on 'close', (evt) =>
      delete @connections[wsock.id]
      #console.log "Socket closed with following data\nwasClean: #{evt?.wasClean}, code: #{evt?.code}, reason: #{evt?.reason}"
    #wsock.send "Welcome! " + (Math.floor(Math.random() * 100) + 1) if wsock.readyState is 'open'

  constructor: (options) ->
    @options = options or {}
    for key, value of @options
      @[key] = value
    @realms = {} if not @realms
    #console.log "Realms: %j", @realms
    @roles = {broker: {}, dealer: {}} if not @roles
    @nextSessionId = genId()
    @connections = {}
    @webSocketServer = new ws.WebSocketServer @_wsockHandler
    @webSocketServer.on 'listening', => @emit 'listening'

  listen: () =>
    ws.WebSocketServer::listen.apply @webSocketServer, Array::slice.call(arguments)

  processMessage: (peer, transport, message) =>
    #@sendMessage peer, transport, message
    arr = JSON.parse message
    [code] = arr
    switch code
      when HELLO
        console.log "Router received HELLO"
        [realm, details] = arr.slice(1)
        session = {id: @nextSessionId, peer, details}
        @realms[realm] = {sessions: []} unless realm of @realms
        @realms[realm].sessions.push session
        console.log "@realms[#{realm}].sessions.length: %d", @realms[realm].sessions.length
        @sendMessage peer, transport, JSON.stringify [WELCOME, @nextSessionId, {roles: @roles}]
        @nextSessionId += 1
      else
        console.log "Unknown code received."


  sendMessage: (peer, transport, message) =>
    if transport is 'websocket'
      #return peer.send message.split('').reverse().join('')
      return peer.send message
    if transport is 'unixsocket'
      #return peer.send message.split('').reverse().join('')
      return peer.write new Buffer "#{message}\r\n", "utf8"
    if transport is 'direct'
      #console.log "Going to call processMessage of peer with %s", message
      return peer.processMessage @, 'direct', message


class WampClient

  constructor: (options) ->
    @options = options or {}
    for key, value of @options
      @[key] = value
    throw new Error "An URL or a unix socket or a WAMP router instance must be provided for the client to connect" if (not @url) and (not @router) and (not @unixsocket)
    throw new Error "Must provide either URL or unix socket or a WAMP router instance, but not more than one of them" if (@url and @router) or (@url and @unixsocket) or (@unixsocket and @router)
    throw new Error "A realm must be provided for the client to attach to" if not @realm
    @transport = if @url then 'websocket' else if @router then 'direct' else 'unixsocket'
    @roles = {publisher: {}, subscriber: {}, caller: {}, callee: {}} if not @roles
    if @transport is 'websocket'
      #console.log "WampClient using webSocket"
      @webSocket = new ws.WebSocketClientConnection @url, 'Sec-WebSocket-Protocol': 'wamp.2.json'
      @webSocket.on 'data', (opcode, data) =>
        @processMessage @webSocket, 'websocket', data


  open: =>
    peer = @webSocket or @router or @unixsocket
    @sendMessage peer, @transport, JSON.stringify [HELLO, @realm, {roles: @roles}]


  processMessage: (peer, transport, message) =>
    arr = JSON.parse message
    [code] = arr
    switch code
      when WELCOME
        console.log "Client received Welcome"
        [id, details] = arr.slice(1)
        @session = {id, peer, details}
        @onopen? @session
      else
        console.log "Unknown code received."

  sendMessage: (peer, transport, message) =>
    if transport is 'websocket'
      #console.log "sendMessage:", message
      return peer.send message
    if transport is 'unixsocket'
      return peer.write new Buffer "#{message}\r\n", "utf8"
    if transport is 'direct'
      return peer.processMessage @, 'direct', message



test = ->
  wampRouter = new WampRouter
  console.log "WAMP Router listening on port 8000"
  wampRouter.listen 8000

  wampRouter.on 'listening', ->
    client1 = new WampClient router: wampRouter, realm: 'test'
    client1.onopen = (session) ->
      console.log "Direct client opened session."
    client1.open()

    client2 = new WampClient url: 'ws://0.0.0.0:8000', realm: 'test'
    client2.onopen = (session) ->
      console.log "WebSocket client opened session:"
    client2.open()

module?.exports = {WampRouter, WampClient}


test() if not module?.parent

