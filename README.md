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
In progress
