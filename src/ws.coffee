events = require("events")
http = require("http")
crypto = require("crypto")
util = require("util")
URL = require('url')
uuid = require('./uuid')

# opcodes for WebSocket frames
# http://tools.ietf.org/html/rfc6455#section-5.2
opcodes =
  TEXT: 1
  BINARY: 2
  CLOSE: 8
  PING: 9
  PONG: 10

#magic constant to generate handshake
KEY_SUFFIX = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

lowerObjKeys = (obj) ->
  keys = (key for key of obj)
  lkeys = keys.map (key) -> key.toLowerCase()
  resp = {}
  resp[lkeys[index]] = obj[keys[index]] for key, index in keys
  resp

hashWebSocketKey = (key) ->
  sha1 = crypto.createHash("sha1")
  sha1.update key + KEY_SUFFIX, "ascii"
  sha1.digest "base64"

genWebSocketKey = ->
  key = new Buffer(16)
  for _, index in key
    key.writeUInt8 Math.floor(Math.random() * 256), index
  key.toString('base64')

genMask = ->
  mask = new Buffer(4)
  for _, index in mask
    mask.writeUInt8 Math.floor(Math.random() * 256), index
  mask

unmask = (maskBytes, data) ->
  payload = new Buffer(data.length)
  i = 0

  while i < data.length
    payload[i] = maskBytes[i % 4] ^ data[i]
    i++
  payload

encodeMessage = (opcode, payload, useMask = false) ->
  buf = undefined
  mask = undefined
  maskLen = if useMask then 4 else 0

  # first byte: fin and opcode
  b1 = 0x80 | opcode # always send message as one frame (fin)
  
  # second byte: mask and length part 1
  # followed by 0, 2, or 4 additional bytes of continued length
  b2 = if useMask then 0x80 else 0
  length = payload.length

  if useMask
    mask = genMask()
    payload = unmask(mask, payload)

  if length < 126
    buf = new Buffer(payload.length + 2 + 0 + maskLen) # zero extra bytes
    b2 |= length
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    payload.copy(buf, 2 + maskLen)
    mask.copy(buf, 2) if useMask
  else if length < (1 << 16)
    buf = new Buffer(payload.length + 2 + 2 + maskLen) # two bytes extra
    b2 |= 126
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    # add two byte length
    buf.writeUInt16BE length, 2
    payload.copy(buf, 4 + maskLen)
    mask.copy(buf, 4) if useMask
  else
    buf = new Buffer(payload.length + 2 + 8 + maskLen) # eight bytes extra
    b2 |= 127
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    
    # add eight byte length
    # note: this implementation cannot handle lengths greater than 2^32
    # the 32 bit length is prefixed with 0x0000
    buf.writeUInt32BE 0, 2
    buf.writeUInt32BE length, 6
    payload.copy buf, 10 + maskLen
    mask.copy buf, 10 if useMask
  #console.log "Returning this buffer:", buf
  buf

WebSocketClientConnection = (url, options) ->
  parsed_url = URL.parse(url)
  throw new TypeError "URL scheme must be 'ws' or 'wss'" if parsed_url.protocol not in ['ws:', 'wss:']

  self = @

  @options =
    hostname: parsed_url.hostname
    port: parsed_url.port or (if parsed_url.protocol.match /ss/ then 443 else 80)
    path: parsed_url.path or "/"
    headers: {}

  @options.headers.Host = "#{@options.hostname}:#{@options.port}"
  @options.headers.Connection = "Upgrade"
  @options.headers.Upgrade = "websocket"
  @options.headers.Origin = "#{if parsed_url.protocol.match /ss/ then 'https' else 'http'}://#{@options.hostname}:#{@options.port}"
  @options.headers['Sec-WebSocket-Version'] = 13
  @options.headers['Sec-WebSocket-Key'] = genWebSocketKey()
  @options.headers['Sec-WebSocket-Protocol'] = options['Sec-WebSocket-Protocol'] if options?['Sec-WebSocket-Protocol']?
  @options.headers['Sec-WebSocket-Extensions'] = options['Sec-WebSocket-Extensions'] if options?['Sec-WebSocket-Extensions']?

  @request = http.request @options
  @request.on 'upgrade', (response, socket, upgradeHead) ->
    self.socket = socket

    self.socket.on 'error', (err) ->
      console.log 'Client Socket error:', err.message

    self.socket.on "data", (buf) ->
      #console.log "Raw data:", buf
      self.buffer = Buffer.concat([
        self.buffer
        buf
      ])
      # process buffer while it contains complete frames
      continue  while self._processBuffer()
      return

    self.socket.on "close", (had_error) ->
      unless self.closed
        self.emit "close", 1006
        self.closed = true
      return

    self.emit 'open', if self.id then self.id else null

  @request.end()

  @buffer = new Buffer(0)
  @closed = false
  @currentRoundTrip = 0
  return

