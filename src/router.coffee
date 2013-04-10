# Router object, invocation returns a function meant to dispatch  http requests.
Router = (options = {}) ->

# Required modules, all of them from standard node library, no external dependencies.	

  urlparse = require('url').parse
  querystring = require('querystring')
  fs       = require('fs')
  path_tools = require('path')
#  util      = require('util')
  spawn  = require('child_process').spawn

# End of required modules


# Constants.	

  mime_types =
    '':      'application/octet-stream'
    '.bin':   'application/octet-stream'
    '.com':   'application/x-msdownload'
    '.exe':   'application/x-msdownload'
    '.htm':  'text/html'
    '.html': 'text/html'
    '.txt':  'text/plain'
    '.css':  'text/css'
    '.mid':  'audio/midi'
    '.midi': 'audio/midi'
    '.wav':  'audio/x-wav'
    '.mp3':  'audio/mpeg'
    '.ogg':  'audio/ogg'
    '.mp4':  'video/mp4'
    '.mpeg': 'video/mpeg'
    '.avi':  'video/x-msvideo'
    '.pct':  'image/pict'
    '.pic':  'image/pict'
    '.pict': 'image/pict'
    '.ico' : 'image/x-icon'
    '.jpg':  'image/jpg'
    '.jpeg': 'image/jpg'
    '.png':  'image/png'
    '.gif' : 'image/gif'
    '.pcx':  'image/x-pcx'
    '.tiff': 'image/tiff'
    '.svg':  'image/svg+xml'
    '.xul':  'text/xul'
    '.rtf':  'application/rtf'
    '.xls':  'application/vnd.ms-excel'
    '.xml':  'application/xml'
    '.doc':  'application/msword'
    '.pdf':  'application/pdf'
    '.mobi': 'application/x-mobipocket-ebook'
    '.epub': 'application/epub+zip'
    '.js':   'application/x-javascript'
    '.json': 'application/json'
    '.sh':   'text/x-sh'
    '.py':   'text/x-python'
    '.rb':   'text/x-ruby'
    '.c':    'text/x-csrc'
    '.cpp':  'text/x-c++src'

  default_options =
    logging: true
    log: console.log
    static_route: "#{process.cwd()}/public"
    serve_static: true
    list_dir: true
    default_home: ['index.html', 'index.htm', 'default.htm']
    cgi_dir: "cgi-bin"
    serve_cgi: true
    served_by: 'Node Simple Router'
    version: '0.3.4'

# End of Constants.


# Auxiliary functions.	

  _extend = (obj_destiny, obj_src) ->
    for key, val of obj_src
      obj_destiny[key] = val
    obj_destiny

  _parsePattern = (pat) ->
    re = /\/:([A-Za-z0-9_]+)+/g
    m = pat.match(re)
    if m
      pars = (x.slice(2) for x in m)
      retpat = pat.replace(re, "/([A-Za-z0-9_\-]+)")
    else
      retpat = pat
      pars = null
    {pattern: retpat, params: pars}
  
  _make_request_wrapper = (cb) ->
    wrapper = (req, res) ->
      body = []
      req.setEncoding('binary')
      req.on 'data', (chunk) ->
        body.push chunk
      req.on 'end', () ->
        body = body.join('')
        contentType = 'application/x-www-form-urlencoded'
        if req.headers['content-type']
          contentType = req.headers['content-type']
        if contentType is 'text/plain'
          body = body.replace('\r\n', '')
        mp_index = contentType.indexOf('multipart/form-data')
        req.post = if mp_index is -1 then _bodyparser(body) else _multipartparser(body, contentType)
        req.body = _extend req.body, req.post
        try
          cb(req, res)
        catch e
          dispatch._500 req, res, req.url, e.toString()
    wrapper

# End of Auxiliary functions.	


