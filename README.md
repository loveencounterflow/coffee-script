


# CoffyScript

## ...is CoffeeScript with Yield❗

As of
[JavaScript 1.7 (as implemented in Firefox)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Iterators_and_Generators)
and
[EcmaScript 6 (ES6, dubbed 'Harmony')](http://wiki.ecmascript.org/doku.php?id=harmony:generators), we have a
Python-like `yield` keyword in JavaScript. Yeah!

That's really cool 'cause, y'know, `yield` brings generators, and generators are cool for—you
guessed it—asynchronous programming.

Unfortunately, it's not looking as if [CoffeeScript](https://github.com/jashkenas/coffee-script) in its
official incarnation is
[going to support `yield` any time soon](https://github.com/jashkenas/coffee-script/wiki/FAQ#unsupported-features),
which is a shame since it has already landed in NodeJS—which relies on V8, and the V8 team is known to be rather
conservative with features (which is understandable when your aim is to build the fastest *and* the most compatible
JavaScript engine).

## So what is this Yield All About?

If you have never programmed with iterators and generators, you may imagine as a 'resumable return' for
starters. For the more technically oriented,
[ES6 defines generators](http://wiki.ecmascript.org/doku.php?id=harmony:generators) as "First-class coroutines,
represented as objects encapsulating suspended execution contexts (i.e., function activations)." Well,
maybe 'resumable return' is not so bad after all.

The simplest example for using generators may be something like this (`log` being a shortcut for
`console.log` here):

    # Using a star after the arrow 'licenses' the use of `yield` in the function body;
    # it basically says: this is not an ordinary function, this is a generator function:
    count = ->*
      yield 1
      yield 2
      yield 3

    # Calling a generator function returns a generator:
    counting_generator = count()

    # Now that we have a generator, we can call one of its methods, `next`:
    log counting_generator.next()
    # { value: 1, done: false }

*(Note: The output you see is somewhat of a specialty of ES6 generators. In Python, generators throw a special
`StopIteration` exception to signal the generator has run to completion; because of [concerns over
efficiency and correctness in a fundamentally asynchronous language like
JavaScript](https://github.com/rwldrn/tc39-notes/blob/master/es6/2013-03/mar-12.md#412-stopiterationgenerator),
the consensus among developers is that yielding an object with members `value` and `done` is better.)*

<!-- ## A Quick Example

This is, in a nutshell, what CoffyScript gives you:

    # examples/generators.coffy

    log = console.log

    walk_fibonacci = ->*
      a = 1
      b = 1
      loop
        c = a + b
        yield c
        a = b
        b = c

    g = walk_fibonacci()
    log g.next()
    log g.next()
    log g.next()
    log g.next()
    log g.next()
    log g.next()
    log g.next()

Now let's run it:

    [object Generator]
    { value: 2, done: false }
    { value: 3, done: false }
    { value: 5, done: false }
    { value: 8, done: false }
    { value: 13, done: false }
    { value: 21, done: false }
    { value: 34, done: false }

A normal function will return whatever expression occurs behind the last `return` statement encountered
when executing the function. Generator functions are different—they always return a generator.

Now generators have a method `next`, which, when called, executes the body of the generator function until
a `yield` statement is encountered; whatever the value of the expression behind the `yield` statement is
(in our case `c = a + b`) becomes the return value of the `g.next()` call.

Code execution in the generator function is then suspended (not *terminated*, as would be the case in a
normal function), preserving the state of the function's scope. If you're still with me: Yes, that's a lot
like asynchronous code, and it's also a lot like closures.

But why the lucky stiff would you ever want this? Why not build a list of those Fibo numbo-jumbos and return
that?

'Courseyoucoulddothat. But. What if there are infinitely many of those numbers (and there are)? What if
each one of them is rather costly to compute (here it's simple)? What if you're not sure just yet how many
results you will need?
 -->

## Implementation Status

**Note: You will need NodeJS version ≥ 0.11.2 to use `yield`. The `bin/coffee` executable sets the V8
`--harmony` command line flag so you don't have to. If this should break things with part of your code,
consider changing that to `--harmony-generators`.**

CoffyScript is as yet **experimental**—just a quick hack of the CoffeeScript grammar. **You should probably
not use it to control a space rocket.**

Currently, the focus is on getting generators right in NodeJS; other targets most importantly Firefox
(which does not fully comply with ES6 generator specs) are *not* supported.

ES6 also specifies `yield*`, which corresponds to Python's `yield from` construct. However, if you try to
use that in NodeJS 0.11.2, you're bound to witness the Longest. Stacktrace. Ever. from deep inside of NodeJS,
so don't do that.


## Syntax

ES6 specifies that functions that use `yield` must be defined using `function*` instead of plain `function`.
CoffeeScript's equivalent for the JS keyword `function` is the arrow notation, so we attach the asterisk
to the arrows to get `->*` for ordinary and `=>*` for bound generator functions:

    walk_fibonacci = ->*
      # ... some code ...
      yield x

    walk_fibonacci = =>*
      # ... some code ...
      yield x

Should you forget the asterisk after the arrow, you will get a rather unhelpful error from NodeJS stating
that it 'doesn't know about yield', which of course is bollocks (provided that you do have a bleeding edge
version of NodeJS); just remember that when 'yield' occurs in an error message, the asterisk is the first
thing to check.


## Suspension

[suspend](https://github.com/jmar777/suspend) is a great little library that provides a single
function, `suspend`, to make working with `yield` and asynchronous functions just a bit easier. Suppose you
have a method to read a file and do something with that data:

    read_file = ( handler ) ->*
      [ error
        text  ] = yield njs_fs.readFile __filename, 'utf-8', handler
      throw error if error?
      log "read #{text.length} chrs"

have a look at `examples/suspend.coffy`


## Asynchronicity & How to Cope with it

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

JavaScript might not be as 'iterative' as modern Pythons are, but it sure is a *lot* more asynchronous by
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





