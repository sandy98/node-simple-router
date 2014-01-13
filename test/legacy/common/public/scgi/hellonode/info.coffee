#!/usr/bin/env coffee

net = require 'net'
fs = require 'fs'

received = ""


replace_zeros = (stri, replacement = "@") ->
  retval = ""
  for i in [0..(stri.length - 1)]
    if stri.charCodeAt(i) isnt 0
      retval += stri[i]
    else 
      retval += replacement
  retval

write_res = (conn, obj) ->
  #received += data.toString('utf8') if data
  conn.write "Status: 200 OK\r\n"
  conn.write "Content-type: text/html\r\n"
  conn.write "\r\n"
  headers = obj.headers
  body = obj.body
 
  conn.write "<h3>HEADERS</h3><hr/>"
  headers = headers.split /\0/g
  keys = (n for n in headers by 2)
  thevals = headers[1..]
  vals = (n for n in thevals by 2)
  #console.log keys
  #console.log vals
  heads = []
  for val, index in keys
    heads.push "#{keys[index]} = #{vals[index]}<br/>----------------------------------------------<br/>" if keys[index]
  conn.write head for head in heads 
  conn.write "<hr/>"
  conn.write "<h3>BODY</h3><hr/>"
  conn.write body
  conn.write "<hr/>"
  #conn.write received.replace /\0/g, '<br/>'
  conn.end()
  
handler =  (conn) ->
  received = ""
  conn.on 'data', (data) ->
    sans_zeros = replace_zeros(data.toString('utf8'), '\0')
    received += sans_zeros
    console.log "RECEIVED #{replace_zeros sans_zeros}"
    m = received.match /^(\d+):/
    if m
      nslen = parseInt m[1]
      prefix = "#{m[1]}:"
      console.log "PREFIX #{prefix}"
      nsrcvlen = received.length - m[1].length - 1
      if nsrcvlen >= nslen
        pat = /CONTENT_LENGTH\0(\d+)\0/i
        m = received.match pat
        if m
          bodylen = parseInt(m[1])
          totallen = nslen + bodylen + 1
          console.log "Netstring length: #{nslen} - Body length: #{bodylen} - Total length: #{totallen}"
          if nsrcvlen >= totallen
            headers = received.substring(prefix.length, (prefix.length + nslen))
            console.log "HEADERS: #{headers}"
            if bodylen > 0
              body = received.substring(prefix.length + nslen + 1)
            else
              body = ""
            console.log "BODY: #{body}"
            write_res conn, {headers: headers, body: body}
          else
            return
        else
          return
      else
        return  
    else
      return
      
  #conn.on 'end', -> write_res(conn)
  #conn.on 'error', -> write_res(conn)
  
server = net.createServer allowHalfOpen: true, handler


console.log "Serving SCGI on port 26000"
server.listen 26000
