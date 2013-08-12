# Node.js Simple Router
# Yet another minimalistic router for node.js

## Install

From Node Package Manager:

<pre>
  npm install node-simple-router
</pre>

or from source:

<pre>
  git clone git://github.com/sandy98/node-simple-router.git
</pre>

## Purpose
Designed to provide routes to barebones node http server, Sinatra style (or Express.js router, for that matter) staying out
of your way for the rest.

Main target: restful APIs for single page applications.

Source main file - router.coffee - and testing utility - test_router.coffee - are coffeescript source files. Should you prefer to
work with javascript, just simply compile them (i.e. coffee -c router.coffee) provided you have installed coffee-script, which is as
simple as <pre>sudo npm install coffee-script -g</pre>

## Basic Usage
```coffeescript
# CoffeeScript version
# Assumes usual installation through npm.
Router = require 'node-simple-router'
# Alternative: assumes router.js - or router.coffee - is located at the current working directory.
#Router = require('./router')

var http   = require('http')

router  = Router()

router.get '/', (request, response) ->
  response.end 'Home page'

router.get '/hello/:who', (request, response) ->
  response.end "Hello, #{request.params.who}"

server = http.createServer router

server.listen 3000

```
or, for the unlikely case you didn't yet discover/fall in love with coffeescript, the javascript version:

```javascript
// Javascript version
// Assumes usual installation through npm.
var Router = require('node-simple-router')
// Alternative: assumes router.js is located at the current working directory.
//var Router = require('./router')

var http   = require('http')

var router = Router();

router.get('/', function (request, response) {
  response.end('Home page');})

router.get('/hello/:who', function(request, response) {
  response.end("Hello, " + request.params.who);})

server = http.createServer(router)

server.listen(3000)

```
## Changelog
### < 0.2.4 All the basic stuff
### 2012-09-07: v0.2.4 Added CGI support
Currently the cgi dispatcher relies - as it's supposed to be - on the cgi process to provide the correct headers.
Also, post and get - summed up in 'body' - must be readed by the cgi process via std input and converted to json 
object by whatever means the cgi implementation provides. For instance, a python example could be implemented along 
the lines:
```python   
    
import json, sys
    
body = json.loads(sys.stdin.readline())
for key in body:
    print "%s = %s" % (key, body[key])
```

### 2013-03-25: v0.2.5 Added mimetypes xml and svg to the list of recognized types      

### 2013-04-01: v0.2.6 Added compile to js tool 'compile.sh'      

### 2013-04-02: v0.2.7 Added mk-server to the bin directory. 
This is a tiny tool that will create a brand new node-simple-router powered server to the working directory.
It can be invoked with no params, producing an executable server.coffee file. Should you prefer getting a javascript version of the server, 
you must invoke it like so: mk-server js. This will produce server.js.

It's worth noting that in order for this to be useful, you should install node-simple-router globally <code>sudo npm install -g node-simple-router</code>       

### 2013-04-03: v0.3.0 node-simple-router becomes able to handle form uploads.
Or, to be precise, *node-simple-router* aka *nsr* has earned the ability to handle multipart/form-data

This can be seen as an important update, hence the minor version leap (0.2 to 0.3)

There is an example of the way to use it to handle uploads that may be found in test/uploader/server.coffee (or server.js, 
for that matter), following the route "/upload". A simplified version follows:

```coffeescript   
router.post "/upload", (req, res) ->
  res.writeHead(200, {'Content-type': 'text/html'})
  if req.post['multipart-data']
    for part in req.post['multipart-data']
      for key, val of part
          res.write "#{key} = #{val}<br/>" unless ((key is 'fileData') and part.fileName)
      if part.fileName
        fullname = "#{__dirname}/public/uploads/#{part.fileName}"
        if part.contentType.indexOf('text') >= 0
          fs.writeFileSync fullname, part.fileData
        else
          fs.writeFileSync fullname, part.fileData, 'binary'
        res.write '<div style="text-align:center; padding: 1em; border: 1px solid; border-radius: 5px;">'
        if part.contentType.indexOf('image') >= 0
          res.write "<img src='uploads/#{part.fileName}' />"
        else
          res.write "<pre>#{part.fileData}</pre>"
        res.write '</div>'
      res.write "<hr/>"

  res.end "" 
```   
Essentially, what you get is an array labeled 'multipart-data' added to the body of the request. Each of its members 
will have some, or all of the following properties (some may lack "filename")

