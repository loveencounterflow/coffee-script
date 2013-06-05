


# CoffyScript

## ...is CoffeeScript with Yield❗

As of
[JavaScript 1.7 (as implemented in Firefox)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Iterators_and_Generators)
and
[EcmaScript 6 (ES6, dubbed 'Harmony')](http://wiki.ecmascript.org/doku.php?id=harmony:generators), we have a
Python-like `yield` keyword in JavaScript. Yeah!

That's really cool–'cause, y'know, `yield` brings generators, and generators are cool for—you
guessed it—asynchronous programming.

Unfortunately, it's not looking as if [CoffeeScript](https://github.com/jashkenas/coffee-script) in its
official incarnation is [going to support `yield` any time soon](https://github.com/jashkenas/coffee-script/wiki/FAQ#unsupported-features),
which is a shame since it has already landed in NodeJS—which relies on V8, and the V8 team is known to be rather
conservative with features (which is understandable when your aim is to build the fastest *and* the most compatible
JavaScript engine).

## A Quick Example

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

But–why the lucky stiff would you ever want this? Why not build a list of those Fibo numbo-jumbos and return
that?

'Courseyoucoulddothat. But. What if there are infinitely many of those numbers (and there are)? What if
each one of them is rather costly to compute (here it's simple)? What if you're not sure just yet how many
results you will need?


## Implementation Status

**Note: You will need NodeJS version ≥ 0.11.2 to use `yield`. The `bin/coffee` executable sets the V8
`--harmony` command line flag so you don't have to. If this should break things, consider changing
that to `--harmony-generators`.** (Note: as an experimental feature, `--harmony_proxies` is also set,
so you do experiments how ES6 Proxies can help dealing with iterating over generated values).

CoffyScript is as yet experimental–a quick hack of the CoffeeScript grammar. You should probably not use
it to control a space rocket.

*Currently, the focus is on getting generators right in NodeJS; other targets–most importantly Firefox
(which does not fully comply with ES6 generator specs)–are **not** supported.*

ES6 also specifies `yield*`, which corresponds to Python's `yield from` construct. However, if you try to
use that in NodeJS 0.11.2, you're bound to witness the Longest. Stacktrace. Ever., so don't use it just
yet.

## Syntax

ES6 specifies that functions that use `yield` must be defined using `function*` instead of plain `function`.
CoffeeScript's equivalent for the JS keyword `function` is the arrow notation, so we attach the asterisk
to the arrows:

    walk_fibonacci = ->*
      # ... some code ...
      yield x

    walk_fibonacci = =>*
      # ... some code ...
      yield x








