#!/usr/bin/env coffee

process.chdir __dirname

path = require 'path'
fs = require 'fs'
spawn = require('child_process').spawn

try
  Router = require '../src/router'
catch e
  try
    Router = require '../lib/router'
  catch e2
    console.log 'node-simple-router must be installed for this to work'
    process.exit(-1)

{defer} = require '../lib/promises'
{wsserver, socks, msgs, createProxy} = require "#{__dirname}#{path.sep}wschat"
wamp = require "../lib/wamp"
{wampRouter, chatManager} = require "#{__dirname}#{path.sep}wampchat"
http = require 'http'
https = require 'https'
router = Router(list_dir: true)

_extend = (base, extender) ->
  new_obj = {}
  for key, val of base
    new_obj[key] = val
  for key, val of extender
    new_obj[key] = val
  new_obj

base_context =
  home_active: ''
  getting_started_active: ''
  documentation_active: ''
  changelog_active: ''
  license_active: ''
  wiki_active: ''
  about_active: ''

#
#Routes
#

site_router = (context, response, keep_tokens = false) ->
  router.render_template_file "#{__dirname}/templates/layout.html", context, ((exists, rendered_text) -> response.end rendered_text), keep_tokens


router.get "/", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/home.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, home_active: 'active'})
    site_router(context, response)

router.get "/getting_started", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/getting_started.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, getting_started_active: 'active'})
    site_router(context, response)

router.get "/documents", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/documents.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, documentation_active: 'active'})
    site_router(context, response, true)

router.get "/changelog", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/changelog.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, changelog_active: 'active'})
    site_router(context, response)

router.get "/license", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/license.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, license_active: 'active'})
    site_router(context, response)

router.get "/wiki", (request, response) ->
  get_wiki request, response, "Home"

router.get "/wiki/:page", (request, response) ->
  get_wiki request, response, request.params.page

get_wiki = (request, response, destination) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/wiki.html", encoding: "utf8", (err, data) ->
    https.get "https://github.com/sandy98/node-simple-router/wiki/#{destination}", (resp) ->
      chunks = []
      resp.on 'error', (err) -> router._500 request, response, request.url, err.message
      resp.on 'data', (chunk) -> chunks.push chunk
      resp.on 'end', () ->
        #remote_data = chunks.join('').replace(/\/sandy98\/node-simple-router\/wiki/g, '/wiki')
        remote_data = chunks.join('')
        context = _extend(
          base_context
          contents: router.render_template(data, wiki_content: remote_data), wiki_active: 'active')
        site_router(context, response)

router.get "/about", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/about.html", encoding: "utf8", (err, data) ->
    context = _extend(
      base_context
      contents: router.render_template(data, current_version: router.version), about_active: 'active')
    site_router(context, response)

router.get "/hello_world", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  data = """
     <div style="margin-left: 2em;">
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="English">Hello, World!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="Spanish">Hola, Mundo!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="Italian">Ciao, Mondo!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="French">Bonjour, tout le Monde!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="Portuguese">Ol&aacute;, Mundo!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="German">Hallo, Welt!</p>
         <p style="color: rgb(#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)},#{Math.floor(Math.random() * 256)});" title="Catalan">Hola, M&oacute;n!</p>
     </div>
     <hr/>
     <p><strong>Current Time:</strong>&nbsp;<span id='date-span'>#{new Date().toLocaleString().replace(/GMT.+/, '')}</span></p>
     <script type="text/javascript">
        setTimeout(function () {try {$('p[title]').tooltip({placement: 'left'});} catch (e) {}}, 0);
        setInterval(function () {document.getElementById('date-span').innerHTML = new Date().toLocaleString().replace(/GMT.+/, '');}
        , 1000);
        setTimeout(function () {location.reload();}, 10000);
       </script>
  """
  context = _extend(
    base_context
    contents: data)
  site_router(context, response)