# Dispatcher (router) function.	

  dispatch = (req, res) ->
    parsed = urlparse(req.url)
    pathname = parsed.pathname
    req.get = if parsed.query? then querystring.parse(parsed.query) else {}
    req.body = _extend {}, req.get
    method = req.method.toLowerCase()
    if dispatch.logging
      dispatch.log "#{req.client.remoteAddress} - [#{new Date().toLocaleString()}] - #{method.toUpperCase()} #{pathname} - HTTP #{req.httpVersion}"
    for route in dispatch.routes[method]
      m = pathname.match(route.pattern)
      if m isnt null
        if route.params
          req.params = {}
          args = m.slice(1)
          for param, index in route.params
            req.params[param] = args[index]
        return route.handler(req, res)

    if pathname is "/"
      for home_page in dispatch.default_home
        full_path = "#{dispatch.static_route}/#{home_page}"
        try
          if fs.existsSync full_path
            return dispatch.static "/#{home_page}", req, res
        catch error
          dispatch.log error.toString() unless not dispatch.logging
      if dispatch.list_dir
        return dispatch.directory dispatch.static_route, '.', res
      else
        return dispatch._404 req, res, pathname

    if dispatch.serve_static
      return dispatch.static pathname, req, res
    else
      return dispatch._404 req, res, pathname

# End of Dispatcher (router) function.	


# Extends default options with client provided ones, and then using that extends dispatcher function itself.	

  _extend(default_options, options)
  _extend(dispatch, default_options)

# End of Extends default options with client provided ones, and then using that extends dispatcher function itself.	


# Directory listing template	

  _dirlist_template = """
      <!DOCTYPE  html>
      <html>
        <head>
            <title>Directory listing for <%= @cwd %></title>
            <style type="text/css" media="screen">

            </style>
        </head>
        <body>
            <h2>Directory listing for <%= @cwd %></h2>
            <hr/>
            <ul id="dircontents">
              <%= @cwd_contents %>
            </ul>
            <hr/>
            <p><strong>Served by #{dispatch.served_by} v#{dispatch.version}</strong></p>
        </body>
      </html>
      """

# End of Directory listing template	


# Dispatch object methods, not meant to be called/used by the client.	

  _pushRoute = (pattern, callback, method) ->
    params = null
    if typeof pattern is "string"
      parsed = _parsePattern(pattern)
      pattern = new RegExp("^#{parsed.pattern}$")
      params = parsed.params
    dispatch.routes[method].push {pattern: pattern, handler: callback, params: params}
    dispatch.routes[method].sort (it1, it2) -> it2.pattern.toString().length > it1.pattern.toString().length


  _multipartparser = (body, content_type) ->
    resp = "multipart-data": []
    boundary = content_type.split(/;\s+/)[1].split('=')[1].trim()
    parts = body.split("--#{boundary}")
    for part in parts
      if part and part.match(/Content-Disposition:/i)
        #dispatch.log "PART: #{part}"
        obj = {}
        m = part.match(/Content-Disposition:\s+(.+?);/i)
        if m
          obj.contentDisposition = m[1]
        m = part.match(/name="(.+?)"/i)
        if m
          obj.fieldName = m[1]
        m = part.match(/filename="(.+?)"/i)
        if m
          obj.fileName = m[1]
        m = part.match(/Content-Type:\s+(.+?)\s/i)
        if m
          obj.contentType = m[1]
        else
          obj.contentType = 'text/plain'
        m = part.match(/Content-Length:\s+(\d+?)/i)
        if m
          obj.contentLength = m[1]

        m = part.match /\r\n\r\n/
        if m
          obj.fileData = part.slice(m.index + 4, -2)
          obj.fileLen = obj.fileData.length
        
        resp['multipart-data'].push obj     
    resp

  _bodyparser = (body) ->
    if body.indexOf('=') isnt -1
      try
        return querystring.parse(body)
      catch e
        dispatch.log e unless not dispatch.logging
    try
      return JSON.parse(body)
    catch e
      dispatch.log e unless not dispatch.logging
    body

# End of Dispatch object methods, not meant to be called/used by the client.	


