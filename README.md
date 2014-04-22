# Node Simple Router <img src="https://raw.github.com/sandy98/node-simple-router/master/test/public/img/router50.png" />
### Yet another minimalistic router for node.js 

# Getting started

## 
**Step 1: Install**

From Node Package Manager:

    npm install node-simple-router`</pre>

From source:

    git clone https://github.com/sandy98/node-simple-router


## 
**Step 2: Test**

    cd to your installation directory and run `npm test`
then point your browser to _http://localhost:8000_ and review the info
and above all, try the examples.


## 
**Step 3: Run your server**

You can roll your own, or use the sample server that NSR provides by means of the mk-server utility:

`mk-server js` will provide a barebones server (_server.js_)  with some example routes ready to run.

In order for this to work, you must have installed NSR global, like so:

   `sudo npm install -g node-simple-router`, or have the .bin directory of NSR in your path by whatever means you see fit.

Either case, the basic steps are the same:

#### Import 'http'

`var http = require('http');`

#### Import NSR

`var Router = require('node-simple-router');`

#### Instantiate the router

`var router = Router(); // may also be router = new Router();`

#### Add some routes

`router.get("/hello", function(request, response) {response.end("Hello, World!"};});`

#### Create an http server using router as the handler

`var server = http.createServer(router);`

#### Finally, make it listen on your chosen port and you're in business

`server.listen(1234);`


# Documents

### Rationale

Routing, in web app parlance, is about defining what code to execute when a given URL is invoked.
NSR takes care of the necessary plumbing to make that happen,
freeing the programmer of the cumbersome details, allowing her to focus on the problem domain.
#### How does it work?
As was stated in the lines above, it's not necessary to know <span class="nsr">NSR</span>
inner workings in order to be productive using it. Having said that, it is nevertheless useful to
have some insight on a couple of key aspects, fundamentally what could be called the <em>"request wrapping
mechanism"</em>.

When you feed <span class="nsr">NSR</span> with a url handling function, i.e. <code class="js">
router.get("/answertoall", function(request, response) {response.end("42");});</code>

what <span class="nsr">NSR</span>
does is to wrap that function into another, unnamed one, which has the primary mission of _"augmenting"_ the request
object and it stores said function in an array of url-handling functions, thus acting as a _middleware_ piece of code.
At run time, when a client invokes the matching URL, the "middleware" function will be called, which, after doing its trickery to "dress" the request object, will ultimately call the original url-handling function that was provided.
            
What does _"augmenting-dressing"_  the request object mean?