router.any "/agents/:number", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  data = """
   <div>
     <h1>
       <span>Super Agent No:&nbsp;</span>
       <span class="nsr">#{request.params.number}</span>
     </h1>
   </div>
  """
  context = _extend(
    base_context
    contents: data)
  site_router(context, response)

router.get "/teams", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  data = """
     <div>
       <form method="post">
         <label>Preferred team:&nbsp;&nbsp;&nbsp;</label><input type="text" placeholder="River Plate" name="team_name" required="required" /><br/>
         <label>Titles won:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label><input type="number" value="0" name="titles_won" required="required" /><br/>
         <p></p>
         <input class="btn btn-primary" type="submit" value="Send" /> <input class="btn" type="reset" value="Reset" />
       </form>
     </div>
  """
  context = _extend(
    base_context
    contents: data)
  site_router(context, response)

router.post "/teams", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  data = """
    <h1>
      Your team is <span style="color: #ff0000;">{{ team_name }}</span>
      &nbsp;and has won <span style="color: #008f00;">{{ titles_won }}</span> title{{is_plural}}.
    </h1>
    <hr/>
    <p><a href="/teams">Back to team choice</a></p>
  """
  context = _extend(
    base_context
    contents: router.render_template(
      data
      _extend(request.post, is_plural: if request.post.titles_won is "1" then '' else 's')))
  site_router(context, response)


router.get "/wimi", (request, response) ->
  #router.proxy_pass "http://testing.savos.ods.org/wimi", response
  router.proxy_pass "http://sandy98-coffee-hello.herokuapp.com/wimi", response

router.get "/cgitest", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/cgitest.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data})
    site_router(context, response)

router.get "/scgitest", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/scgiform.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data})
    site_router(context, response)

router.post "/scgi/:prog_id", (request, response) ->
  if request.params.prog_id is 'hello_scgi_py'
    router.scgi_pass(26000, request, response)
  else
    router._404 request, response, request.url

router.any "/templates", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/layout.html", encoding: "utf8", (err, layout) ->
    fs.readFile "#{__dirname}/templates/templates.html", encoding: "utf8", (err, data) ->
      if request.method.match /post/i
        try
          tpl_obj = eval("(#{request.post.txt_context})")
        catch e
          tpl_obj = {}
        #router.log tpl_obj
        template = request.post.txt_template
        #router.log template
        compiled = router.render_template(template, tpl_obj)
        str_to_replace = """<div id="template-result">"""
        data = data.replace str_to_replace, "#{str_to_replace}#{compiled}"
        script = """
                 <script type="text/javascript">
                  var setValues = function () {
                  //document.getElementById('txt-context').value = 'CONTEXT';
                  //document.getElementById('txt-template').value = 'TEMPLATE';
                    var context = '#{escape(request.post.txt_context)}';
                    var template = '#{escape(request.post.txt_template)}';
                    document.getElementById('txt-context').value = unescape(context);
                    document.getElementById('txt-template').value = unescape(template);
                   };
                   document.body.onload = function() {setTimeout(setValues, 100);};
                  </script>
                 </body>
                 """
        layout = layout.replace('</body>', script)
      response.end layout.replace("{{& contents }}", data)

router.get "/uploads_form", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/uploadsform.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data})
    site_router(context, response)

