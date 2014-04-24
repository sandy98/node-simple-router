{WebSocketClientConnection} = require '../src/ws'
ws = new WebSocketClientConnection('ws://echo.websocket.org')
ws.readyState
ws.on 'close', (code) -> console.log "Socket closed", code
ws.on 'data', (opcode, data) -> console.log "OPCODE:", opcode, "DATA:", data
