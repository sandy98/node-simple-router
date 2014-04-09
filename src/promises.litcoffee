
########################################################################################################################################


# The Promise Resolution Procedure

    resolve = (promise, x) ->

## If promise and x refer to the same object, reject promise with a TypeError as the reason.
    
      if promise is x
        return reject promise, new TypeError "promise and resolution value can't be the same object"

## If x is a promise, adopt its state
      
      if x?.constructor.name is 'Promise'
        if x.isPending()
          return x._dependants.push promise
        if x.isFulfilled()
          return fulfill promise, x.value
        if x.isRejected()
          return reject promise, x.reason
      
## If x is an object or a function
## Pending for now...


## Else, fulfill this way...

      #console.log "resolve: fulfilling promise with", x
      return fulfill promise, x
        

########################################################################################################################################

# Fulfillment Procedure

    fulfill = (promise, value) ->
      return promise unless promise.isPending()
      promise._state = Promise.states.fulfilled
      promise._value = value
      fireHandlers promise, value
      promise._dependants.forEach (dependant) ->
        resolve dependant, value
      promise

########################################################################################################################################

# Rejection Procedure

    reject = (promise, reason) ->
      return promise unless promise.isPending()
      promise._state = Promise.states.rejected
      promise._reason = reason
      fireHandlers promise, reason
      promise._dependants.forEach (dependant) ->
        reject dependant, reason
      promise

########################################################################################################################################


# fireHandlers Procedure

    fireHandlers = (promise, what) ->
        switch promise._state
          when Promise.states.rejected
            handlers = promise._rejectHandlers
          when Promise.states.fulfilled
            handlers = promise._fulfillHandlers
          else
            return
        
        handlers.forEach (handler, index) ->
          return if promise._handlerCalls[index] isnt 0
          promise._handlerCalls[index] += 1
          cascade_promise = promise._retPromises[index]
          if handler?.constructor.name is "Function"
            #setImmediate ->
            #console.log "Resolving cascade promise through handler invocation result"
            try
              result = handler what
              #console.log "Result of handler invocation is #{result}"
              if promise._state is Promise.states.fulfilled
                resolve cascade_promise, result
              else
                reject cascade_promise, result
            catch e
              reject cascade_promise, e
          else
            #console.log "Resolving cascade promise with received argument (named what)"
            if promise._state is Promise.states.fulfilled
              resolve cascade_promise, what
            else
              reject cascade_promise, what
        promise

########################################################################################################################################


# The Promise class

    class Promise
      "Returns a promise object which complies (really?) with promises A+ spec"

      @states: {pending: 0, rejected: -1, fulfilled: 1}

## ** Define value and reason getters

      Object.defineProperties @prototype,
        value:
          get: -> @_value
        reason:
          get: -> @_reason
        state:
          get: -> @_state
      
## **constructor/initializer** method of Promise class

      constructor: (@_options = {}) ->
        Promise.init @
        
      @init: (obj) ->
        obj._state = Promise.states.pending
        obj._fulfillHandlers = []
        obj._rejectHandlers = []
        obj._retPromises = []
        obj._handlerCalls = []
        obj._dependants = []

        obj
        
## **then** method of Promise class

      then: (onFulfilled, onRejected) =>
        @_fulfillHandlers.push onFulfilled or null
        @_rejectHandlers.push onRejected or null
        retPromise = new Promise level: @_options.level + 1
        @_retPromises.push retPromise
        if @isPending()
          @_handlerCalls.push 0
        else
          @_handlerCalls.push 1
          if @isRejected()
            reject retPromise, @_reason
          if @isFulfilled()
            if onFulfilled?.constructor.name is "Function"
              resolve retPromise, onFulfilled(@_value)
            else
              resolve retPromise, @_value
              
        #console.log "Returning from Promise.then a new promise with level: #{retPromise._options.level}"
        retPromise

## **done, fail** sugar methods for calling then

      done: (onFulfilled) =>
        @then onFulfilled, null
    
      fail: (onRejected) =>
        @then null, onRejected
        
## **utility methods** of Promise object

      isRejected: =>
        if @_state is Promise.states.rejected then true else false

      isFulfilled: =>
        if @_state is Promise.states.fulfilled then true else false

      isPending: =>
        if @_state is Promise.states.pending then true else false

      isResolved: =>
        not @isPending()


