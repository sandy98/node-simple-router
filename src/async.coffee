_argumentsToArray = ->
  ret = []
  for arg in arguments
    ret.push arg
  ret
      
async = {}

defaultFinalCb = (err, result) ->
  if arguments.length is 1
    result = err
    err = null
  if err then err else result

async.some = (arr, asyncFunc, finalCb) ->
  if not finalCb
    finalCb = defaultFinalCb
  if arr.length is 0
    return finalCb(false)
  else
    asyncFunc arr[0], (err, resp) ->
      if arguments.length is 1
        resp = err
        err = null
      if err
        return finalCb(err, null)
      if !!resp
        return finalCb(!!resp)
      else
        return async.some arr.slice(1), asyncFunc, finalCb

async.every = (arr, asyncFunc, finalCb) ->
  if not finalCb
    finalCb = defaultFinalCb
  if arr.length is 0
    return finalCb(true)
  else
    asyncFunc arr[0], (err, resp) ->
      if arguments.length is 1
        resp = err
        err = null
      if err
        return finalCb(err, null)
      if not resp
        return finalCb(!!resp)
      else
        return async.every arr.slice(1), asyncFunc, finalCb

async.map = (arr, asyncFunc, finalCb, asyncArr = []) ->
  if not finalCb
    finalCb = defaultFinalCb
  if arr.length is 0
    return finalCb(null, asyncArr)
  else
    asyncFunc arr[0], (err, resp) ->
      if arguments.length is 1
        resp = err
        err = null
      if err
        return finalCb err, null
      asyncArr.push resp
      return async.map arr.slice(1), asyncFunc, finalCb, asyncArr

async.filter = (arr, asyncFunc, finalCb, asyncArr = []) ->
  if not finalCb
    finalCb = defaultFinalCb
  if arr.length is 0
    return finalCb(null, asyncArr)
  else
    asyncFunc arr[0], (err, resp) ->
      if arguments.length is 1
        resp = err
        err = null
      if err
        return finalCb err, null
      asyncArr.push arr[0] if !!resp
      return async.filter arr.slice(1), asyncFunc, finalCb, asyncArr

async.reduce = (arr, asyncFunc, acum = 0, finalCb) ->
  if not finalCb
    finalCb = defaultFinalCb
  if arr.length is 0
    return finalCb(null, acum)
  else
    asyncFunc acum, arr[0], (err, resp) ->
      if arguments.length is 1
        resp = err
        err = null
      if err
        return finalCb err, null
      acum = resp
      return async.reduce arr.slice(1), asyncFunc, acum, finalCb


async.waterfall = (funcArr, finalCb, args = null) ->
  if not finalCb
    finalCb = defaultFinalCb
  
  cb = (err, args) ->
    if arguments.length is 1
      args = err
      err = null
    if err
      return finalCb(err, null)
    else
      return async.waterfall funcArr.slice(1), finalCb, args
               
  if funcArr.length is 0
    return finalCb null, args
  else
    return funcArr[0] args, cb
  

async.series = (funcArr, finalCb, results = []) ->
  
  if not finalCb
    finalCb = defaultFinalCb
  
  cb = (err, args) ->
    if arguments.length is 1
      args = err
      err = null
    if err
      return finalCb(err, results)
    else
      results.push args
      async.series funcArr.slice(1), finalCb, results
                           
  if funcArr.length is 0
    return finalCb null, results
  else
    funcArr[0] cb
    #return async.series funcArr.slice(1), finalCb, results             


async.parallel = (funcArr, finalCb) ->

  if not finalCb
    finalCb = defaultFinalCb
    
  completed = 0
  len = funcArr.length
  results = new Array(len)

  make_parallel_cb = (index) ->
    (err, args) ->
      if arguments.length is 1
        args = err
        err = null
      if err
        return finalCb(err, results)
      else
        results[index] = args
        completed += 1
        if completed is len
          finalCb null, results
  
  for fn, index in funcArr
    fn make_parallel_cb(index)

  undefined
                             
  
module.exports = async


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

      
      fs = require 'fs'
      readDir = (arg, cb) ->
        fs.readdir process.cwd(), (err, files) ->
          if err
            console.log "ERROR reading directory: "
          else
            console.log "Current working directory: #{process.cwd()}\n"

          if err then cb(err, null) else cb(files)
          
        console.log "Running file system test function"
        console.log "---------------------------------\n"
      
      async.waterfall(
        [
          readDir
          (files, cb) ->
            len = files.length - 1
            stats = []
            files.forEach (file, index) ->
              fs.stat file, (err, stat) ->
                return cb(err, null) if err
                stats[index] = stat
                if index is len
                  console.log "Retrieved", stats.length, "items.\n"
                  cb [files, stats]
          (arrs, cb) ->
            [files, stats] = arrs
            fileSizes = []
            for file, index in files
              fileSizes.push name: ('' + file + if stats[index]?.isDirectory() then ' [DIR]' else ''), size: stats[index]?.size, isFile: stats[index]?.isFile()
            fileSizes.sort (info1, info2) -> info1.isFile - info2.isFile
            for fileInfo in fileSizes
              console.log pad(fileInfo.name, 40), "   ---   ", pad(thousand_sep(fileInfo.size), 40, "l"), "bytes."
            cb(fileSizes)
        ]
        (err, fileSizes) ->
          if err
            console.log "An error happened: #{err.message}"
          else
            info = "\nTotal Size of files in #{process.cwd()}: "
            info += "#{thousand_sep(fileSizes.reduce ((acum, fileInfo) -> acum + if fileInfo.isFile then fileInfo.size else 0), 0)} bytes.\n"
            console.log info
      )

      

