#!/usr/bin/env coffee


Router = require '../../lib/router'
  
http = require 'http'

router = Router(list_dir: true)

###
Example routes
###

#router.get "/", (req, res) ->
#  res.end "Home"

router.get "/hello", (req, res) ->
  res.end "Hello, World!, Hola, Mundo!"

router.get "/users", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end "<h1 style='color: navy; text-align: center;'>Active members registry</h1>"


router.post "/users", (req, res) ->
  router.log "\n\nBody of request is: #{req.body.toString()}\nRequest content type is: #{req.headers['content-type']}"
  router.log "\nRequest Headers"
  router.log "#{key} = #{val}" for key, val of req.headers
  router.log "\nRequest body object properties"
  res.write "\nRequest body object properties\n"
  try
    router.log "#{key}: #{val}" for key, val of req.body
  catch e
    res.write "Looks like you did something dumb: #{e.toString()}\n"
  for key, val of req.body
    res.write "#{key} = #{val}\n"
  res.end()

router.get "/users/:id", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end "<h1>User No: <span style='color: red;'>#{req.params.id}</span></h1>"

router.get "/crashit", (req, res) ->
  throw new Error("Crashed on purpose...")

router.post "/showrequest", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/plain'})
  res.write '-----------------------------------------------------------\n\n'
  res.write "The name is Bond...hey, no, it is #{req.post['name'] or 'unknown'}\n"
  res.write "And the age is #{req.post['age']}\n\n";
  #res.write("And that is all, folks...")
  for key, val of req
    try
      stri = "Request #{key} = #{JSON.stringify(val)}\n"
      router.log stri unless not router.logging
      res.write stri
    catch e
      res.write "NASTY ERROR: #{e.message}\n"
  res.end()

router.get "/formrequest", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  res.end """
    <title>Request vars discovery</title>
    <form action="/showrequest" method="post" enctype="application/x-www-form-urlencoded">
      <p>Name:<input type="text" required="required" size="40" name="name" /></p>
      <p>Age:&nbsp;&nbsp;&nbsp;<input type="number" required="required" size="4" name="age" /></p>
      <p><input type="submit" value="Submit to /showrequest" /><input type="reset" value="Reset" /></p>
    </form>
          """

# Proxy pass

router.get "/google", (req, res) ->
  router.proxy_pass "http://www.google.com.ar", res

router.get "/testing", (req, res) ->
  router.proxy_pass "http://testing.savos.ods.org/", res

router.get "/testing/:route", (req, res) ->
  router.proxy_pass "http://testing.savos.ods.org/#{req.params.route}/", res

router.get "/shell", (req, res) ->
  router.proxy_pass "http://testing.savos.ods.org:10001", res

# End of proxy pass

#Auth


router.get "/login", (req, res) ->
  require_credentials = ->
    res.setHeader "WWW-Authenticate", 'Basic realm="node-simple-router"'
    res.writeHead 401, 'Access denied', 'Content-type': 'text/html'
    res.end()

  console.log req.headers
  console.log "----------------------------------------------------------------"
  if not req.headers['authorization']
    require_credentials()
  else
    console.log "req.headers['authorization'] = #{req.headers['authorization']}"
    auth = req.headers['authorization'].split /\s+/
    console.log "AUTH: #{auth[0] + ' - ' + auth[1]}"
    [usr, pwd] = new Buffer(auth[1], 'base64').toString().split ':'
    if usr is 'sandy' and pwd is 'ygnas'
      res.writeHead 200, 'Content-type': 'text/plain'
      res.write "usr: #{usr}\n"
      res.write "pwd: #{pwd}\n"
      res.end()
    else
      require_credentials()
      
#End of Auth


#SCGI

router.get "/scgi", (req, res) ->
  router.scgi_pass '/tmp/node_scgi.sk', req, res

get_scgi = (req, res) ->
  router.scgi_pass 26000, req, res  

router.get "/scgiform", (req, res) ->
  res.writeHead 200, 'Content-type': 'text/html'
  res.end """
  <title>SCGI Form</title>
  <h3 style="text-align: center; color: #220088;">SCGI Form</h3><hr/>
  <form action="/uwsgi" method="post">
    <table>
      <tr>
        <td>Name</td>
        <td style="text-align: right;"><input type="text" size="40" name="name" required="required" /></td>
      <tr>
      <tr>
        <td>Age</td>
        <td style="text-align: right;"><input type="number" size="4" name="age" /></td>
      <tr>
      <tr>
        <td><input type="submit" value="Send  data" /></td>
        <td><input type="reset" value="Reset" /></td>
      <tr>
    </table>
  </form>
  """
  
router.get "/uwsgi", get_scgi
router.post "/uwsgi", get_scgi

#End of SCGI


###
End of example routes
###

#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

server.on 'listening', ->
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at #{addr.address}:#{addr.port}"
      
process.on "SIGINT", ->
  server.close()
  router.log "\n Server shutting up...\n"
  process.exit 0

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000


