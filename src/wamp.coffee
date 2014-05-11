# First shot at WAMP (Web Application Messaging Protocol) implementation.

events = require 'events'
util = require 'util'
net = require 'net'
ws = require './ws'

#Message Constants

MESSAGE_TYPES =
  HELLO: 1
  WELCOME: 2
  ABORT: 3
  CHALLENGE: 4
  AUTHENTICATE: 5
  GOODBYE: 6
  HEARTBEAT: 7
  ERROR: 8
  PUBLISH: 16
  PUBLISHED: 17
  SUBSCRIBE: 32
  SUBSCRIBED: 33
  UNSUBSCRIBE: 34
  UNSUBSCRIBED: 35
  EVENT: 36
  CALL: 48
  CANCEL: 49
  RESULT: 50
  REGISTER: 64
  REGISTERED: 65
  UNREGISTER: 66
  UNREGISTERED: 67
  INVOCATION: 68
  INTERRUPT: 69
  YIELD: 70

#End of Message Constants

#Transport constants

TRANSPORT_TYPES =
  DIRECT: 1
  WEBSOCKET: 2
  UNIXSOCKET: 3

#End of Transport constants

MAX_ID = 2 ** 53

isValidURI = (uri_string) -> !!uri_string.match(/^(([0-9a-z_]{2,}\.)|\.)*([0-9a-z_]{2,})?$/)

randomNum = (len) ->
  parseInt ((Math.floor(Math.random() * 10)).toString() for n in [1..len]).join('')

genId = ->
  randomNum 15

###
class WampSession extends events.EventEmitter
  constructor: (@id, options) ->
    @_options = options or {}
    for key, val of @_options
      @[key] = val
    @nextId = 1
###

