


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

## Implementation Status

**Note: You will need NodeJS version ≥ 0.11.2 to use `yield`. The `bin/coffy` executable sets the V8
`--harmony` command line flag so you don't have to. If this should break things, consider changing
that to `--harmony-generators`.**

CoffyScript is as yet experimental–a quick hack of the CoffeeScript grammar. You should probably not use
it to control a space rocket.

*Currently, the focus is on getting generators right in NodeJS; other targets–most importantly Firefox
(which does not fully comply with ES6 generator specs)–are **not** supported.*

## Syntax

ES6 specifies that

## Examples


    log = console.log

    walk_fibonacci = ->>
      a = 1
      b = 1
      loop
        yield c = a + b
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




