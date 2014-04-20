events = require("events")
http = require("http")
crypto = require("crypto")
util = require("util")

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

unmask = (maskBytes, data) ->
  payload = new Buffer(data.length)
  i = 0

  while i < data.length
    payload[i] = maskBytes[i % 4] ^ data[i]
    i++
  payload

encodeMessage = (opcode, payload) ->
  buf = undefined
  
  # first byte: fin and opcode
  b1 = 0x80 | opcode # always send message as one frame (fin)
  
  # second byte: maks and length part 1
  # followed by 0, 2, or 4 additional bytes of continued length
  b2 = 0 # server does not mask frames
  length = payload.length
  if length < 126
    buf = new Buffer(payload.length + 2 + 0) # zero extra bytes
    b2 |= length
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    payload.copy buf, 2
  else if length < (1 << 16)
    buf = new Buffer(payload.length + 2 + 2) # two bytes extra
    b2 |= 126
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    # add two byte length
    buf.writeUInt16BE length, 2
    payload.copy buf, 4
  else
    buf = new Buffer(payload.length + 2 + 8) # eight bytes extra
    b2 |= 127
    buf.writeUInt8 b1, 0
    buf.writeUInt8 b2, 1
    
    # add eight byte length
    # note: this implementation cannot handle lengths greater than 2^32
    # the 32 bit length is prefixed with 0x0000
    buf.writeUInt32BE 0, 2
    buf.writeUInt32BE length, 6
    payload.copy buf, 10
  #console.log "Returning this buffer:", buf
  buf


WebSocketConnection = (req, socket, upgradeHead) ->
  self = this
  key = hashWebSocketKey(lowerObjKeys(req.headers)["sec-websocket-key"])
  
  # handshake response
  # http://tools.ietf.org/html/rfc6455#section-4.2.2
  socket.write "HTTP/1.1 101 Web Socket Protocol Handshake\r\n" + "Upgrade: WebSocket\r\n" + "Connection: Upgrade\r\n" + "sec-websocket-accept: " + key + "\r\n\r\n"
  socket.on "data", (buf) ->
    self.buffer = Buffer.concat([
      self.buffer
      buf
    ])
    continue  while self._processBuffer()
    return

  
  # process buffer while it contains complete frames
  socket.on "close", (had_error) ->
    unless self.closed
      self.emit "close", 1006
      self.closed = true
    return

  
  # initialize connection state
  @request = req
  @socket = socket
  @buffer = new Buffer(0)
  @closed = false
  @currentRoundTrip = 0
  return

util.inherits WebSocketConnection, events.EventEmitter

Object.defineProperty WebSocketConnection::, 'readyState',
  get: -> @socket.readyState

# Ping method
WebSocketConnection::ping = ->
  @_doSend opcodes.PING, new Buffer(new Date().getTime().toString())

# Send a text or binary message on the WebSocket connection
WebSocketConnection::send = (obj) ->
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
WebSocketConnection::close = (code, reason) ->
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
  return


# Process incoming bytes
WebSocketConnection::_processBuffer = ->
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
  return  if buf.length < idx + 4 + length
  maskBytes = buf.slice(idx, idx + 4)
  idx += 4
  payload = buf.slice(idx, idx + length)
  payload = unmask(maskBytes, payload)
  @_handleFrame opcode, payload
  @buffer = buf.slice(idx + length)
  true

WebSocketConnection::_handleFrame = (opcode, buffer) ->
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
WebSocketConnection::_doSend = (opcode, payload) ->
  @socket.write encodeMessage(opcode, payload)
  return


WebSocketServer = (handler) ->
  if handler and handler.constructor.name is "Function"
    @connectionHandler = handler
  else
    throw new Error("Must provide a socket handler function to instantiate a WebSocketServer")
  return

WebSocketServer::listen = (port, host) ->
  srv = undefined
  self = this
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
        
  srv.on "upgrade", (req, socket, upgradeHead) ->
    ws = new WebSocketConnection(req, socket, upgradeHead)
    self.connectionHandler ws
    setTimeout (-> setInterval (-> ws.ping()), 2000), 1000
    return

  return

createWebSocketServer = (handler) ->
  new WebSocketServer(handler)



module?.exports = exports = {createWebSocketServer, WebSocketServer, WebSocketConnection, opcodes}



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

