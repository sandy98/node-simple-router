# Router object, invocation returns a function meant to dispatch  http requests

Router = (options = {}) ->

  urlparse = require('url').parse
  querystring = require('querystring')
  fs       = require('fs')
  util      = require('util')
  path_tools      = require('path')

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
    '.rtf':  'application/rtf'
    '.xls':  'application/vnd.ms-excel'
    '.xul':  'text/xul'
    '.doc':  'application/msword'
    '.pdf':  'application/pdf'
    '.js':   'text/x-javascript'
    '.json': 'text/x-json'
    '.sh':   'application/x-sh'
    '.py':   'text/x-python'
    '.rb':   'text/x-ruby'


  dispatch = (req, res) ->
    done = false
    parsed = urlparse(req.url)
    pathname = parsed.pathname
    req.get = if parsed.query? then querystring.parse(parsed.query) else {}
    req.body = _extend {}, req.get
    method = req.method.toLowerCase()
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
      return dispatch.static "/index.html", res
    if dispatch.serve_static
      return dispatch.static pathname, res
    else
      return dispatch._404 req, res, pathname

  dispatch.version = '0.1.5'

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
            <p><strong>Served by Node Simple Router v#{dispatch.version}</strong></p>
        </body>
      </html>
      """

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

  _pushRoute = (pattern, callback, method) ->
    params = null
    if typeof pattern is "string"
      parsed = _parsePattern(pattern)
      pattern = new RegExp("^#{parsed.pattern}$")
      params = parsed.params
    dispatch.routes[method].push {pattern: pattern, handler: callback, params: params}
    dispatch.routes[method].sort (it1, it2) -> it2.pattern.toString().length > it1.pattern.toString().length

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


  _make_request_wrapper = (cb) ->
    wrapper = (req, res) ->
      body = []
      req.on 'data', (chunk) ->
        body.push chunk
      req.on 'end', () ->
        body = body.join('')
        req.post = _bodyparser body
        req.body = _extend req.body, req.post
        cb(req, res)
    wrapper

  dispatch.static = (pathname, res) ->
    full_path = "#{dispatch.static_route}#{pathname}"
    dispatch.log "trying static #{full_path}" unless not dispatch.logging
    fs.stat full_path, (err, stats) ->
      if err
        dispatch.log err.toString() unless not dispatch.logging
        return dispatch._404 null, res, pathname
      if stats
        done = true
        if stats.isDirectory()
          return dispatch.directory(full_path, pathname, res) unless not dispatch.list_dir
          return dispatch._405(null, res, pathname, "Directory listing not allowed")
        if stats.isFile()
          fd = fs.createReadStream full_path
#          res.writeHead 200, {'Content-Type': if pathname[0] is "/" then pathname.substring(1) else pathname}
          res.writeHead 200, {'Content-Type': mime_types[path_tools.extname(full_path)] or 'text/plain'}
          util.pump fd, res, (err) ->
            dispatch.log err.toString() unless (not err or not dispatch.logging )

  dispatch.directory = (fpath, path, res) ->
    resp = _dirlist_template
    resp = resp.replace("<%= @cwd %>", path) while resp.indexOf("<%= @cwd %>") isnt -1
    fs.readdir fpath, (err, files) ->
      if err
        return dispatch._404(null, res, path)
      else
        links = ("<li><a href='#{path}/#{file}'>#{file}</a></li>" for file in files).join('')
        resp = resp.replace("<%= @cwd_contents %>", links)
      res.writeHead 200, {'Content-type': 'text/html'}
      res.end resp

  default_options =
    logging: true
    log: console.log
    static_route: "#{__dirname}/public"
    serve_static: true
    list_dir: true

  _extend(default_options, options)
  _extend(dispatch, default_options)

  dispatch.routes =
    get:  []
    post: []
    put:  []
    delete:  []

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
            <hr/><h3>Node Simple Router v#{dispatch.version}</h3>
            <p style="text-align: center;"><button onclick='history.back();'>Back</button></p>
        """)

  dispatch._405 = (req, res, path, message) ->
    res.writeHead(405, {'Content-Type': 'text/html'})
    res.end("""
                <h2>405 - Resource #{path}: #{message}</h2>
                <hr/><h3>Node Simple Router v#{dispatch.version}</h3>
                <p style="text-align: center;"><button onclick='history.back();'>Back</button></p>
            """)


  dispatch



module.exports = Router