class WampPeer extends events.EventEmitter
  "Peer at one end of Wamp Session. Involves acting as a session itself, as well"

  constructor: (@parent, @transport, @roles, options) ->
    @isOpen = true
    @transport.on 'close', (code) =>
      @isOpen = false
      console.log "Closing WampPeer due to transport closed."
    @id = null
    @nextId = 1
    @setOptions options

  setOptions: (options) =>
    @_options = options or {}
    for key, val of @_options
      @[key] = val

  sendMessage: (message) =>
    @transport.send(message) if @isOpen

  processMessage: (message) =>
    return unless @isOpen
    arr = JSON.parse message
    [code] = arr
    if code not in [MESSAGE_TYPES.HELLO, MESSAGE_TYPES.WELCOME]
      return unless @id
    switch code
      when MESSAGE_TYPES.HELLO
        console.log "Router received HELLO message"
        [realm, details] = arr.slice(1)
        #@session = new WampSession @parent.nextSessionId, {peer: @, realm, details}
        @id = @parent.nextSessionId
        @realm = realm
        @setOptions details
        @parent.realms[realm] = {sessions: [], registered_procedures: [], invocations: [], subscriptions: {}} unless realm of @parent.realms
        @parent.realms[realm].sessions.push @
        console.log "@realms[#{realm}].sessions.length: %d", @parent.realms[realm].sessions.length
        @sendMessage JSON.stringify [MESSAGE_TYPES.WELCOME, @parent.nextSessionId, {roles: @roles}]
        console.log "Router sent WELCOME message to #{@parent.nextSessionId}"
        @parent.nextSessionId += 1
      when MESSAGE_TYPES.WELCOME
        console.log "Received Welcome Message"
      when MESSAGE_TYPES.ABORT
        console.log "Received Abort Message"
      when MESSAGE_TYPES.CHALLENGE
        console.log "Received Challenge Message"
      when MESSAGE_TYPES.AUTHENTICATE
        console.log "Received Authenticate Message"
      when MESSAGE_TYPES.GOODBYE
        @sendMessage message
        sessions = @parent.realms?[@realm].sessions
        if sessions
          for session, index in sessions
            if session.id is @id
              @parent.realms[@realm].sessions.splice(index, 1)
              break
        #@isOpen = false
        @transport.close()
      when MESSAGE_TYPES.HEARTBEAT
        console.log "Received HeartBeat Message"
      when MESSAGE_TYPES.PUBLISH
        #console.log "Received publish message from session #{@id}"
        [RequestId, OptionsDict, TopicUri, ArgumentsList, ArgumentsKwDict] = arr.slice(1)
        PublicationId = @nextId
        @nextId += 1
        topic = @parent.realms[@realm].subscriptions[TopicUri]
        if topic
          for suscription in topic
            for session in @parent.realms[@realm].sessions
              if session.id is suscription.sessionId
                msgArray = [MESSAGE_TYPES.EVENT, suscription.SubscriptionId, PublicationId, OptionsDict]
                msgArray.push ArgumentsList if ArgumentsList
                msgArray.push ArgumentsKwDict if ArgumentsKwDict
                session.sendMessage JSON.stringify(msgArray)
                break
        if OptionsDict.acknowledge
          @sendMessage(JSON.stringify [MESSAGE_TYPES.PUBLISHED, RequestId, PublicationId])
      when MESSAGE_TYPES.PUBLISHED
        console.log "Received Published Message"
      when MESSAGE_TYPES.SUBSCRIBE
        console.log "Received subscribe message from session #{@id}"
        [RequestId, OptionsDict, TopicUri] = arr.slice(1)
        SubscriptionId = @nextId
        @nextId += 1
        @parent.realms[@realm].subscriptions[TopicUri] = [] if not @parent.realms[@realm].subscriptions[TopicUri]
        @parent.realms[@realm].subscriptions[TopicUri].push {
        sessionId: @id
        SubscriptionId
        OptionsDict
        }
        resp = [MESSAGE_TYPES.SUBSCRIBED, RequestId, SubscriptionId]
        @sendMessage(JSON.stringify resp)
        console.log "Registered subscription for #{TopicUri} in realm #{@realm}"
      when MESSAGE_TYPES.SUBSCRIBED
        console.log "Received Subscribed Message"
      when MESSAGE_TYPES.UNSUBSCRIBE
        [RequestId, SubscriptionId] = arr.slice(1)
        console.log "Received unsubscribe message from session #{@id} with requestId: #{RequestId} and subscriptionId: #{SubscriptionId}"
        for key, topic of @parent.realms[@realm].subscriptions
          for subscription, index in topic
            if (subscription.SubscriptionId is SubscriptionId) and (subscription.sessionId is @id)
              console.log "Found subscription to erase at index #{index}. Going to do it for request: #{RequestId}"
              topic.splice(index, 1)
              return @sendMessage JSON.stringify([MESSAGE_TYPES.UNSUBSCRIBED, RequestId])
        console.log "Did not find a subscription to erase. Sending error message: 'wamp.error.no_such_subscription'"
        return @sendMessage JSON.stringify([MESSAGE_TYPES.ERROR, MESSAGE_TYPES.UNSUBSCRIBE, RequestId, {}, "wamp.error.no_such_subscription"])
      when MESSAGE_TYPES.UNSUBSCRIBED
        console.log "Received Unsubscribed Message"
      when MESSAGE_TYPES.EVENT
        console.log "Received Event Message"
      when MESSAGE_TYPES.CALL
        console.log "Received Call Message from session #{@id} with request Id = #{arr[1]}"
        [RequestId, OptionsDict, ProcedureUri, ArgumentsList, ArgumentsKwDict] = arr.slice(1)
        for proc in @parent.realms[@realm].registered_procedures
          if proc.ProcedureUri is ProcedureUri
            callee_sessionId = proc.sessionId
            registrationId = proc.RegistrationId
            for session in @parent.realms[@realm].sessions
              if session.id is callee_sessionId
                callee_session = session
                #requestId = @session.nextId
                #@session.nextId += 1
                invocation_message = [
                  MESSAGE_TYPES.INVOCATION,
                  RequestId,
                  registrationId,
                  OptionsDict,
                  ArgumentsList or [],
                  ArgumentsKwDict or {}
                ]
                @parent.realms[@realm].invocations.push {
                  sessionId: @id
                  requestId: RequestId
                }
                return callee_session.sendMessage(JSON.stringify invocation_message)
      when MESSAGE_TYPES.CANCEL
        console.log "Received Cancel Message"
      when MESSAGE_TYPES.RESULT
        console.log "Received Result Message"
      when MESSAGE_TYPES.REGISTER
        console.log "Received register message from session #{@id}"
        [RequestId, OptionsDict, ProcedureUri] = arr.slice(1)
        RegistrationId = @nextId
        @nextId += 1
        @parent.realms[@realm].registered_procedures.push {
          sessionId: @id
          RegistrationId
          OptionsDict
          ProcedureUri
        }
        resp = [MESSAGE_TYPES.REGISTERED, RequestId, RegistrationId]
        @sendMessage(JSON.stringify resp)
        console.log "Registered procedure #{ProcedureUri} in realm #{@realm}"
      when MESSAGE_TYPES.REGISTERED
        console.log "Received Registered Message"
      when MESSAGE_TYPES.UNREGISTER
        console.log "Received Unregister Message"
      when MESSAGE_TYPES.UNREGISTERED
        console.log "Received Unregistered Message"
      when MESSAGE_TYPES.INVOCATION
        console.log "Received Invocation Message"
      when MESSAGE_TYPES.INTERRUPT
        console.log "Received Interrupt Message"
      when MESSAGE_TYPES.YIELD
        console.log "Received Yield Message from session #{@id}"
        [RequestId, OptionsDict, ArgumentsList, ArgumentsKwDict] = arr.slice(1)
        console.log "Yield message data\nRequestId: #{RequestId}"
        console.log "OptionsDict: %j", OptionsDict
        console.log "ArgumentsList: #{ArgumentsList}"
        console.log "ArgumentsKwDict: #{ArgumentsKwDict}"
        for invocation in @parent.realms[@realm].invocations
          if invocation.requestId is RequestId
            caller_sessionId = invocation.sessionId
            for session in @parent.realms[@realm].sessions
              if session.id is caller_sessionId
                caller_session = session
                result_message = [
                  MESSAGE_TYPES.RESULT,
                  RequestId,
                  OptionsDict,
                  ArgumentsList or [],
                  ArgumentsKwDict or {}
                ]
                console.log "Sending results to session #{caller_session.id} corresponding to request Id: #{RequestId}"
                return caller_session.sendMessage(JSON.stringify result_message)
      else
        console.log "Unknown code received."


