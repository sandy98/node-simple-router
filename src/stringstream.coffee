util = require 'util'
Duplex = require('stream').Duplex

StringStream = (value, options) ->
  Duplex.call @, options
  @value = value or ''
  @defaultEncoding = options?.encoding or 'utf8'
  @decodeStrings = options?.decodeStrings or false

util.inherits StringStream, Duplex
  
Object.defineProperties StringStream.prototype,
  value:
    get: ->
      @_value
    set: (newValue) -> 
      @_value = newValue
      @_value
            

StringStream.prototype._write = (chunk, encoding, cb) ->
  encoding = encoding or @defaultEncoding
  if encoding isnt @encoding
    chunk = chunk.toString @defaultEncoding
  @value += chunk
  cb?()

    
StringStream.prototype._read = () ->
  @push @value, @defaultEncoding
  #@emit 'data', @value
  #@emit 'end'
  @push null
    
StringStream.prototype.toString = () ->
  @value

StringStream.prototype.transform = (fn) ->
  @value = fn(@value)
  @
        
module?.exports = StringStream

if not module?.parent
  sstream = new StringStream 'Hello, World!!!'
  sstream.pause()
  console.log "sstream is a StringStream which has a value of '#{sstream.value}'"
  sstream.write " I am a StringStream, that is, I am a String but I'm also a Stream!"
  sstream.on 'end', -> console.log 'sstream ended'
  sstream.on 'data', (data) -> console.log 'sstream.sent:', data.toString('utf8')
  console.log "Now wait 3 seconds, please..."
  setTimeout (-> sstream.resume()), 3000

