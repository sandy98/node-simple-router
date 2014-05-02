require 'coffee-script/register'
fs = require 'fs'
path = require 'path'
{print} = require 'sys'
{spawn} = require 'child_process'
#utils = require("#{__dirname}#{path.sep}src#{path.sep}router")().utils
async = require("#{__dirname}#{path.sep}src#{path.sep}async")


run = (command, cb) ->
  args = command.split /\s+/g
  child = spawn args[0], args[1..]
  child.on 'error', (error) -> cb?(err, null)
  child.on 'exit', (code) ->
    print "Child process exiting with code: #{code}\n"
    cb?(null, code)
  child.stdout?.pipe? process.stdout
  child.stderr?.pipe? process.stderr

build = ->
  print "Building app\n"
  print "------------\n"
  f1 = (cb) ->
    build_src cb
  f2 = (cb) ->
    build_mk_server cb
  f3 = (cb) ->
    build_test cb
  finalCb = -> print "\nAll tasks finished.\n"
  async.series [f1, f2, f3], finalCb

build_src = (cb) ->
  print "Compiling src\n"
  run 'coffee -co lib src', cb

build_test = (cb) ->
  print "Building test/server.js\n"
  run 'coffee -c test', ->
    tmp = fs.createWriteStream("#{__dirname}#{path.sep}test#{path.sep}server.tmp", encoding: "utf8")
    tmp.write "#!/usr/bin/env node\n\n", "utf8"
    tmp.write fs.readFileSync("#{__dirname}#{path.sep}test#{path.sep}server.js", encoding: "utf8"), "utf8"
    tmp.end()
    fs.unlinkSync "#{__dirname}#{path.sep}test#{path.sep}server.js"
    fs.renameSync "#{__dirname}#{path.sep}test#{path.sep}server.tmp", "#{__dirname}#{path.sep}test#{path.sep}server.js"
    fs.chmodSync "#{__dirname}#{path.sep}test#{path.sep}server.js", 0o755
    cb?(null, "test/server.js built")

build_mk_server = (cb) ->
  print "Building bin/mk-server\n"
  mk_server = fs.createWriteStream("#{__dirname}#{path.sep}bin#{path.sep}mk-server", encoding: 'utf8')
  mk_server.write "#!/usr/bin/env node\n\n"
  mk_server.write fs.readFileSync("#{__dirname}#{path.sep}lib#{path.sep}mk-server.js", encoding: "utf8"), "utf8"
  mk_server.end()
  fs.chmodSync "#{__dirname}#{path.sep}bin#{path.sep}mk-server", 0o755
  fs.unlinkSync "#{__dirname}#{path.sep}lib#{path.sep}mk-server.js"
  cb?(null, "mk-server built")

test = (cb) ->
  print "Trying test/server.js\n"
  f1 = (cb) ->
    build_test cb
  f2 = (cb) ->
    #console.log "CONSOLE: Going to run test/server.js"
    run "node test/server.js", cb

  if (not fs.existsSync('test/server.js'))
    print "test/server.js does not exist, going to create it...\n"
    return async.series [f1, f2], (err, results) -> print "RESULTS: #{err or results}\n"
  else
    #console.log "CONSOLE: comparing test/server.coffee and test/server.js"
    statCoffee = fs.statSync 'test/server.coffee'
    statJs = fs.statSync 'test/server.js'
    timeCoffee = statCoffee.mtime.getTime()
    timeJs = statJs.mtime.getTime()
    #console.log "CONSOLE: coffee millis: #{timeCoffee}. js millis: #{timeJs}. Dif: #{timeJs - timeCoffee}"
    if (timeJs <= timeCoffee)
      print "test/server.js is old, recompiling...\n"
      return async.series [f1, f2], (err, results) -> print "RESULTS: #{err or results}\n"
    else
      return f2()

task "build", "Builds the app", ->
  build()

task "build_src", "Compiles src", ->
  build_src -> print "Source files compiled.\n"

task "build_test", "Builds test/server.js", ->
  build_test  -> print "test/server.js built.\n"

task "build_mk_server", "Builds bin/mk-server", ->
  build_mk_server -> print "bin/mk-server built.\n"

task "test", "Checks existence/validity of test/server.js and recompiles if necessary, then run it", ->
  test -> print "test/server.js ran OK."

task "version", "Shows current version of the project", ->
  #if arguments.length is 1
    console.log "NSR version: #{require('./package.json').version}"
  #else
    #json = require './package.json'
    #console.log "NSR current version: #{json.version}"
    #json.version = arguments[1]
    #fs.writeFileSync './package.json', JSON.stringify json, 'utf8'
    #console.log "NSR version set to: #{json.version}"
