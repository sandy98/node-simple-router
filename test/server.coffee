#!/usr/bin/env coffee

process.chdir __dirname

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

http = require 'http'
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
  about_active: ''

#
#Routes
#

site_router = (context, response) ->
  fs.readFile "#{__dirname}/templates/layout.html", encoding: "utf8", (err, layout_data) ->
    response.end router.compile_template(layout_data, context)

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

router.get "/documentation", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/documents.html", encoding: "utf8", (err, data) ->
    context = _extend(base_context, {contents: data, documentation_active: 'active'})
    site_router(context, response)

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

router.get "/about", (request, response) ->
  response.writeHead(200, {'Content-Type': 'text/html'})
  fs.readFile "#{__dirname}/templates/about.html", encoding: "utf8", (err, data) ->
    context = _extend(
      base_context
      contents: router.compile_template(data, current_version: router.version), about_active: 'active')
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
       <span style="color: red;">#{request.params.number}</span>
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
    contents: router.compile_template(
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



#
#End routes
#


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
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at " + addr.address + ":" + addr.port  + " - PID: " + process.pid + " from directory: " + process.cwd()

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