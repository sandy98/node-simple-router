# Beginning of websocket specific section.

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
      sock.send msg
    catch e
      console.log "Error sending data to clients: #{e.message}"

  
broadcastChattersList = () ->
  lsocks = ({id: sock.id, color: sock.color, username: sock.username, currentRoundTrip: sock.currentRoundTrip} for sock in socks when sock.username)
  for sock in socks
    try
      #console.log "Sending #{lsocks}"
      sock.send headers: {command: 'chatters-list', subcommand: 'init'}, body: lsocks
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
 

module.exports = {wsserver, socks, msgs}

# End of websocket specific section