Well, basically, <span class="nsr">NSR</span> provides the request object with 3 properties:
            <ul>
              <li>**request.get** which is an object representation of the <dfn>query string</dfn></li>
              <li>**request.post** an object representation of what was posted, if anything</li>
              <li>**request.body** is the union of the two previous items</li>
            </ul>
            It should be pointed down that regardless the transmission method, <span class="nsr">NSR</span>
            takes the necessary steps to make all 3 of them true javascript objects with all that implies, JSON and all.
            Worst case is an empty object **{}**, no errors.
            So, you can use `request.get.whatever` for `router.get`,
            `request.post.whatever` for `router.post`, but in any case, if you don't care about request method,
            using `request.body.whatever` is a safe bet, most obviously useful if you do not know in advance
            the request method, for example: <code class="js">router.any("/threefold", function(request, response)
            {response.end((parseInt(request.body.number) * 3).toString();});</code>
         </p>
         <p>
             Wrapping up, you just got to remember **request.get, request.post** and **request.body**
             
And that's all there is about it.

### Options

NSR sticks to some conventions ("public" as directory name for static assets, etc),
which the programmer can override when instantiating the router, for instance:

    var router = new Router({static_route: __dirname + "/static"});
to change usage of the default "public" directory for static resources
            

List of default options:
            <p>
                <pre><code class="js">
                logging: true
                log: console.log
                static_route: "#{process.cwd()}/public"
                serve_static: true
                list_dir: true
                default_home: ['index.html', 'index.htm', 'default.htm']
                cgi_dir: "cgi-bin"
                serve_cgi: true
                serve_php: true
                php_cgi: "php-cgi"
                served_by: 'Node Simple Router'
                software_name: 'node-simple-router'
                admin_user: 'admin'
                admin_pwd: 'admin'
                use_nsr_session: true
                avail_nsr_session_handlers: ['dispatch.memory_store', 'dispatch.text_store']
                nsr_session_handler: 'dispatch.memory_store'
                </code></pre>
            </p>
            <p>
                Most of them are self explanatory, but some deserve further comments,
                which will be added on doc completion.
            </p>
 
## Router API

Router object supports the following methods
#### <dfn>get</dfn>
_Usage:_

      router.get('/users/:id', function(request, response) {
        response.end("User: " + getUserById(request.params.id).fullName);});
          
#### <dfn>post</dfn>
_Usage:_

    router.post('/users', function(request, response) {
                        insertUser(request.post.user, function(new_user_id) {
                          request.post.user.id = new_user_id;
                          response.end(JSON.stringify(request.post.user);});
                        });

#### Handling file uploads
<span class="nsr">NSR</span> handles 'multipart/form-data' out of the box.
When <span class="nsr">NSR</span> detects a post having enctype="multipart/form-data" it
adds to the _request_ object the properties: <em>fileName, fileLen, fileData and
fileType</em>, which client code (your server) can handle as shown in the following usage example.

_Usage:_

        router.post("/handle_upload", function(request, response) {
        var encoding, fullname;
        response.writeHead(200, {'Content-type': 'text/html'});
        if (request.fileName) {
           response.write("&lt;h2&gt;Uploaded File Data&lt;/h2&g");
           response.write("File name = " + request.fileName + "&lt;br/&gt;");
           response.write("File length = " + request.fileLen + " bytes&lt;br/&gt;");
           response.write("File type = " + request.fileType + "&lt;br/&gt;");
           fullname = "" + __dirname + "/public/uploads/" + request.fileName;
           if (request.fileType.indexOf('text') &gt;= 0) {
              encoding = 'utf8';
           }
           else {
             encoding = 'binary';
           }
           return fs.writeFile(fullname, request.fileData, {encoding: encoding}, function(err) {
             if (err) {
               response.write("&lt;p style='color: red;'&gt;Something went wrong, uploaded file could not be saved.&lt;/p&gt;");
             }
             else {
               response.write('&lt;div style="text-align:center; padding: 1em; border: 1px solid; border-radius: 5px;"&gt;');
               if (request.fileType.indexOf('image') &gt;= 0) {
                 response.write("&lt;img src='/uploads/" + request.fileName + "' /&gt;");
               }
               else {
                 response.write("&lt;pre&gt;" + request.fileData + "&lt;/pre&gt;");
               }
               response.write("&lt;/div&gt;");
             }
             response.write("&lt;hr/&gt;");
             return response.end("&lt;div style=\"text-align: center;\"&gt;&lt;button onclick=\"history.back();\"&gt;Back&lt;/button&gt;&lt;/div&gt;");
           });
         }
         else {
           response.write("&lt;p style='color: red;'&gt;Something went wrong, looks like nothing was uploaded.&lt;/p&gt;");
           return response.end("&lt;div style=\"text-align: center;\"&gt;&lt;button onclick=\"history.back();\"&gt;Back&lt;/button&gt;&lt;/div&gt;");
         }
      });
      
#### <dfn>put</dfn>
_Usage:_

    router.put('/users', function(request, response) {
        updateUser(request.post.user, function(updated_user_id) {
        response.end(updated_user_id);})
    });                use_nsr_session: true<br/>
                avail_nsr_session_handlers: ['dispatch.memory_store', 'dispatch.text_store']<br/>
                nsr_session_handler: 'dispatch.memory_store'<br/>


#### <dfn>patch</dfn>
A variant for PUT

_Usage:_

    router.patch('/users', function(request, response) {
        updateUser(request.post.user, function(updated_user_id) {
        response.end(updated_user_id);});
    });

#### <dfn>delete</dfn>

_Usage:_

    router.delete('/users', function(request, response) {
        deleteUser(request.post.user_id, function(user_id) {
        response.end(user_id);});
    });

#### <dfn>any</dfn>
To be used when the request method is not known in advance. Sort of "catch all"

_Usage:_

    // Observe usage of 'request.body' as the union of 'request.get' and 'request.post'
    router.any('/users', function(request, response) {
        response.end("User: " + getUserById(request.body.user_id).fullName);}); 


### <dfn>Complementary methods</dfn>
 
Up to here, all the enumerated methods are directly related to <span class="nsr">NSR</span> primary activity: routing.

They are what you will use 90% of the time.

What follows are method loosely related to routing activity, but are the ones that give <span class="nsr">NSR</span> some of its distinctiveness.

#### <dfn>proxy_pass</dfn>

To deliver to the client the contents of an url from another server

_Usage:_

    router.get('/whatismyip', function(request, response) {
        router.proxy_pass('http://testing.savos.ods.org/wimi', response);});

#### <dfn><abbr title="Common Gateway Interface">cgi</abbr></dfn>

To pass the client the results of an external CGI program.

This one deserves an additional comment on its usefulness. While some - many perhaps - would argue that CGI doesn't make any sense from a Node.js development perspective, I still it's a worthy inclusion for a couple of reasons
 - First of all, you may have a legacy CGI module that you want/need to use in your brand new Node.js server - would you rewrite, for instance, Crafty, the chess engine, in Node?
 - Writing programs that can talk to each other through standard means (stdin, stdout) has passed the test of time, and I think it has it niche even in the web server world.
 - If performance is a concern - and it should be - the present considerations still stand for the next item: SCGI, which NSR also supports. But there would not have been SCGI without CGI
 - Last but not least, CGI support makes the same sense in the context of a Node.js web server thant it does in Nginx, Apache, etc.. I'm not aware of anybody suggestiong CGI support should be dropped from any of them.

_Usage:_

<samp>
    By default, any static resource having a path that includes the router option 'cgi-dir'
    (which defaults to "cgi-bin") will be treated by <span class="nsr">NSR</span>
    as a cgi program, provided the router option 'serve_cgi' is true.
    For example, the uri: `/cgi-bin/hello.py` will be handled as a CGI program.
    On the other hand, you can invoke directly the cgi method of the router, like so:
    `router.cgi('/hidden-cgi-dir/mycgi.rb', request, response);`
    Nevertheless, such way of using it is discouraged as it does not follow CGI standard
    guidelines.
</samp>

#### <dfn>scgi_pass</dfn>
                            

To pass the client the results of an external program running under the [SCGI](http://en.wikipedia.org/wiki/SCGI) protocol.

Same considerations as those pertaining to CGI, with the added benefit of not having to spawn a new process each time.

Why SCGI and not <dfn title="Fast CGI">FCGI</dfn>? Well, SCGI protocol was far easier to implement, and I really couldn't find significant performance differences between the two. FCGI may be implenented in future versions.

_Usage:_

    //Example SCGI invocation. Output will be provided by a SCGI process listening on tcp port 26000.
    router.post("/scgi", function(request, response) {
      router.scgi_pass(26000, request, response);
    });

The first parameter for scgi_pass is the port number (for tcp sockets)
or the socket name (for unix sockets) at which the SCGI process is listening.

#### <dfn>render_template</dfn>
                            

To provide rudimentary template handling without compromising the goal of keeping <span class="nsr">NSR</span> lean and simple.

Even though templating is not directly related to routing, having a micro-templating utility was considered handy.

It is basically a naive implementation of [mustache.js](http://mustache.github.io/), which tries to follow the [spec](http://mustache.github.io/mustache.5.html), but at its current stage lacks partials and lambdas. Template handling as you would with any mustache template, as shown in the following example.

_Usage:_

    router.get("/greet_user/:user_id", function(request, response) {
      get_user_by_id(request.params.user_id, function (user) {
        template_str = "&lt;h2&gt;Hello, {{ name }}!&lt;h2&gt;";
        compiled_str = router.render_template(template_str, user); // returns "&lt;h2&gt;Hello, Joe Router!&lt;h2&gt;"
        response.end(compiled_str);
      }
    });

New in version 0.8.8: `render_template_file(fileName, context, callback, keep_tokens)` was added
The method signature is almost the same than for **render_template** with 2 differences worth noting

* The first parameter is a string containing the file name, not the template string itself.

* There is a new parameter, previous to last one: a callback function with the following signature:
`cb(exists, rendered_text);`. The reason for this is that obviously file retrieval is an async IO  operation and as such it needs a callback, which **render_template** doesn't need as there is no IO involved.
                                
Obviously it would have been better to keep only one method (**render_template**), letting it guess if the first parameter is  a file name or a template string, but doing it that way would introduce a backward incompatibility since **render_template** returns a string, while becoming async would make it need a callback. So... too late to regret. It's not big deal, anyway..


#### <dfn>Session handling</dfn>


This section deals with session handling utilities built in with NSR.

<p>
    <span class="nsr">NSR</span> augments the request object with a <em>nsr_session</em> object
    unless the option <em>use_nsr_session</em> is set to a falsy value (defaults to true).<br/>
    <strong><em>nsr_session</em></strong> is a javascript object that holds the session keys and values
    defined by the application. Incidentally, the reason <span class="nsr">NSR</span> uses
    <em>request.nsr_session</em> and not <em>request.session</em> is to avoid name collision in case
    that a separate session handling mechanism is used.
</p>

<p>
    Options related to session handling:
    <ul style="list-style-type: none;">
       <li><strong>use_nsr_session</strong> Set <em>nsr_session</em> on or off</li>
       <li><strong>avail_nsr_session_handlers</strong> Low level functions that perform the real action. See below for details</li>
       <li><strong>nsr_session_handler</strong> The one handler currently selected</li>
    </ul>
</p>

<p>
    Methods related to session handling:
    <ul style="list-style-type: none;">
        <li><code>addSessionHandler(function, function_name)</code> Add your own function to the list of session handlers</li>
        <li style="margin-bottom: 1em;"><code>setSessionHandler(func_name_or_ordinal)</code> Tell <span class="nsr">NSR</span> which of the available handlers to use (defaults to 0, 'memory_store').</li>
        <li><code>getSession(request, callback)</code> Get the current <em>request.nsr_session</em>.</li>
        <li><code>setSession(request, session_object, callback)</code> Set the current <em>request.nsr_session</em> with the provided session_object.</li>
        <li><code>updateSession(request, session_object, callback)</code> Update the current <em>request.nsr_session</em> with the provided session_object, keeping not included keys and adding-updating keys present in session_object.</li>
    </ul>
    <div style="margin-top: 1em;">
        The three latter methods are convenience wrappers to access the low level method that handles <em>nsr_session</em>
        which is responsible for the real implementation of the session mechanism.<br/>
        The 3 are asynchronous, having the <em>nsr_session</em> returned as the only argument to the callback function.<br/>
        Two low level handlers are provided built in: <em>memory_store</em> (default) and <em>text_store</em> (serializes each session to a file named by the session ID)<br/>
        If you don't need/want to construct your own implementation, you don't need to know a thing
        about it, but if you want to roll your own (for instance, if you want to save sessions to a database or a remote server)
        here are a couple of things that you should keey in mind:
    </div>
    <div style="margin-top: 1em;">
      <span style="1em; padding-left: 3em;">Function signature: <code>var db_store = function(request, opcode, sess_obj, callback);</code></span><br/>
      <span style="1em; padding-left: 3em;">Having a look at the source code used in <em>memory_store</em> and <em>text_store</em> should provide a fairly good idea of how things should work</span><br/>
      <span style="1em; padding-left: 3em;">In order to put your brand new session handler to work, you have to</span><br/>
      <span style="1em; padding-left: 4em;">1) Register it with <span class="nsr">NSR</span> by means of <em>addSessionHandler</em></span><br/>
      <span style="1em; padding-left: 4em;">2) Put it to use with <em>setSessionHandler</em></span><br/>
    </div>
</p>

<p>
    You can see the session machinery in action in the <a href="http://node-simple-router.herokuapp.com/session">Session Handling</a> section of the demo site.<br/>
    By all means, review the code that makes it work in <em>test/server.js</em> or <em>test/server.coffee</em> if you are so inclined.
</p>

<div class="panel panel-primary">
    <div class="panel-heading">
        <h3 class="panel-title">Utilities</h3>
    </div>
    <div class="panel-body">
        <p>
            There are a bunch of utilities that can make your job easier, such as mk-server, the standalone tool
            that will generate a <span class="nsr">NSR</span> driven web server ready to go, cookie handling, uuid
            generation, built-in async or promises (flow-control routines), but these are - rather, will be - fully commented in
            <a target="_blank" href="https://github.com/sandy98/node-simple-router/wiki/Utils">utilities section of
            NSR wiki</a>
        </p>
    </div>
</div>

### Real time

Beginning with v0.9.0 NSR becomes real time. Now not only http requests routing is enabled, 
but also the **ws** protocol (WebSockets) is implemented.

See all the juicy details at <a target="_blank" href="https://github.com/sandy98/node-simple-router/wiki/WebSocket">WebSocket section of
            NSR wiki</a> or see it in action <a href="http://node-simple-router.herokuapp.com/sillychat.html">at the demo site.</a>

### Added goodies

Really? Need more goodies?

Ok, here we go...
 -  **Default favicon** If your app doesn't have a favicon, <span class="nsr">NSR</span> provides one for you. I _REALLY_ suggest you provide yours...
 -  **Default '404 - Not found' page.** Once again, you're advised to provide your own.
 -  **Default '500 - Server Error' page.** Same applies here.

## License

(The MIT License)

Copyright (c) 2012 Ernesto Savoretti <esavoretti@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
