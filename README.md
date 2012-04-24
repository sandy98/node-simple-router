## Node.js Simple Router - Yet another minimalistic router for node.js

### Install

From Node Package Manager:

<pre>
  npm install node-simple-router
</pre>

or from source:

<pre>
  git clone git://github.com/sandy98/node-simple-router.git
</pre>

### Purpose
Designed to provide routes to barebones node http server, Sinatra style (or Express.js router, for that matter) staying out
of your way for the rest.
Source main file - router.coffee - and testing utility - test_router.coffee - are coffeescript source files. Should you prefer to
work with javascript, just simply compile them (i.e. coffee -c router.coffee) provided you have installed coffee-script, which is as
simple as <pre>sudo npm install coffee-script -g</pre>

### Basic Usage
```coffeescript
# Assumes router.coffee is located at the current working directory.
Router = require './router'
http   = require 'http'

router = Router()

router.get '/', (request, response) ->
  response.end 'Home page'

router.get '/hello/:who', (request, response) ->
  response.end "Hello, #{params.who}"

server = http.createServer router

server.listen 3000

#Off you go!
```
or, for the unlikely case you didn't yet discover/fall in love with coffeescript, the javascript version:

```javascript
// Assumes router.coffee is located at the current working directory.
var Router = require('./router')
var http   = require('http')

var router = Router();

router.get('/', function (request, response) {
  response.end('Home page');})

router.get('/hello/:who', function(request, response) {
  response.end("Hello, " + params.who);})

server = http.createServer(router)

server.listen(3000)

//Off you go!
```

### Complementary topics
I) Default options

-    *logging: true*                         Turns off logging if defined false
-    *log: console.log*                      Defines console.log as default logging output.
-    *serve_static: true*                    Allows serving static content.
-    *static_route: "#{__dirname}/public"*   Defines root directory for static contents
-    *list_dir: true*                        Allows/disallows directory listings

Example:
```javascript
//Disallows logging and directory listing, uses '/static' for static contents,
//defaults remaining options
var router = Router({logging: false; list_dir: false; static_route: __dirname + '/static'}
```






### Final note
Was this necessary?
Probably not.
But then again, there are a couple of reasons that I think make it worth, and perhaps, useful to someone who shares these.
For one thing, *reinventing the wheel is not only fun, it's frequently highly educative*.
Second, there are quite of bunch of routing solutions for node.js, but I found the ones that come bundled with node frameworks,
although in most cases high quality and performant, also in many cases just a bit too much stuffed with features that either I didn't
need or was unable to manage/tweak to my projects needs, hence the decision to roll my own, mainly aimed to serve as a lightweight
component for a *restful API*.
Last but not least, I wanted to *share the fun*.