util.inherits WebSocketClientConnection, events.EventEmitter

Object.defineProperty WebSocketClientConnection::, 'readyState',
  get: -> @socket?.readyState

WebSocketClientConnection::_doSend = (opcode, payload) ->
  @socket?.write encodeMessage(opcode, payload, true)
  return


WebSocketServerConnection = (request, socket, upgradeHead) ->
  self = @

  key = hashWebSocketKey(lowerObjKeys(request.headers)["sec-websocket-key"])

  protocol = (->
    if 'sec-websocket-protocol' of request.headers
      protocols = lowerObjKeys(request.headers)["sec-websocket-protocol"].split /\s*,\s*/
      #console.log "Protocol: #{protocols[0]}"
      return protocols[0]
    else
      return null
  )()

  lines = []

  # handshake response
  # http://tools.ietf.org/html/rfc6455#section-4.2.2
  lines.push "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
  lines.push "Upgrade: WebSocket\r\n"
  lines.push "Connection: Upgrade\r\n"
  lines.push "sec-websocket-accept: #{key}"
  lines.push "\r\nsec-websocket-protocol: #{protocol}" if protocol
  lines.push "\r\n\r\n"

  socket.write lines.join('')

  socket.on 'connect', (evt) ->
    self.emit 'open', if self.id then self.id else null

  socket.on 'error', (err) ->
    console.log 'Server Socket error:', err.message

  socket.on "data", (buf) ->
    self.buffer = Buffer.concat([
      self.buffer
      buf
    ])
    # process buffer while it contains complete frames
    continue  while self._processBuffer()
    return

  
  socket.on "close", (had_error) ->
    unless self.closed
      self.emit "close", 1006
      self.closed = true
    return


  # initialize connection state
  @request = request
  @socket = socket
  @buffer = new Buffer(0)
  @closed = false
  @currentRoundTrip = 0

  return

util.inherits WebSocketServerConnection, events.EventEmitter

Object.defineProperty WebSocketServerConnection::, 'readyState',
  get: -> @socket.readyState

# Ping method
WebSocketClientConnection::ping = WebSocketServerConnection::ping = ->
  @_doSend opcodes.PING, new Buffer(new Date().getTime().toString())

# Send a text or binary message on the WebSocket connection
WebSocketClientConnection::send = WebSocketServerConnection::send = (obj) ->
  opcode = undefined
  payload = undefined
  if Buffer.isBuffer(obj)
    opcode = opcodes.BINARY
    payload = obj
  else if typeof obj is "string"
    opcode = opcodes.TEXT
    # create a new buffer containing the UTF-8 encoded string
    payload = new Buffer(obj, "utf8")
  else
    try
      obj = JSON.stringify obj
      opcode = opcodes.TEXT
      payload = new Buffer(obj, "utf8")
    catch e
      throw new Error("Cannot send object. Must be string or Buffer")
  @_doSend opcode, payload
  return


# Close the WebSocket connection
WebSocketClientConnection::close = WebSocketServerConnection::close = (code, reason) ->
  opcode = opcodes.CLOSE
  buffer = undefined
  
  # encode close and reason
  if code
    buffer = new Buffer(Buffer.byteLength(reason) + 2)
    buffer.writeUInt16BE code, 0
    buffer.write reason, 2
  else
    buffer = new Buffer(0)
  @_doSend opcode, buffer
  @closed = true
  try
    @socket.end()
    @socket.destroy()
  catch e
    console.log "Error while destroying underlying raw socket:", e.message

  return


# Process incoming bytes
WebSocketClientConnection::_processBuffer = WebSocketServerConnection::_processBuffer = ->
  buf = @buffer

  # insufficient data read
  return  if buf.length < 2
  idx = 2
  b1 = buf.readUInt8(0)
  fin = b1 & 0x80
  opcode = b1 & 0x0f # low four bits
  b2 = buf.readUInt8(1)
  mask = b2 & 0x80
  length = b2 & 0x7f # low 7 bits
  if length > 125
    
    # insufficient data read
    return  if buf.length < 8
    if length is 126
      length = buf.readUInt16BE(2)
      idx += 2
    else if length is 127
      # discard high 4 bits because this server cannot handle huge lengths
      highBits = buf.readUInt32BE(2)
      @close 1009, ""  unless highBits is 0
      length = buf.readUInt32BE(6)
      idx += 8
  
  # insufficient data read
  return  if buf.length < (idx + (if mask isnt 0 then 4 else 0) + length)
  if mask isnt 0
    maskBytes = buf.slice(idx, idx + 4)
    idx += 4
  payload = buf.slice(idx, idx + length)
  if mask isnt 0
    payload = unmask(maskBytes, payload)
  @_handleFrame opcode, payload
  @buffer = buf.slice(idx + length)
  true

