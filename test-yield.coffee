
###

This is a simple testing suite for CoffyScript `yield`.

It has been placed in the module root folder so it stands out as an addition to the CoffeeScript distro;
also, the CS test suite (`npm test`) currently fails—presumably because the codebase is not an official
release. Remember: this is alpha quality software.

This file can be run as `./bin/coffee test-yield.coffee`; it should terminate without errors and without
any output.



###



############################################################################################################
# ERROR                     = require 'coffeenode-stacktrace'
# njs_util                  = require 'util'
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
# TRM                       = require 'coffeenode-trm'
# rpr                       = TRM.rpr.bind TRM
# badge                     = 'using-express'
# log                       = TRM.get_logger 'plain', badge
# info                      = TRM.get_logger 'info',  badge
# whisper                   = TRM.get_logger 'whisper',  badge
# alert                     = TRM.get_logger 'alert', badge
# debug                     = TRM.get_logger 'debug', badge
# warn                      = TRM.get_logger 'warn',  badge
# help                      = TRM.get_logger 'help',  badge
# echo                      = TRM.echo.bind TRM
# rainbow                   = TRM.rainbow.bind TRM
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
after                     = suspend.after
eventually                = suspend.eventually
immediately               = suspend.immediately
every                     = suspend.every
# TEXT                      = require 'coffeenode-text'
#...........................................................................................................
assert                    = require 'assert'


#-----------------------------------------------------------------------------------------------------------
# f = ->
#   step ( resume ) =>
#     text = yield njs_fs.readFile __filename, encoding: 'utf-8', resume
#     info rpr text

#-----------------------------------------------------------------------------------------------------------
@test_1 = ->
  # Using a star after the arrow 'licenses' the use of `yield` in the function body;
  # it basically says: this is not an ordinary function, this is a generator function:
  count = ->
    yield 1
    yield 2
    yield 3

  # Calling a generator function returns a generator:
  counting_generator = count()

  # Now that we have a generator, we can call one of its methods, `next`:
  assert.deepEqual counting_generator.next(), { value: 1, done: false }

  # ...and we can go on doing so until the generator becomes exhausted:
  assert.deepEqual counting_generator.next(), { value: 2, done: false }
  assert.deepEqual counting_generator.next(), { value: 3, done: false }
  assert.deepEqual counting_generator.next(), { value: undefined, done: true }
  try
    log counting_generator.next()   # throws an error saying "Generator has already finished"
  catch error
    throw error unless ( /^Generator has already finished$/ ).test error[ 'message' ]
    # warn "(ok: #{error[ 'message' ]}"
  #.........................................................................................................
  test.done()

#-----------------------------------------------------------------------------------------------------------
@test_fibonacci = ->
  #.........................................................................................................
  walk_fibonacci = ->
    a = 1
    b = 1
    loop
      c = a + b
      return c if c > 20
      yield c
      a = b
      b = c

  #.........................................................................................................
  g = walk_fibonacci()

  results = [ 2, 3, 5, 8, 13, ]
  idx     = 0
  loop
    { value, done } = g.next()
    break if done
    assert.equal value, results[ idx ]
    idx += 1
  assert.equal idx, 5

#-----------------------------------------------------------------------------------------------------------
@test_fibonacci_with_exception = ->
  walk_fibonacci = ->
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
        # log 'CAUGHT ERROR IN GENERATOR:', error
        assert.equal error[ 'message' ], "144!!!!"
        return "it's over!"
  #.........................................................................................................
  g = walk_fibonacci()
  #.........................................................................................................
  loop
    { value, done } = g.next()
    if done
      assert false
      break
    { value, done } = g.throw new Error "144!!!!" if value is 144
    if done
      assert.equal value, "it's over!"
      # log 'received value:', rpr value
      # log 'aborted'
      break
    # log value

