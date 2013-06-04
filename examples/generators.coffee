


############################################################################################################
# ERROR                     = require 'coffeenode-stacktrace'
njs_util                  = require 'util'
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
log                       = console.log
rpr                       = njs_util.inspect


### TAINT not a test suite just yet, just an example ###

#-----------------------------------------------------------------------------------------------------------
walk_fibonacci = ->>
  a = 1
  b = 1
  loop
    yield c = a + b
    a = b
    b = c
  return 42

#-----------------------------------------------------------------------------------------------------------
g = walk_fibonacci()

log ( require 'coffeenode-types' ).type_of g
log Object::toString.call g

log g.next()
log g.next()
log g.next()
log g.next()
log g.next()
log g.next()
log g.next()

for n in walk_fibonacci()
  log n


coffee = require '../../coffy-script'
log coffee.compile """
  outer = ->
    inner = =>>
      yield 'helo world'
  """