WebSocketClientConnection::_handleFrame = WebSocketServerConnection::_handleFrame = (opcode, buffer) ->
  payload = undefined
  switch opcode
    when opcodes.TEXT
      payload = buffer.toString("utf8")
      @emit "data", opcode, payload
    when opcodes.BINARY
      payload = buffer
      @emit "data", opcode, payload
    when opcodes.PING
      # respond to pings with pongs
      @_doSend opcodes.PONG, buffer
    # process pongs
    when opcodes.PONG
      #process.stdout.write "\nReceived PONG: #{buffer.toString('utf8')}\n"
      pong_millis = new Date().getTime()
      ping_millis = parseInt(buffer.toString('utf8'))
      @currentRoundTrip = (pong_millis - ping_millis) / 1000
      @emit "heartbeat", @currentRoundTrip, pong_millis
    when opcodes.CLOSE
      # parse close and reason
      code = undefined
      reason = undefined
      if buffer.length >= 2
        code = buffer.readUInt16BE(0)
        reason = buffer.toString("utf8", 2)
      @close code, reason
      @emit "close", code, reason
    else
      @close 1002, "unknown opcode"
      @emit "close", 1002, "unknown opcode"
  return


# Format and send a WebSocket message
WebSocketServerConnection::_doSend = (opcode, payload) ->
  @socket?.write encodeMessage(opcode, payload, false)
  return


WebSocketServer = (handler) ->
  if handler and handler.constructor.name is "Function"
    @connectionHandler = handler
  else
    throw new Error("Must provide a socket handler function to instantiate a WebSocketServer")
  return

util.inherits WebSocketServer, events.EventEmitter

WebSocketServer::listen = (port, host, route = "/") ->
  srv = undefined
  self = @
  switch port.constructor.name
    when "Server"
      srv = port
    when "String"
      srv = http.createServer((request, response) ->
        response.end "websocket server"
        return
      )
      srv.listen port
    when "Number"
      srv = http.createServer((request, response) ->
        response.end "websocket server"
        return
      )
      srv.listen port, (if host then host else "0.0.0.0")
    else
      if port._handle
        srv = port
      else
        throw new TypeError "WebSocketServer only listens on something that has a _handle."

  srv.on 'listening', => @emit 'listening'

  srv.on "upgrade", (request, socket, upgradeHead) ->
    if URL.parse(request.url).path isnt route
      return
      #console.log "websocket out of path, aborting."
      #ws = new WebSocketServerConnection(request, socket, upgradeHead)
      #ws.close()
    else
      ws = new WebSocketServerConnection(request, socket, upgradeHead)
      self.connectionHandler ws
      setTimeout (-> ws.periodicPing = setInterval (-> ws.ping() if ws.readyState is 'open'), 2000), 1000
      ws.on 'close', ->
        #console.log "Closing server websocket connection", ws.id
        clearInterval ws.periodicPing if ws.periodicPing?
      self.emit 'upgrade'

###
# Didn't work because request doesn't register upgrade event. Must be done at server level.
WebSocketServer::listenOnRoute = (router, path, socket_handler_fn = null) ->
  self = @
  socket_handler_fn = socket_handler_fn or self.connectionHandler # use ad-hoc socket handler if provided, else use "default" socket handler
  obj = router.get_route_handler(path, 'get')
  if obj
    http_handler_fn = obj.handler_obj.handler
  else
    http_handler_fn = (request, response) ->
      response.end 'websocket server listening at ' + path
  path = "/#{path}" unless path.charAt(0) is "/"
  router.get path, (request, response) ->
    if request.headers['upgrade'] or request.headers['Upgrade']
      ( (response, socket, upgradeHead) ->
        console.log "Received upgrade request on path: #{request.url}"
        ws = new WebSocketServerConnection(request, socket, upgradeHead)
        socket_handler_fn ws
        setTimeout (-> ws.periodicPing = setInterval (-> ws.ping() if ws.readyState is 'open'), 2000), 1000
        ws.on 'close', ->
          #console.log "Closing server websocket connection", ws.id
          clearInterval ws.periodicPing if ws.periodicPing?
        self.emit 'upgrade')(null, request.socket, '')

    http_handler_fn request, response
###

createWebSocketServer = (socket_handler_fn) ->
  new WebSocketServer(socket_handler_fn)



module?.exports = exports = {createWebSocketServer, WebSocketServer, WebSocketServerConnection, WebSocketClientConnection, opcodes}



#Test to execute when invoked stand-alone.
test = ->
  reverseServer = createWebSocketServer((sock) ->
    sock.on "data", (opcode, data) ->
      sock.send data.split("").reverse().join("")
      return

    return
  )
  reverseServer.listen 8000
  console.log "Reverse WebSocket Server listening on port 8000"
  return


test() unless module?.parent

