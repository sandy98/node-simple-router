#!/usr/bin/env coffee

process.chdir __dirname

fs = require 'fs'

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
  fs.readFile "#{__dirname}/templates/documentation.html", encoding: "utf8", (err, data) ->
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


#
#End routes
#


#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

server.on 'listening', ->
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at " + addr.address + ":" + addr.port  + " - PID: " + process.pid + " from directory: " + process.cwd()

clean_up = ->
  router.log ' '
  router.log "Server shutting up..."
  router.log ' '
  server.close()
  process.exit 0

process.on 'SIGINT', clean_up
process.on 'SIGHUP', clean_up
process.on 'SIGQUIT', clean_up
process.on 'SIGTERM', clean_up

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000