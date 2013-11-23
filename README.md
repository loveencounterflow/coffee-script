

## ⚞ BREAKING NEWS ⚟

CoffyScript has now been bumped to version 11.6.3 to reflect it has been
updated to [the Nov 15, 2013 version of CoffeeScript master](https://github.com/jashkenas/coffee-script/commit/f047ba52b21805751d68c95f1a2c8aac18601b01),
merged with [pull request #3240 from the same date](https://github.com/alubbe/coffee-script/commit/f51cbd71179c30dccab1806146c50b688fa2b528).
The strange version number is just `'1' + '1.6.3'` as a way to indicate that **(1)** it's basically CS v1.6.3;
**(2)** it's a little more than that version of CS; **(3)** it introduces breaking changes w.r.t. the previous
version of CoffyScript (namely, no more `->*`, only `->`). Given that the community seems quite eager to
get `yield` into CS, it is to be expected that CoffyScript will soon become useless—which is a good thing.


# CoffyScript

## ...is CoffeeScript with Yield❗

As of
[JavaScript 1.7 (as implemented in Firefox)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Iterators_and_Generators)
and
[EcmaScript 6 (ES6, dubbed 'Harmony')](http://wiki.ecmascript.org/doku.php?id=harmony:generators), we have a
Python-like `yield` keyword in JavaScript. Yeah!

That's really cool: **asynchronous programming and generators are a natural match**.

Unfortunately, it's not looking as if [CoffeeScript](https://github.com/jashkenas/coffee-script) in its
official incarnation is
[going to support `yield` any time soon](https://github.com/jashkenas/coffee-script/wiki/FAQ#unsupported-features),
which is a shame since it has already landed in NodeJS. So i patched together this CoffeeScript fork that
bends the parsing rules somewhat, with the result that this version supports 'starred function syntax' and
the `yield` statement. See below for details.

## TL;DR

The impatient may want to scroll down to the section on [Suspension](#suspension), where i demonstrate how
to write serialized asynchronous function calls. Be sure to read the [disclaimers](#implementation-status)—this
is rather new stuff, not yet main stream, so there will be rough edges.

**Table of Contents**

- [So What is this Yield All About?](#so-what-is-this-yield-all-about)
  - [Minimal Example](#minimal-example)
  - [Endless Loops](#endless-loops)
  - [Throwing Errors](#throwing-errors)
  - [Sending Values](#sending-values)
- [How Not to Yield to Callback Hell: Serializing Control Flow](#how-not-to-yield-to-callback-hell-serializing-control-flow)
- [Suspension](#suspension)
- [Suspension #2](#suspension-2)
- [Implementation Status](#implementation-status)
  - [A Note on Require.Extensions](#a-note-on-requireextensions)
- [Asynchronicity & How to Cope With It: the Alternatives](#asynchronicity--how-to-cope-with-it-the-alternatives)

> *generated with [DocToc](http://doctoc.herokuapp.com/)*

## So What is this Yield All About?

If you have never programmed with iterators and generators, you may imagine as a 'resumable return' for
starters. For the more technically oriented,
[ES6 defines generators](http://wiki.ecmascript.org/doku.php?id=harmony:generators) as "First-class coroutines,
represented as objects encapsulating suspended execution contexts (i.e., function activations)." Well,
maybe 'resumable return' is not so bad after all.

### Minimal Example

The simplest example for using generators may be something like this (`log` being a shortcut for
`console.log` here):

```coffeescript

# Using a star after the arrow 'licenses' the use of `yield` in the function body;
# it basically says: this is not an ordinary function, this is a generator function:
count = ->
  yield 1
  yield 2
  yield 3

# Calling a generator function returns a generator:
counting_generator = count()

# Now that we have a generator, we can call one of its methods, `next`:
log counting_generator.next()   # prints: { value: 1, done: false }

# ...and we can go on doing so until the generator becomes exhausted:
log counting_generator.next()   # prints: { value: 2, done: false }
log counting_generator.next()   # prints: { value: 3, done: false }
log counting_generator.next()   # prints: { value: undefined, done: true }
log counting_generator.next()   # throws an error saying "Generator has already finished"

```

> *(Note: The output you see is somewhat of a peculiarity of ES6 generators. In Python and in current (June 2013)
> Firefoxen, generators throw a special
> `StopIteration` exception to signal the generator has run to completion; because of [concerns over
> efficiency and correctness in a fundamentally asynchronous language like
> JavaScript](https://github.com/rwldrn/tc39-notes/blob/master/es6/2013-03/mar-12.md#412-stopiterationgenerator),
> the consensus among developers is that yielding an object with members `value` and `done` is better.
> In CoffeeScript this is easily dealt with using `{ value, done } = g.next()`.)*

So what happens here is essentially that the generator will, on the first call to `g.next()`, do whatever
the function definition says, until it hits `yield`. It will return the argument of that `yield` (inside  a
custom-made object), and suspend operation. When `g.next()` is called another time, the generator picks up
from where it left and runs until it hits upon the next `yield`. When no more `yield`s are left, an object
with `done: true` is returned; from that point on, calling `g.next()` will cause an exception.

### Endless Loops

Now let's look at a slightly more interesting example. I'm sure you're already shivering in anticipation how
one might do Fibonacci numbers with generators. Here's one way:

```coffeescript

walk_fibonacci = ->
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

# will print a list of numbers:
# 2
# 3
# 5
# 8
# 13

# ...

# 19740274219868226000
# 31940434634990100000
# 51680708854858330000
# 83621143489848430000

# ...and stop there as the next value would be larger than the limit we've set.

```

This example shows that:

* a generator can be used similar to a function that returns a list, but without ever building that list, so
  you can build a list with arbitrary many elements, the limitation being *time*
  rather than *space*—a use case for this is reading huge files as streams, segmenting them into lines, and
  then yielding those lines to a processor. Stuff like this will become much more palatable once NodeJS
  implements true iteration using something like `for x in/of g` constructs.

* A `return` statement inside a generator function indicates the last value has just
  been reached (this again is different from Python, where a `return` in a generator function cannot return
  any value).

### Throwing Errors

When you call `g.throw error`, you'll **throw an error *inside* the generator**. Understanding by example is maybe
the easiest:

```coffeescript

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

# prints:
# 2
# 3
# 5
# 8
# 13
# 21
# 34
# 55
# 89
# CAUGHT ERROR IN GENERATOR: [Error: 144!!!!]
# received value: 'it\'s over!'
# aborted
```
> *(`rpr` in the above is just `( require 'util' ).inspect`)*

As you can see, `g.throw()` gets an object back just like `g.next()` does. When the generator catches
the error, it may or may not decide to go on delivering values; in our case, we just return an unhelpful
message and call it quits. Control flow literally bounces to and fro between caller and callee, as
documented by the log messages.


### Sending Values

Now we get to the point where we examine the single most exciting gem—what might well turn out to be the
future of asynchronous programming in JavaScript, and that is **sending values into a generator**. To get a
feel for this feature, let's rewrite our Fibonacci example a bit:

```coffeescript
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

g       = walk_fibonacci 3, 1
restart = undefined

for idx in [ 0 ... 100 ]
  # { value, done } = g.send restart # NB old version
  { value, done } = g.next restart
  restart         = value > 100
  break if done
  log value

# prints
# 4
# 5
# 9
# 14
# 23
# 37
# 60
# 97
# 157
# 4
# 5
# 9
# 14
# 23
# 37
# 60
# ...
```

Here we have a generalized Fibonacci function that not only accepts two numbers as seed, it also checks
whether the consumer sent in a truthy value to indicate the sequence should start over. In essence, you
can 'talk' to your generator, as it were, telling it what to do.

<strike>strikethrough</strike>

> We send in `undefined` when we first call `g.send()`. The reason is that **(1)** `g.next()` is actually
> implemented as `g.send undefined`, and **(2)** to initialize a generator, you must not send anything but
> `undefined`, or you'll get an error.


## How Not to Yield to Callback Hell: Serializing Control Flow

Now that we've got all the pieces together, let's have a look at how `yield` is great for dealing with
asynchronous programming.


```coffeescript
stepper_with_timeouts = ->*
  log "A"
  yield after 1, -> log '1'
  log "B"
  yield after 1, -> log '2'

g = stepper_with_timeouts()
g.next()
```

> In this code, `after` is just a friendly rewrite of `setTimeout`, JavaScript's most generic means for
> asynchronous programming: it takes a time expressed as number of seconds and a callback; it will call the
> callback at some time in the future when at least as many seconds have passed; before that can happen, the
> current code context is allowed to run to completion.

We first retrieve the generator, then call `g.next()` on it. Of course what happens is that we immediately
get printed out `A`, and, after a delay of one second, a `1` appears on the console. We never get to see
`B`, because there's no second call to `g.next()`. Now the idea is that if we could make it so that the next
call to `g.next()` happens when the scheduled callback occurs ... we'd effectively implemented `sleep()` in
JavaScript, a language that never had such a construct.

And this is how we might be doing that, with very simple means:

```coffeescript

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

# prints:
# after
# (one second pause)
# a
# (one second pause)
# long
# (one second pause)
# time
```

To really appreciate how great this is, recall that `setTimeout()` (and, therefore, `after()`) is a truly
asynchronous function—unlike the blocking `time.sleep()` you get with a language like Python. This means
that while the script is running, you could very well be doing some other stuff during the breaks,
which you can't when using a blocking `sleep()` function. And unlike a so-called 'busy loop'—basically
`while time() < t1...`—CPU load will be near zero while the program is waiting. And still we have
managed to arrange our stuff in a linear fashion; without `yield`, we would've been forced to write that
stuff like

```coffeescript
log "after"
after 1, ->
  log "a"
  after 1, ->
    log "long"
    after 1, ->
      log "time"
```

invoking the Pyramid of Doom, or using promises or events or an asynchronous library.

There's one single thing we have to accomplish yet: how to get back a value from an asynchronous call?
Well, as we've seen above, `g.next()` is really just `g.send value`, so we can easily update the previous
example. Let's do something different now and read a file asynchronously:

```coffeescript
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
```

And that's basically it! Using just a little bit of built-in language features, we've managed to deal with
the event loop, suspending and resuming from one line to the next!


## Suspension

In the previous section i demonstrated how simple it is to use `yield` and `g.send()` to build **code that
suspends and resumes**. It gets even better though when you use a library for that generator-building stuff,
and [`suspend` by Jeremy Martin (jmar777)](https://github.com/jmar777/suspend) is exactly such a brilliant
piece of code. Exporting a single function that weighs in at a mere 16 lines of JavaScript, `suspend` makes
the formulation of suspend / resume functions significantly easier and clearer. Let's take another look at
the file reading example above, reformulated suspension-style:

```coffeescript

suspend = require 'suspend'

read_text_file = ( route, handler ) ->
  ### A run-of-the-mill asynchronous file reading function; `handler` should be a NodeJS-compliant callback
  function that expects to be called with `( error, data )` on completion. ###
  ( require 'fs' ).readFile route, 'utf-8', ( error, text ) ->
    if error?
      handler error
    else
      handler null, text

#                         argument to `suspend`:
# result of calling       generator function that
#     `suspend`           accepts `resume` as its
#                          asynchronous callback
#        ↓                           ↓
test_read_text_file = suspend ( resume ) ->*
  ### The consumer of `read_text_file`, above. It is defined by 'decorating' a generator function (which
  accepts a single argument, `resume`) with `suspend`. When calling a NodeJS-compliant
  asynchronous function, we simple call that function with `resume`as callback, prepend the call with
  a `yield` statement, and upon completion we'll get a pair `[ error, data, ]` back from `yield`.
  We can than proceed to dealing with an error or further process the data. ###
  [ error
    text  ] = yield read_text_file __filename, resume
  throw error if error?
  log "read #{text.length} characters"

test_read_text_file()
```

Now `suspend` returns a function, but does not execute it; this is what the call on the last line does. In
many cases, you will want to pass in some arguments to your generator. To make this easier, we define a
`step` decorator that does what `suspend` does, and immediately calls the result. Thus:

```coffeescript
step = ( stepper ) ->
  R = suspend stepper
  return R()

test_read_text_file = ( route ) ->
  # Consider to use `=>*` below in order to keep the `this` / `@` context.
  return step ( resume ) ->*
    [ error
      text  ] = yield read_text_file route, resume
    throw error if error?
    log "read #{text.length} characters"

test_read_text_file __filename
```

It's really amazing how clear this syntax is once you've gotten used to the semantics of `yield` and removed
your callbacks. jmar777 remarks that instead of building a full-fledged asynchronous helper libraries with
all the bells and whistles, he'd rather stick with the minimalist approach and keep `suspend` small for the
time being; he recommends using `async` for higher-order asynchronous chores. i can only second that
sentiment.

Still, it is fun and quite instructive to see how the most recurrent asynchronous chores can be formulated
using nothing but `yield`, `suspend`, and `resume`, so this is what i want to do next.

First, let's define our magic workhorse—a function that promises to deliver the result of `n * 2` at some
time in the future. It also prints to the command line so we get a feel for what's going on behind the
scenes:

```coffeescript
double = ( n, handler ) ->
  after Math.random(), ->
    Z = n * 2
    log "double: #{n} -> #{Z}"
    handler null, Z
```

We've already seen that `yield` lends itself to serialization, so let's start with just that: We want a
function that takes a start value, a stop value and a handler; we'll step over all the numbers one by one,
and on completion call the handler with a list of results.

Since each call happens asynchronously and may take anywhere between zero and one seconds to complete, we'll
have to serialize the calls so the result list keeps the correct order. And that turns out to be rather
simple indeed:

```coffeescript
double_numbers_in_serial = ( n0, n1, handler ) ->
  Z = []
  step ( resume ) ->*
    for i in [ n0 .. n1 ]
      [ error
        result ] = yield double i, resume
      handler error if error?
      Z.push result
    handler null, Z
```

Some tasks greatly benefit from complete or partial serialization: when you run thousands of automated web
page retrievals, you will want to limit how many open connections there are; when you want to drill into
data from a database, future requests may depend on the outcome of earlier ones.

In our case, however, we do not have to be careful about resources, and results are mutually independent.
Each call takes a half second on average and leaves the CPU idle for that accumulated time. If we could do
that in a more parallelized manner, that would be great. And we can:

```coffeescript
double_numbers_in_parallel = ( n0, n1, handler ) ->
  Z                 = []
  active_call_count = 0
  for i in [ n0 .. n1 ]
    active_call_count += 1
    step ( resume ) ->*
      [ error
        result ] = yield double i, resume
      active_call_count -= 1
      handler error if error?
      Z.push result
      handler null, Z if active_call_count is 0
  return null
```

Things do get a tad more complicated as we have to keep track of how many calls are still unfinished. On the
bright side, the average time to compute a list of, say, a hundred numbers has just come down from 50
seconds to about a half second. On the other hand, our list is just mumbo-jumbo numbos, the results being
randomly distributed over the result list (fine for some tasks, not good for others). It's not really
difficult to remedy that without any sacrifice in terms of efficiency:

```coffeescript
double_numbers_in_sorted_parallel = ( n0, n1, handler ) ->
  Z                 = []
  active_call_count = 0
  for i in [ n0 .. n1 ]
    idx                 = active_call_count
    active_call_count  += 1
    do ( idx ) ->
      step ( resume ) ->*
        [ error
          result ] = yield double i, resume
        active_call_count -= 1
        handler error if error?
        Z[ idx ] = result
        handler null, Z if active_call_count is 0
  return null
```

All we have to do is remembering the index where each result has to land; we can easily accomplish that by
using a CoffeeScript `do () ->` closure.


## Suspension #2

So i forked [suspend](https://github.com/jmar777/suspend), rewrote it in CoffeeScript, and added a few
utility methods; the thing is called `coffeenode-suspend` and is available on
[GitHub](https://github.com/loveencounterflow/coffeenode-suspend) and on
[NPM](https://npmjs.org/package/coffeenode-suspend).

coffeenode-suspend differs from the original in a few points:

* coffenode-suspend is **re-written in CoffeeScript**;
* it **works with callback-accepting synchronous functions**
* which means using `suspend` or `step` will **make your code asynchronous in case it wasn't already**.
* coffenode-suspend will **throw errors in the generator** by default (instead of returning them);
* it will **send only a single value** (not a list with a single value) to the generator if the callback
  just delivered a single value;
* it offers **utility functions** for your asynchronous chores (available as `suspend.step`, `suspend.after`,
  and `suspend.eventually`).

In essence, you can now write code like this:

```coffeescript
test_read_text_file_with_step = ( route ) ->
  return step ( resume ) =>*
    try
      text = yield read_text_file route, resume
      log "read #{text.length} characters"
    catch error
      log "### THIS ERROR CAHUGHT IN GENERATOR ### #{error[ 'message' ]}"
```

Getting those yielded values and catching those errors has just become a tad more like what you know from
synchronous programming. And just in case you thought that `read_text_file` function was asynchronous but in
fact wasn't, your code will have *transparently* become asynchronous and will continue working.

To see more, take a look at the code in
[examples/coffeenode-suspend.coffy](https://github.com/loveencounterflow/coffy-script/blob/master/examples/coffeenode-suspend.coffy).


## Implementation Status

**Note: You will need NodeJS version ≥ 0.11.2 to use `yield`. The `bin/coffee` executable sets the V8
`--harmony` command line flag so you don't have to. If this should break things with part of your code,
consider changing that to `--harmony-generators`.**

CoffyScript is as yet **experimental**—just a quick hack of the CoffeeScript grammar. **You should probably
not use it to control a space rocket.**

Currently, the focus is on getting generators right in NodeJS; other targets (most importantly Firefox,
which currently does not fully comply with ES6 generator specs) are *not* supported.

ES6 also specifies `yield*`, which corresponds to Python's `yield from` construct. However, if you try to
use that in NodeJS 0.11.2, you're bound to witness the Longest. Stacktrace. Ever. from deep inside of NodeJS,
so don't do that.


### A Note on Require.Extensions

After NodeJS's multilinguistic capabilities had gotten enthusiastically
embraced by people advocating '[symbiotic languages](http://ashkenas.com/dotjs/)', the drawbacks of having a
single, global `require.extensions` object manage transpiling languages became apparent.

Fact is, **if Language A registers extension `.lang` and any Language B does so too, it becomes unclear
which language will end up dealing with any given file `x.lang`. Worse, two modules may require two
different versions of the same language, and while the NPM module system as such is designed to allow just
this, the global `require.exensions` will mar those efforts**. This is bad.

For the time being, the best solution seems to be to pre-compile all your sources written in a secondary
language to their target language (`*.js` in most cases), but if you're like me, you still want to run your
sources and compile them on-the-fly. In order to provide a best-effort stop-gap solution, i've edited
`src/coffee-script.coffee` so that it registers all of CoffeeScript's extensions (`.coffee`, `.litcoffee`,
`.coffee.md`) *and* its own extensions (`.coffy`, `.litcoffy`, `.coffy.md`). The recommendation is that
you use one of the `*.coffy` extensions whenever you want to use `yield`, and `*.coffee` otherwise.


## Asynchronicity & How to Cope With It: the Alternatives

`yield` really starts to shine for a lot of use cases with full language support, such as what you get in
Python. Specifically, there are on the one hand lots and lots of builts-ins / standard library functions
in Python that routinely avoid building lists; on the other hand, you can transparently iterate over
generated values in a `for x in foo()` loop. Most of the time, you don't have to worry about whether you
got a list or a generator, you can just so use it. Doing this in a lot of places makes sense, as it should
reduce memory consumption, drive down garbage collection cycles, and also be faster.

Unfortunately, JavaScript isn't quite there yet. NodeJS as of 11.2 does not yet provide a full-fledged
implementation of JS Harmony iterators and generators, so JavaScripters can't yet get away with simply
writing `for x of foo()`—you always have to use explicit calls like `generator.next()`, `generator.send()`,
`generator.throw()`, `generator.close()`.

JavaScript might not be as 'iterative' as modern Pythons, but it sure is a *lot* more asynchronous by
nature.

* **Callbacks**. Simple, well standardized. CoffeeScript's function syntax makes callbacks a lot more viable for
  many people, being both easier to write and to read, it's much less of a burden to use functions all the
  the time. But, of course: the Pyramid of Doom doesn't go away just because functions are easier to type.

* **Events**. More expressive than callbacks, as you can subscribe to specific event types, rather than waiting
  for a single callback handler to get called.

* **Promises**. An emerging standard (cf. 'Promises/A+'). Harder to get right than callbacks, as witnessed by
  all those attempts that *didn't* get it right (mighty jQuery being one of them—which goes to show just
  how hard promises are). Promises may be thought of 'specialized event handlers' of sorts.

* **Control Flow Libraries**. Packages like [Step](https://github.com/creationix/step) or
  [async](https://github.com/caolan/async) library (and around 200 more).

  Asynchronous control flow libraries typically provide methods to simplify such tasks as: fulfill each
  subtask in parallel, and return a (list of) value(s) when all have finished; return a value as soon as any
  subtask has finished; run subtasks in parallel, but limit the number of concurrent asynchronous calls.

* **Transpiling languages with asynchronous constructs**, such as
  [GorillaScript](https://github.com/ckknight/gorillascript),
  [PogoScript](https://github.com/featurist/pogoscript),
  [ToffeeScript](https://github.com/jiangmiao/toffee-script).
  [Iced CoffeeScript](http://maxtaco.github.io/coffee-script/)
  Transpiling
  languages occupy a middle ground between mere libraries and native language extensions. The justification
  for transpiling languages is that there are things you just can't push into a library—for example,
  changing the very syntax, introduce new or improved operators, reordering code—stuff like that.

  While i find transpiling languages very exciting mainly because they allow you to write code for an
  existing, popular VM with well-known properties and without being bound to (all of) the idiosyncrasies
  of that VM, there are certain limits to what is desirable or even
  acceptable as far as the generated code goes.

  PogoScript, as a case in point, allows you to decorate
  your asynchronous function call, so you can write `x = f! a` as if `f a` replaced by `f! a` was an
  asynchronous-turned-synchronous function call (i call this 'folded style', the callback part being
  like 'folded back' into your primary control flow). Of course, within the limits of JavaScript *without*
  `yield`, turning an asynchronous into a synchronous call is not
  possible without a massive reordering of code and dealing with callbacks and exceptions behind the scenes.

  So while you do get benefits from this approach
  (like being able to catch asynchronous errors inside a seemingly run-of-the mill `try` / `catch` clause),
  the expensiveness in terms of resulting code complexity is baffling: a single line, a single 'folded'
  call will expand to ~25 lines of
  JavaScript. Worse, a single `try` / `catch` / `finally` clause with three 'folded' calls
  on 6 lines of source
  will *explode* to ~150 lines of target JS, forming a pyramid that is up to *ten* stories deep, all riddled with
  nested `if` / `else` and `try` / `catch` clauses. Debugging a chess programm written in Brainfuck is
  probably easier than to digest *this* heap of spaghetti. Nice try, but thank you. And thank you Jeremy
  and everyone for not allowing this to happen in CS. (Disclaimer: not one here to disparage PogoScript or
  its authors in whichever ways—making this trick work is an achievement to be sure. I'm just saying this hammer
  is probably not what you wanted to fix your screw.)

  Iced CoffeeScript introduces two new keywords, `await` and `defer`, that, used in concert, allow to write
  quite succinct constructs.

  Turns out the 'folded' calls of some transpiling languages is pretty similar to what you can get with
  `yield`.

* **Native Language Extensions** (that modify NodeJS or another VM), e.g. XXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
  Interesting
  and certainly potentially able to provide the most powerful solutions to the asynchronous conondrum. But:
  unless ideas tested and proven by such projects enter the mainstream (read: become part of ES), they won't
  fly (far). Platform fragmentation has and will be one difficult aspect of JavaScript, and more
  fragmentation won't cut it. When you have the chance to work within the world's best-deployed software
  platform / VM, you don't want to lock out yourself for thirty pieces of silver and a few saved callbacks
  (bad enough `yield` needs an unstable version of NodeJS).

* **Using another VM altogether**—Haskell, Erlang or Go maybe. Ouside of my consideration; but of course, there
  may be valuable lessons in other VMs, e.g. [exception handling in Go](http://blog.golang.org/error-handling-and-go),
  which is completely different from what you would (or even could) do in unadultered JavaScript. Otherwise,
  it's pretty much that thirty pieces of silver thing for me again.