# The Deferred class

    class Deferred
      "Promise manager object"

      constructor: ->
        @_promise = new Promise level: 0

      promise: =>
        @_promise

      resolve: (value) =>
        setImmediate =>
          return if not @_promise.isPending()
          resolve @_promise, value

      reject: (reason) =>
        setImmediate =>
          return if not @_promise.isPending()
          reject @_promise, reason


# The Deferred creation function

    defer = ->
      new Deferred



# Exports PromiseA Object

    module?.exports = PromiseA = {Promise, Deferred, defer}


## End of objects definition, beginning of  tests


# Run standalone test if it isnt being required

    if not module?.parent

      thousand_sep = (num, sep = ",") ->
        return num.toString() unless num.toString().length > 3
        resp = num.toString().split('').reverse().join('').replace(/(\d{3})/g, "$1#{sep}").split('').reverse().join('')
        if resp.charAt(0) is sep then resp.slice(1) else resp

      pad = (stri, quantity, direction = "r", padchar = " ") ->
        stri = stri.toString() if stri.constructor.name is "Number"
        len = stri.length
        dif = quantity - len
        return stri if dif <= 0
        padstri = (padchar for n in [1..dif]).join ''
        if direction is "r" then "#{stri}#{padstri}" else "#{padstri}#{stri}"

      testFunc = ->
        #util = require 'util'
        d = defer()
        setTimeout ( -> d.resolve 10), 100
        p = d.promise()
        ###
        setTimeout (->
          console.log "\n"
          console.log util.inspect p._fulfillHandlers
          console.log util.inspect p._retPromises[0]?._fulfillHandlers
          console.log util.inspect p._retPromises[0]?._retPromises[0]?._fulfillHandlers
          console.log "\n"), 50
        ###
        console.log "Running test function"
        console.log "---------------------\n"
        p

      ###  
      testFunc()
      .then(
        (number) ->
          console.log "Promise level 0 received number #{number}"
          number + 1
        (err) =>
          console.log  "First promise triggered an error:", err.toString()
      )
      .then(
         (number) ->
           console.log "Promise level 1 received number #{number}"
           number + 1
      )
      .then(
         (number) ->
           console.log "Promise level 2 received number #{number}"
           number * 3
      )
      .then(
         (resp) ->
           console.log "Promise level 3 received number #{resp}"
           resp
      )
      ###
      
      fs = require 'fs'
      readDir = ->
        d = defer()
        fs.readdir process.cwd(), (err, files) ->
          if err
            console.log "ERROR reading directory: "
          else
            console.log "Current working directory: #{process.cwd()}\n"

          if err then d.reject err else d.resolve files
          
        console.log "Running file system test function"
        console.log "---------------------------------\n"
        d.promise()
      
      readDir()
      .then(
        (files) ->
          len = files.length - 1
          stats = []
          d = defer()
          p = d.promise()
          files.forEach (file, index) ->
            fs.stat file, (err, stat) ->
              return d.reject err if err
              stats[index] = stat
              if index is len
                console.log "Retrieved", stats.length, "items.\n"
                d.resolve [files, stats]
          p
        (err) -> console.log "ERROR reading current directory: #{err.message}"
      )
      .then(
        (arrs) ->
          [files, stats] = arrs
          fileSizes = []
          for file, index in files
            fileSizes.push name: ('' + file + if stats[index]?.isDirectory() then ' [DIR]' else ''), size: stats[index]?.size, isFile: stats[index]?.isFile()
          fileSizes.sort (info1, info2) -> info1.isFile - info2.isFile
          for fileInfo in fileSizes
            console.log pad(fileInfo.name, 40), "   ---   ", pad(thousand_sep(fileInfo.size), 40, "l"), "bytes."
          fileSizes
        (err) -> console.log "Something horrible happened while processing file names and stats:", err.message
      )
      .then(
        (fileSizes) ->
          info = "\nTotal Size of files in #{process.cwd()}: "
          info += "#{thousand_sep(fileSizes.reduce ((acum, fileInfo) -> acum + if fileInfo.isFile then fileInfo.size else 0), 0)} bytes.\n"
          console.log info
        (err) -> console.log "Something horrible happened while processing total files size:", err.message
 
      )
        

      