-   *contentDisposition*

    Just for reference. This will always be "form-data"
   
-   *fieldName*

    The name of the input element that originated the current member of the array.

-   *fileName*

    This will only exist if the originating field is &lt;input type="file"&gt;
   
-   *fileData*

    This and the following may be somewhat misleading names, because as has been noted the object may not be a
    file. Regardless, it contains whatever was in the originating field. If this was a text input type, it will be
    the contents input by the user. If it was a file, it will be its contents.
    Its worth noting that in order for this to work accurately, the request input has been previously determined as
    binary by the router, like so: ``` req.setEncoding('binary') ``` 

-   *fileLen*

    Length of fileData 

-   *contentType*

    Mimetype of fileData, as sent by the browser. Things like 'text/plain', 'image/jpeg', etc
    
### 2013-07-27: v0.3.5 Correction for paths which have escaped characters.
    
### 2013-08-02: v0.3.6 Added default favicon. Fixed cgi-bin.
    
### 2013-08-03: v0.4.1 Improved cgi-bin. Looks like it's now really usable. Now FCGI to come.

### 2013-08-04: v0.4.5 Further improvement for cgi-bin, mainly PHP related. Some issues remain as regards to PHP, though.

### 2013-08-12: v0.4.7 CGI works smoothly now. SCGI support - router.scgi_pass - added and working fine.

## Complementary topics
###I) Default options

-    **logging**: *true*

     Turns off logging if defined false

-    **log**: *console.log*

     Defines console.log as default logging output.

-    **serve_static**: *true*

     Allows serving static content.

-    **static_route**: *"#{__dirname}/public"*

     Defines root directory for static contents

-    **list_dir**: *true*

     Allows/disallows directory listings

Example:
```javascript
//Disallows logging and directory listing, uses '/static' for static contents,
//defaults remaining options
var router = Router({logging: false, list_dir: false, static_route: __dirname + '/static'})
```
###II) Retrieving get/post data

Request get data may be retrieved from *request.get*, an object in JSON format

Request post data is included, also in JSON format, in *request.post*, although in this case, if data came in an
unrecognized format, it will be retrieved as raw data, without any conversion.

Finally, *request.get* and *request.post* are joined in *request.body*, so if you don't care how the data got to the
server, you can use that.

###III) Getting parameters from urls

Uses a similar convention as Express.js: any url segment preceded by a colon is treated as a parameter, as shown below

```javascript
router.get('/users/:id', function(request, response) {
  response.end("User: " + getUserById(request.params.id).fullName);})
```


###IV) Todo list
-    Making directory listing actually work
-    Preparing a nice template for directory listing.
-    Managing file uploads.


## Final note
Was this necessary?

Probably not.

But then again, there are a couple of reasons that I think make it worth, and perhaps, useful to someone who shares these.

For one thing, *reinventing the wheel is not only fun, it's frequently highly educative*.

Second, there are quite a bunch of routing solutions for node.js, but I found the ones that come bundled with node frameworks,
although in most cases high quality and performant, also in many cases just a bit too much stuffed with features that either I didn't
need or was unable to manage/tweak to my projects needs, hence the decision to roll my own, mainly aimed to serve as a lightweight
component for a *restful API*.

Last but not least, I wanted to *share the fun*.

**Last minute note:** Guaycuru web server, initially included as a test of the static resource serving capabilities of this router,
is no longer present in current distribution. Instead, you can get it [here](https://github.com/sandy98/guaycuru) or install it by 
means of *npm*  

## License

(The MIT License)

Copyright (c) 2012 Ernesto Savoretti <esavoretti@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
