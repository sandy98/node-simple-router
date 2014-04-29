createWs = ->
    ws = new WebSocket 'ws://savos.ods.org:8000'
    ws.onopen = (evt) -> console.log 'socket opened', evt
    ws.onclose = (evt) ->
        console.log 'socket closed.', evt?.wasClean, evt?.code, evt?.reason
    ws.onerror = (evt) ->
        console.log 'socket error:', evt?.error?.message
    ws.onmessage = (evt) -> console.log "Received: #{evt.data}"
    ws
    
