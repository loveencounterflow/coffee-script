


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


#-----------------------------------------------------------------------------------------------------------
g = walk_fibonacci()
log g.next()
log g.next()
log g.next()
log g.next()
log g.next()
log g.next()
log g.next()

log rpr walk_fibonacci()
for i of walk_fibonacci()
  log i


coffee = require '../../coffy-script'
log coffee.compile """
  outer = ->
    inner = =>>
      yield 'helo world'
  """