router.post "/handle_upload", (request, response) ->
  response.writeHead(200, {'Content-type': 'text/html'})
  if request.fileName
    response.write "<h2>Uploaded File Data</h2>"
    response.write "File name = #{request.fileName}<br/>"
    response.write "File length = #{request.fileLen} bytes<br/>"
    response.write "File type = #{request.fileType}<br/>"
    fullname = "#{__dirname}/public/uploads/#{request.fileName}"
    if request.fileType.indexOf('text') >= 0
      encoding = 'utf8'
    else
      encoding = 'binary'
    fs.writeFile fullname, request.fileData, encoding: encoding, (err) ->
      if err
        response.write "<p style='color: red;'>Something went wrong, uploaded file could not be saved.</p>"
      else
        response.write '<div style="text-align:center; padding: 1em; border: 1px solid; border-radius: 5px;">'
        if request.fileType.indexOf('image') >= 0
          response.write "<img src='/uploads/#{request.fileName}' />"
        else if request.fileType.indexOf('video') >= 0
          response.write "<video src='/uploads/#{request.fileName}'></video>"
        else
          response.write "<pre>#{request.fileData}</pre>"
        response.write "</div>"
      response.write "<hr/>"
      response.end """
                   <div style="text-align: center;"><button onclick="history.back();">Back</button></div>
                   """
  else
    response.write "<p style='color: red;'>Something went wrong, looks like nothing was uploaded.</p>"
    response.end """
              <div style="text-align: center;"><button onclick="history.back();">Back</button></div>
              """

router.get "/sillychat", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/sillychat.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data})
    site_router(context, response)

router.get "/wampchat", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  #fs.readFile "#{__dirname}/templates/wampchat.html", encoding: "utf8", (err, data) ->
  fs.readFile "#{__dirname}/public/wampchat.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data})
    #site_router(context, response)
    response.end data

router.get '/getsession' , (request, response)  ->
  router.getSession request, (sess_obj) ->
    response.end(JSON.stringify sess_obj)

router.get '/setsession' , (request, response)  ->
  router.setSession request, request.get
  response.writeHead(307, 'Location': "/session")
  response.end("Session updated with #{JSON.stringify(request.get)}")

router.get '/updatesession' , (request, response)  ->
  router.updateSession(request, request.get)
  response.writeHead(307, 'Location': "/session")
  response.end("Session updated with #{JSON.stringify(request.get)}")

router.get '/getcookie/:cookiename', (request, response) ->
  response.end JSON.stringify(router.getCookie(request, request.params.cookiename))

router.get '/getcookie', (request, response) ->
  response.end JSON.stringify(router.getCookie(request))

router.get '/setcookie' , (request, response)  ->
  if request.get.max_age
    max_age = request.get.max_age
    delete request.get.max_age
    router.setCookie(response, request.get, max_age)
  else
    router.setCookie(response, request.get)
  response.writeHead(307, 'Location': "/getcookie")
  response.end("Cookie updated with #{JSON.stringify(request.get)}")


router.get "/uuid", (request, response) ->
  response.end(router.getUUID())

router.get "/sethandler/:funcname", (request, response) ->
  router.setSessionHandler request.params.funcname
  response.writeHead 307, "Location": "/session"
  response.end("Session handler set to '#{router.nsr_session_handler}' function")

router.any "/session", (request, response) ->
  set_sess = false
  update_sess = false
  delete_sess = false
  obj = null
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/session.html", encoding: "utf8", (err, data) ->
    if request.method.toLowerCase() is 'post'
      #router.log request.post
      if 'nsr-handlers' of request.post
        router.setSessionHandler(request.post['nsr-handlers'])
      if 'key-text' of request.post
        key = request.post['key-text']
        value = request.post['value-text']
        obj = {}
        obj[key] = value
        switch request.post['radio-action']
          when 'set'
            set_sess = true
          when 'update'
            update_sess = true
          when 'delete'
            delete_sess = true

    router.getSession request, (sess) ->
      if set_sess
        sess = obj
        router.setSession(request, sess)
      if update_sess
        router.updateSession(request, obj)
        sess[k] = v for k, v of obj
      if delete_sess
         for k of obj
           delete sess[k]
         router.setSession request, sess

      sess_array = ({key: k, value: v} for k, v of sess)
      #router.log sess
      obj = session: sess_array, sid: router.getCookie(request, 'nsr_sid').nsr_sid
      obj.selected_handler = router.nsr_session_handler
      obj.handlers = ({name: handler, selected: if handler is router.nsr_session_handler then 'selected' else ''} for handler in router.avail_nsr_session_handlers)
      #router.log obj
      context = _extend(
        base_context
        contents: router.render_template(data, obj))
      site_router(context, response)

