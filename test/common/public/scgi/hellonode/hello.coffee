#!/usr/bin/env coffee

net = require 'net'
fs = require 'fs'

if fs.existsSync '/tmp/node_scgi.sk'
    fs.unlinkSync '/tmp/node_scgi.sk'

handler =  (conn) ->
  conn.on 'data', (data) ->
    console.log "============================================"
    console.log "============== INCOMING DATA ==============="
    console.log "============================================"
    console.log line for line in data.toString().split('\0')
    console.log "============================================"
    console.log "========== END OF INCOMING DATA ============"
    console.log "============================================"
  conn.on 'end', (data) ->
    console.log "FINAL DATA: #{data.toString()}" if data
    conn.write "Status: 200 OK\r\n"
    conn.write "Content-type: text/html\r\n"
    conn.write "<title>SCGI via Node.js</title>\r\n"
    conn.write "<h3 style='text-align: center; color: magenta;'>Node.js SCGI Server</h3><hr/>\r\n"
    conn.end "<p>Current time: <strong>#{new Date().toLocaleString()}</stron></p>"

server = net.createServer allowHalfOpen: true, handler

process.umask 0o111

console.log "Serving SCGI on '/tmp/node_scgi.sk'"
server.listen '/tmp/node_scgi.sk'