# Dispatch function properties and methods 	

  dispatch.routes =
    get:  []
    post: []
    put:  []
    delete:  []

  dispatch.static = (pathname, req, res) ->
    if pathname.indexOf("#{dispatch.cgi_dir}/") isnt - 1 and dispatch.serve_cgi is true
     return dispatch.cgi(pathname, req, res)
    full_path = "#{dispatch.static_route}#{pathname}"
    fs.stat full_path, (err, stats) ->
      if err
        dispatch.log err.toString() unless not dispatch.logging
        return dispatch._404 null, res, pathname
      if stats
        if stats.isDirectory()
          return dispatch.directory(full_path, pathname, res) unless not dispatch.list_dir
          return dispatch._405(null, res, pathname, "Directory listing not allowed")
        if stats.isFile()
          fd = fs.createReadStream full_path
          res.writeHead 200, {'Content-Type': mime_types[path_tools.extname(full_path)] or 'text/plain'}
          fd.pipe res
#          util.pump fd, res, (err) ->
#            dispatch.log err.toString() unless (not err or not dispatch.logging )


# CGI support (improved on 2012-09-07)

  dispatch.cgi = (pathname, req, res) ->
      try
        full_path = "#{dispatch.static_route}#{pathname}"
        child = spawn full_path

        body = []

        if req.method.toLowerCase() is "post"
          req.on 'data', (chunk) ->
            body.push(chunk)
          req.on 'end', ->
            body = body.join ''
            req.post = _bodyparser body
            req.body = _extend req.body, req.post
            child.stdin.write("#{JSON.stringify(req.body)}\n")
        else
          child.stdin.write("#{JSON.stringify(req.body)}\n")

        child.stderr.pipe(process.stderr);

        child.stdout.on 'data', (data) ->
          arrdata = data.toString().split('\n')
          for elem in arrdata
            if (elem.substr(0,8).toLowerCase() isnt "content-")
              res.write elem
            else
              pair = elem.split(/:\s+/)
              res.setHeader(pair[0], pair[1])

        child.stdout.on 'end', ->
          res.end()

      catch error
        dispatch._500 null, res, pathname, error.toString() 

# End of CGI support

  dispatch.directory = (fpath, path, res) ->
    resp = _dirlist_template
    resp = resp.replace("<%= @cwd %>", path) while resp.indexOf("<%= @cwd %>") isnt -1
    fs.readdir fpath, (err, files) ->
      if err
        return dispatch._404(null, res, path)
      else
        links = ("<li><a href='#{path}/#{querystring.escape(file)}'>#{file}</a></li>" for file in files).join('')
        resp = resp.replace("<%= @cwd_contents %>", links)
      res.writeHead 200, {'Content-type': 'text/html'}
      res.end resp


  dispatch.get = (pattern, callback) ->
      _pushRoute pattern, callback, 'get'

  dispatch.post = (pattern, callback) ->
    _pushRoute pattern, _make_request_wrapper(callback), 'post'

  dispatch.put = (pattern, callback) ->
    _pushRoute pattern, _make_request_wrapper(callback), 'put'

  dispatch.delete = (pattern, callback) ->
    _pushRoute pattern, callback, 'delete'

  dispatch.del = (pattern, callback) ->
    _pushRoute pattern, callback, 'delete'


  dispatch._404 = (req, res, path) ->
    res.writeHead(404, {'Content-Type': 'text/html'})
    res.end("""
            <h2>404 - Resource #{path} not found at this server</h2>
            <hr/><h3>Served by #{dispatch.served_by} v#{dispatch.version}</h3>
            <p style="text-align: center;"><button onclick='history.back();'>Back</button></p>
        """)

  dispatch._405 = (req, res, path, message) ->
    res.writeHead(405, {'Content-Type': 'text/html'})
    res.end("""
                <h2>405 - Resource #{path}: #{message}</h2>
                <hr/><h3>Served by #{dispatch.served_by} v#{dispatch.version}</h3>
                <p style="text-align: center;"><button onclick='history.back();'>Back</button></p>
            """)

  dispatch._500 = (req, res, path, message) ->
    res.writeHead(500, {'Content-Type': 'text/html'})
    res.end("""
                <h2>500 - Internal server error at #{path}: #{message}</h2>
                <hr/><h3>Served by #{dispatch.served_by} v#{dispatch.version}</h3>
              <p style="text-align: center;"><button onclick='history.back();'>Back</button></p>
            """)

# End of Dispatch function properties and methods 	


# Returns dispatch (router function)	    
  dispatch


# Exports "router factory function"
module.exports = Router
