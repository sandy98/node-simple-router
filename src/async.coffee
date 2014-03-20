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

