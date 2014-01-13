#!/usr/bin/env coffee

arr = []
arr.push "#!/usr/bin/env coffee"
arr.push "\n"
arr.push "try"
arr.push "  Router = require 'node-simple-router'"
arr.push "catch e"
arr.push "  console.log 'node-simple-router must be installed for this to work'"
arr.push "  process.exit(-1)\n"
arr.push "http = require 'http'"
arr.push "router = Router(list_dir: true)"
arr.push "#"
arr.push "#Example routes"
arr.push "#"

arr.push "router.get \"/\", (request, response) ->"
arr.push "  response.writeHead(200, {'Content-Type': 'text/html'})"
arr.push '  response.write("<h1>Home</h1><hr/>")'
arr.push '  response.write(\'<div><a href="/hello">Hello Page</a></div>\')'
arr.push '  response.write(\'<div><a href="/users">Users Page</a></div>\')'
arr.push '  response.end(\'<div><a href="/users/77">User 77 home page</a></div>\')\n'

arr.push "router.get \"/hello\", (request, response) ->"
arr.push " response.end 'Hello, World!, Hola, Mundo!'\n"

arr.push "router.get \"/users\", (request, response) ->"
arr.push "  response.writeHead(200, {'Content-type': 'text/html'})"
arr.push "  response.write '<h1 style=\"color: navy; text-align: center;\">Active members registry</h1><hr/>'\n"
arr.push '  response.write(\'<div><form action="/users" method="POST">\')'
arr.push '  response.write(\'<label>User ID: </label>\')'
arr.push '  response.write(\'<input type="number" name="user_id" /><input type="submit" value="Search" />\')'
arr.push '  response.end(\'</form></div>\')'

arr.push "router.post \"/users\", (request, response) ->"
arr.push '  response.end "User #{request.post.user_id} requested. Trying to figure out who she is..." \n'

arr.push "router.any \"/users/:id\", (request, response) ->"
arr.push "  response.writeHead(200, {'Content-type': 'text/html'})"
arr.push "  response.end \"<h1>User No: <span style='color: red;'>\" + request.params.id + \"</span></h1>\"\n"

arr.push "#"
arr.push "#End of example routes"
arr.push "#\n\n"
arr.push "#Ok, just start the server!\n"
arr.push "argv = process.argv.slice 2\n"
arr.push "server = http.createServer router\n"
arr.push "server.on 'listening', ->"
arr.push "  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}"
arr.push "  router.log \"Serving web content at \" + addr.address + \":\" + addr.port  + \" - PID: \" + process.pid \n"
arr.push "clean_up = ->"
arr.push "  router.log ' '"
arr.push "  router.log \"Server shutting up...\""
arr.push "  router.log ' '"
arr.push "  server.close()"
arr.push "  process.exit 0\n"
arr.push "process.on 'SIGINT', clean_up"
arr.push "process.on 'SIGHUP', clean_up"
arr.push "process.on 'SIGQUIT', clean_up"
arr.push "process.on 'SIGTERM', clean_up\n"
arr.push "server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000"

cs = arr.join '\n'

js = """
     #!/usr/bin/env node

     (function() {
     var Router, argv, http, router, server, clean_up;

     try {
     Router = require('node-simple-router');
     } catch (e) {
     console.log('node-simple-router must be installed for this to work');
     process.exit(-1);
     }

     http = require('http');

     router = Router({
     list_dir: true
     });

     /*
     Example routes
     */

     router.get("/", function(request, response) {
         response.writeHead(200, {
           'Content-type': 'text/html'
         });
         response.write("<h1>Home</h1><hr/>");
         response.write('<div><a href="/hello">Hello Page</a></div>');
         response.write('<div><a href="/users">Users Page</a></div>');
         return response.end('<div><a href="/users/77">User 77 home page</a></div>');
     });

     router.get("/hello", function(request, response) {
       return response.end("Hello, World!, Hola, Mundo!");
     });

     router.get("/users", function(request, response) {
       response.writeHead(200, {
       'Content-type': 'text/html'
       });
       response.write("<h1 style='color: navy; text-align: center;'>Active members registry</h1><hr/>");
       response.write('<div><form action="/users" method="POST">');
       response.write('<label>User ID: </label>');
       response.write('<input type="number" name="user_id" /><input type="submit" value="Search" />');
       return response.end('</form></div>');
     });

     router.post("/users", function(request, response) {
       return response.end("User " + request.post.user_id + " requested. Trying to figure out who she is...");
     });

     router.any("/users/:id", function(request, response) {
       response.writeHead(200, {
         'Content-type': 'text/html'
       });
       return response.end("<h1>User No: <span style='color: red;'>" + request.params.id + "</span></h1>");
     });

     /*
     End of example routes
     */


     argv = process.argv.slice(2);

     server = http.createServer(router);

     server.on('listening', function() {
       var addr;
       addr = server.address() || {
         address: '0.0.0.0',
         port: argv[0] || 8000
       };
       return router.log("Serving web content at " + addr.address + ":" + addr.port + " - PID: " + process.pid);
     });

     clean_up = function() {
       router.log(" ");
       router.log("Server shutting up...");
       router.log(" ");
       server.close();
       return process.exit(0);
     };

     process.on('SIGINT', clean_up);
     process.on('SIGHUP', clean_up);
     process.on('SIGQUIT', clean_up);
     process.on('SIGTERM', clean_up);

     server.listen((argv[0] != null) && !isNaN(parseInt(argv[0])) ? parseInt(argv[0]) : 8000);

     }).call(this);

     """

fs = require 'fs'

filename = if process.argv[2]?.toLowerCase() is 'js' then 'server.js' else 'server.coffee'
full_filename = "#{process.cwd()}/#{filename}"
text = if process.argv[2]?.toLowerCase() is 'js' then js else cs

fs.writeFileSync full_filename, text

fs.chmodSync full_filename, 0o755





