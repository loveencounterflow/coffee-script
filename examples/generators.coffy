


############################################################################################################
# ERROR                     = require 'coffeenode-stacktrace'
njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
log                       = console.log
rpr                       = njs_util.inspect

#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
after = ( time_s, handler ) ->
  ### `after` is a thin shim around `setTimeout` that adheres to NodeJS conventions, taking a `handler`
  callback function as last argument. Also, the timeout is given in humane seconds rather than in ms. ###
  setTimeout handler, time_s * 1000
  return null

#-----------------------------------------------------------------------------------------------------------
eventually = ( handler ) ->
  ### `eventually f` is just another name for `process.nextTick f`—which in turn is basically equivalent to
  `after 0, f`. ###
  return process.nextTick handler


### TAINT not a test suite just yet, just an example ###

#-----------------------------------------------------------------------------------------------------------
fibonacci = ->
  walk_fibonacci = ->*
    a = 1
    b = 1
    loop
      c = a + b
      return c if c > 1e+20
      yield c
      a = b
      b = c

  g = walk_fibonacci()

  loop
    { value, done } = g.next()
    break if done
    log value

#-----------------------------------------------------------------------------------------------------------
fibonacci_with_throw = ->
  walk_fibonacci = ->*
    a = 1
    b = 1
    loop
      try
        c = a + b
        return c if c > 1e+20
        yield c
        a = b
        b = c
      catch error
        log 'CAUGHT ERROR IN GENERATOR:', error
        return "it's over!"

  g = walk_fibonacci()

  loop
    { value, done } = g.next()
    if done
      log 'terminated'
      break
    { value, done } = g.throw new Error "144!!!!" if value is 144
    if done
      log 'received value:', rpr value
      log 'aborted'
      break
    log value

#-----------------------------------------------------------------------------------------------------------
fibonacci_with_send = ->
  walk_fibonacci = ( a, b ) ->*
    initial_a = a ?= 1
    initial_b = b ?= 1
    loop
      c = a + b
      r = yield c
      if r
        a = initial_a
        b = initial_b
      else
        a = b
        b = c

  g       = walk_fibonacci 3, 1
  restart = undefined

  for idx in [ 0 ... 100 ]
    { value, done } = g.send restart
    restart         = value > 100
    break if done
    log value

#-----------------------------------------------------------------------------------------------------------
stepper_with_timeouts_1 = ->
  stepper_with_timeouts = ->*
    log "after"
    yield after 1, -> log '1'
    log "a"

  g = stepper_with_timeouts()
  g.next()
  # g.next()

#-----------------------------------------------------------------------------------------------------------
stepper_with_timeouts_2 = ->

  resume = ->
    g.next()

  stepper_with_timeouts = ->*
    log "after"
    yield after 1, resume
    log "a"
    yield after 1, resume
    log "long"
    yield after 1, resume
    log "time"

  g = stepper_with_timeouts()
  g.next()

#-----------------------------------------------------------------------------------------------------------
read_a_file = ->

  read_file = ( route, handler ) ->
    ### Given the location of a file, read and decode it using UTF-8, then call the handler
    as `handler error, data`. ###
    ( require 'fs' ).readFile __filename, 'utf-8', handler
    return null

  resume = ( error, data ) ->
    ### Send results to generator. ###
    g.send [ error, data, ]

  log_character_count = ( route ) ->*
    ### Given a `route`, retrieve the text of that file and print out its character count. ###
    [ error, text ] = yield read_file route, resume
    log "file #{__filename} is #{text.length} characters long."

  g = log_character_count __filename
  g.next()



############################################################################################################
# fibonacci()
# fibonacci_with_throw()
fibonacci_with_send()
# stepper_with_timeouts_1()
# stepper_with_timeouts_2()
# read_a_file()