class WampClient extends events.EventEmitter


class WampRouter extends events.EventEmitter
  _webSocketHandler: (websocket) =>
    websocket.peer = new WampPeer @, websocket, @roles
    websocket.on 'open', =>
      console.log "WebSocket opened"
    websocket.on 'data', (opcode, data) =>
      websocket.peer.processMessage(data)
    websocket.on 'close', (wasClean, code, reason) =>
      console.log "Websocket closed. Close event data:\n wasClean: #{wasClean or 'no data'} - Code: #{code or 'no data'} - Reason: #{reason or 'no data'}"

  constructor: (options) ->
    @_options = options or {}
    @roles = @_options.roles or {broker: {}, dealer: {}}

    @nextSessionId = genId()
    @realms = {}

    @webSocketServer = ws.createWebSocketServer(@_webSocketHandler)

   listen: (port, host = '0.0.0.0', route = '/wamp') =>
     @webSocketServer.listen port, host, route


createWampRouter = ->
  new WampRouter


test = ->
  wampRouter = createWampRouter()
  wampRouter.listen 8000, '0.0.0.0', '/'
  console.log "WAMP Router listening on port 8000"


module?.exports = {MESSAGE_TYPES, TRANSPORT_TYPES, WampPeer, WampClient, WampRouter, createWampRouter}

test() if not module?.parent