#-----------------------------------------------------------------------------------------------------------
@test_sending_values_1 = ->
  walk_fibonacci = ( a, b ) ->
    initial_a = a ?= 1
    initial_b = b ?= 1
    loop
      c = a + b

      # This `yield` works in two ways: it gives a value *to* the caller
      # and receives a value back *from* the caller:
      r = yield c

      # Our protocol is very simple—resume Fibo sequence if `r` is truthy,
      # proceed normally otherwise:
      if r
        a = initial_a
        b = initial_b
      else
        a = b
        b = c
  #.........................................................................................................
  g       = walk_fibonacci 3, 1
  restart = undefined
  results = [ 4, 5, 9, 14, 23, 37, 60, 97, 157, ]
  #.........................................................................................................
  for idx in [ 0 ... 100 ]
    { value, done } = g.next restart
    restart         = value > 100
    break if done
    assert.equal value, results[ idx % 9 ]

#-----------------------------------------------------------------------------------------------------------
@test_stepper_with_timeouts = ->
  t0 = 1 * new Date()
  stepper_with_timeouts = ->
    # log "A"
    yield after 1, ->
      assert 1000 < ( ( 1 * new Date() ) - t0 ) < 2000
      # log '1'
    assert false # we should never get here
    log "B"
    yield after 1, -> log '2'
  #.........................................................................................................
  g = stepper_with_timeouts()
  g.next()

#-----------------------------------------------------------------------------------------------------------
@test_sending_values_2 = ->
  read_file = ( route, handler ) ->
    ### Given the location of a file, read and decode it using UTF-8, then call the handler
    as `handler error, data`. ###
    ( require 'fs' ).readFile __filename, 'utf-8', handler
    return null
  #.........................................................................................................
  resume = ( error, data ) ->
    ### Send results to generator. ###
    g.next [ error, data, ]
  #.........................................................................................................
  log_character_count = ( route ) ->
    ### Given a `route`, retrieve the text of that file and print out its character count. ###
    [ error, text ] = yield read_file route, resume
    assert not error?
    assert.equal ( Object::toString.call text ), '[object String]'
    assert text.length > 0
    # log "file #{__filename} is #{text.length} characters long."

  g = log_character_count __filename
  g.next()


#-----------------------------------------------------------------------------------------------------------
@test_suspend = ->
  { step } = require 'coffeenode-suspend'
  step ( resume ) =>
    assert.equal ( Object::toString.call @test_suspend ), '[object Function]'
    try
      buffer = yield njs_fs.readFile __filename, resume
      assert Buffer.isBuffer buffer
      # log "read #{buffer.length} bytes"
    catch error
      assert false
      log "### THIS ERROR CAUGHT IN GENERATOR ### #{error[ 'message' ]}"

#-----------------------------------------------------------------------------------------------------------
@test_suspend_with_error = ->
  { step } = require 'coffeenode-suspend'
  step ( resume ) =>
    assert.equal ( Object::toString.call @test_suspend ), '[object Function]'
    try
      buffer = yield njs_fs.readFile 'NOTAVALIDFILENAME', resume
      assert false
    catch error
      assert.equal error[ 'message' ], "ENOENT, open 'NOTAVALIDFILENAME'"

###
# these two features are not yet included:

#-----------------------------------------------------------------------------------------------------------
@test_yieldfrom = ->
  #.........................................................................................................
  g1 = ->
    for n in [ 1 ... 10 ]
      yield n
  #.........................................................................................................
  g2 = ->
    yield 'start'
    yieldfrom g1()
    yield 'stop'
  #.........................................................................................................
  g = g2()
  loop
    debug g.next()

#-----------------------------------------------------------------------------------------------------------
@test_iteration = ->
  #.........................................................................................................
  g1 = ->
    for n in [ 1 ... 10 ]
      yield n
  #.........................................................................................................
  for n outof g1()
    debug n
###


############################################################################################################
# f()
test =
  done: ->

@test_1()
@test_fibonacci()
@test_fibonacci_with_exception()
@test_sending_values_1()
@test_stepper_with_timeouts()
@test_sending_values_2()
@test_suspend()
@test_suspend_with_error()
# @test_yieldfrom()
# @test_iteration()