router.get "/icon/:x/:y", (request, response) ->
  response.writeHead(200, 'Content-Type': 'text/html')
  x = parseInt(request.params.x) or 0
  y = parseInt(request.params.y) or 0
  response.end router.get_icon(x, y)

router.get "/stockicon/:which", (request, response) ->
  if router.stock_icons[request.params.which]
    response.writeHead(200, 'Content-Type': 'text/html')
    response.end router.stock_icons[request.params.which]()
  else
    router._404(request, response, request.url)

router.get "/gallery", (request, response) ->
  fpath = "#{router.static_route}"
  path = if request.get.dir then "/#{request.get.dir}" else "."
  fpath = "#{fpath}#{path}" if path isnt "."
  router.gallery fpath, path, response
  router.log fpath

router.get "/latencies", (request, response) ->
  for sock in socks
    response.write "#{sock.username}  -  #{sock.currentRoundTrip} secs.\n"
  response.end()

#End routes
#

fakehandler = (request, opcode = 'get', sessObj = {}, cb = ((id) -> id)) ->
  cb username: 'cacarulo', time: new Date().toISOString()
  "Narizota"

func = router.addSessionHandler('fakehandler', fakehandler)

#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

try
  scgi_child = spawn "#{__dirname}/public/scgi/python/hello_scgi.py", [], cwd: "#{__dirname}/public/scgi/python"
catch e
  scgi_child = kill: (signal) ->
    console.log "'Killing' mock child with signal: #{signal}"
  console.log "Couldn't spawn real child process because of: #{e.message}\nUsing a mock one."

server.on 'listening', ->
  wsserver.listen server
  addr = server.address()
  createProxy(addr.port - 1) if addr.port?

  #wampRouter = wamp.createWampRouter()
  wampRouter.listen server, null, '/wampchat'

  wampClient = new wamp.WampClient url: "ws://#{addr.address}:#{addr.port}/wampchat", realm: "test"
  #console.log "Create wamp client at url: #{wampClient.url} in realm: #{wampClient.realm}"
  wampClient.onopen = (sessionData) ->
    add2 = () ->
      #console.log "Function 'add2' invoked with args: %j, producing result: %s", arguments, arguments[0] + arguments[1]
      result = arguments[0] + arguments[1]

    factorial = (n) -> if n < 2 then n else n * factorial n - 1

    wampClient[key] = val for key, val of sessionData
    wampClient.register('localhost.test.add2', add2)
    wampClient.register('localhost.test.factorial', factorial)
    wampClient.call('localhost.test.add2', [30, 40]).then((results) -> console.log "Result from RPC is: %j", results[0])
    wampClient.subscribe 'localhost.test.chat', (args = [], kwArgs = {}) ->
      console.log "RECEIVED THE FOLLOWING MESSAGE: #{args[0]} FROM SUBSCRIPTION localhost.test.chat"
    wampClient.publish 'localhost.test.chat', ['Hi, everybody!']

  chatManager.onopen = (sessionData) ->
    chatManager[key] = val for key, val of sessionData
    chatManager.start()
    #chatManager.subscribe 'greeting', (args, kwArgs) ->
    #  console.log "Greetings, #{args}!!!"
    #chatManager.publish "greeting", "World"

  wampClient.connect()
  chatManager.connect()

  addrString = if typeof addr is 'string' then "'#{addr}'" else "#{addr.address}:#{addr.port}"
  router.log "NSR v#{router.version} serving web content at #{addrString} - PID: " + process.pid

clean_up = ->
  router.log ' '
  router.log "Server shutting up..."
  router.log ' '
  server.close()
  scgi_child.kill('SIGTERM')
  process.exit 0

process.on 'SIGINT', clean_up
process.on 'SIGHUP', clean_up
process.on 'SIGQUIT', clean_up
process.on 'SIGTERM', clean_up

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000
