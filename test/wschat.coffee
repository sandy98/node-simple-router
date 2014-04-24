# Beginning of websocket specific section.

net = require 'net'

try
  ws = require '../src/ws'
  router = require('../src/router')()
catch e
  try
    ws = require '../lib/ws'
    router = require('../lib/router')()
  catch e2
    console.log 'node-simple-router must be installed for this to work'
    process.exit(-1)

socks = []
msgs = []

setKey = (sock, key, value) ->
  sock[key] = value

broadcastMsg = (msg) ->
  for sock in socks
    try
      sock.send msg if sock.readyState is 'open'
    catch e
      console.log "Error sending data to clients: #{e.message}"

  
broadcastChattersList = () ->
  lsocks = ({id: sock.id, color: sock.color, username: sock.username, currentRoundTrip: sock.currentRoundTrip} for sock in socks when sock.username)
  for sock in socks
    try
      sock.send(headers: {command: 'chatters-list', subcommand: 'init'}, body: lsocks) if sock.readyState is 'open'
    catch e
      console.log "Error sending data to clients: #{e.message}"

processMessage = (sock, msg) ->
  headers = msg.headers
  body = msg.body
  msgCommand = headers.command
  switch msgCommand
    when 'chat-message'
      broadcastMsg(msg)
    when 'set'
      key = headers.key
      value = body
      setKey(sock, key, value)
      if key is 'username'
        setImmediate ->
          broadcastMsg headers: server_chat_headers, body: "Say hi to #{value} who has joined the chat."
          broadcastChattersList()
      #if key is 'color'
      #  setImmdiate ->
      #    broadcastChattersList()
    when 'reset-color'
      key = 'color'
      value = getRandomRGB()
      setKey(sock, key, value)
      sock.send headers: {command: 'set', key: key}, body: value
      broadcastChattersList()
    else
      console.log("Received an unrecognized message: " + body)

getRandomRGB = ->
  red = Math.floor(Math.random() * 128) + 64
  green = Math.floor(Math.random() * 128) + 64
  blue = Math.floor(Math.random() * 128) + 64
  [red, green, blue] = [red, green, blue].map (color) ->
     color.toString(16).replace('0x', '')
  "##{red}#{green}#{blue}"
    
send_oldmsgs = (sock) ->
  for msg in msgs
    msg = JSON.parse msg
    sock.send msg #if msg.headers.command is 'chat-message'

garbage_collect = () ->
  for sock, index in socks
    if not sock.username
      socks.splice index, 1
      return broadcastChattersList()

server_chat_headers = from: 'SERVER', color: '#dd0000', command: 'chat-message'

wsserver = ws.createWebSocketServer (websock) ->
  nsr_sid = router.utils.getCookie(websock.request, 'nsr_sid').nsr_sid
  websock.id = if nsr_sid then "nsr-#{nsr_sid}--#{router.utils.uuid()}" else router.utils.uuid()
  websock.color = getRandomRGB()
  socks.push websock
  init_websock = (ws) ->
    setTimeout ( ->
      if (ws.readyState isnt 'open') and (ws.readyState isnt 'closed')
        console.log "websocket isnt ready to be initialized. Rescheduling..."
        return init_websock(ws)
      if ws.readyState isnt 'closed'
        headers = command: 'set', key: 'id'
        body = ws.id
        ws.send {headers, body}
        headers.key = 'color'
        body = ws.color
        ws.send {headers, body}
        send_oldmsgs(ws)
    ), 100
  init_websock websock
  #garbage_interval = setInterval garbage_collect, 1000
    
  websock.on 'data', (opcode, data) ->
    #console.log "Received from web client opcode: #{opcode} with data #{data}"
    parsed_data = JSON.parse data
    msgs.push data if parsed_data.headers.command is 'chat-message'
    processMessage websock, parsed_data

  websock.on 'heartbeat', (currentRoundTrip, currentTime) ->
    #console.log "Current roundtrip for websock #{websock.id}: #{currentRoundTrip}"
    broadcastChattersList()
    
  websock.on 'close', (code, reason) ->
    if websock.username
      setImmediate ->
        broadcastMsg headers: server_chat_headers, body: "#{websock.username} has left the chat."
        broadcastChattersList()
    for sock, index in socks
      if socks[index]?.id is websock.id
        socks.splice index, 1
    console.log "web socket closed with code #{if code then code else 'none'} owed to #{if reason then reason else 'no reason provided'}"


createProxy = (port) ->
  proxyServer = net.createServer (sock) ->
    console.log "Server raw socket connected."
    wsock = new ws.WebSocketClientConnection("ws://0.0.0.0:#{port + 1}")
    wsock.color = "#000000"

    wsock.on 'close', (code) ->
      console.log "Proxy WebSocket closed with code:", code

    wsock.on 'data', (opcode, data) ->
      #console.log "Received from web client opcode: #{opcode} with data #{data}"
      msg = JSON.parse data
      headers = msg.headers;
      body = msg.body;
      msgCommand = headers.command;
      if msgCommand is 'chat-message'
        sock.write "#{headers.from.replace(/\r/g, '').replace(/\n/g, '')}: #{body}\r\n", "utf8"
      if msgCommand is 'set'
        wsock[headers.key] = body

    sock.on 'error', (err) ->
      console.log "Error on raw socket:", err.message
      sock.destroy()

    sock.on 'end', ->
      console.log 'Server raw socket disconnected'
      wsock.close()

    sock.on 'data', (data) ->
      if wsock.readyState isnt 'open'
        return console.log "WebSocket closed, '#{data}' could not be sent."
      if not wsock.username
        msg = body: data.toString('utf8').replace(/\r/g, '').replace(/\n/g, ''), headers: {command: 'set', key: 'username'}
        wsock.send JSON.stringify msg
        wsock.username = data.toString('utf8')
      else
        msg = body: data.toString('utf8').replace(/\r/g, '').replace(/\n/g, ''), headers: {command: 'chat-message', from: wsock.username, color: wsock.color}
        if msg.body.match(/^quit/i)
          sock.write('Bye\r\n')
          wsock.close()
          return sock.end()
        setImmediate ->
          if wsock.readyState is 'open'
            wsock.send JSON.stringify msg

     sock.write("Please enter your name: ")


  proxyServer.listen port

module.exports = {wsserver, socks, msgs, createProxy}

# End of websocket specific section

