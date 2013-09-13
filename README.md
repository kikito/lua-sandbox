sandbox.lua
===========

A pure-lua solution for running untrusted Lua code.

For now, sandbox.lua only works with Lua 5.1.x.

Usage
=====

    local sandbox = require 'sandbox'

`sf = sandbox(f, options)` and `sf = sandbox.protect(f, options)`
-----------------------------------------------------------------

Those two are synonyms. They return a sandboxed version of `f`.

`options` is not required. So far the only possible options are `env` and `quota`

    local sandboxed_f = sandbox(function() return 'hey' end)
    local msg = sandboxed_f() -- msg is now 'hey'

Only safe modules and operations can be accessed from a sandboxed function. See the source code for a list of safe/unsafe operations.

    local f1 = sandbox.protect(function()
      return string.upper('string.upper is a safe operation.')
    end)

    local f2 = sandbox.protect(function()
      os.execute('rm -rf /') -- this will throw an error, no damage done
    end)

    f1() -- ok
    f2() -- error: os.execute not found

### `options.quota (default 500000)`

It is not possible to exhaust the machine with infinite loops; the following will throw an error after invoking 500000 instructions:

    sandbox.run('while true do end')

The amount of instructions executed can be tweaked via the `quota` option (default value: 500000 instructions)

    sandbox.run('while true do end', {quota=10000}) -- throw error after 10000 instructions

### `options.env (default {})`

Use the `env` option to add additional variables to the environment

    local msg = sandbox.run('return foo', {env = {foo = 'This is on the environment'}})

If provided, the `env` variable will be modified by the sanbox (adding base modules like `string`)
The sandboxed code can also modify the sandboxed function. Make sure to securize it if needed.

    local env = {amount = 1}
    sandbox.run('amount = amount + 1', {env = env})
    assert(env.amount = 2)


`result = sandbox.run(f, options, ...)`
---------------------------------------

`sandbox.run` sanboxes a function and executes it. `f` can be either a string or a function

    local msg  = sandbox.run(function() return 'this is untrusted code' end)
    local msg2 = sandbox.run("return 'this is also untrusted code'")

`sandbox.run(f, o, ...)` is equivalent to `sandbox.protect(f,o)(...)`.

`options` works exactly like in `sandbox.protect`.

`sandbox.run` also returns the result of executing `f` with the given params after `options`, if any (notice that strings can't accept parameters).

Notice that if `f` throws an error, it is *NOT* captured by `sandbox.run`. Use `pcall` if you want your app to be immune to errors, like this:

    local ok, result = pcall(sandbox.run, 'error("this just throws an error")')


Installation
============

Just copy sandbox.lua wherever you need it.

License
=======

This library is released under the MIT license. See MIT-LICENSE.txt for details

Specs
=====

This project uses [telescope](https://github.com/norman/telescope) for its specs. In order to run them, install it and then:

    cd /path/to/where/the/spec/folder/is
    tsc spec/*

I would love to use [busted](http://olivinelabs.com/busted/), but it has some incompatibility with `debug.sethook(f, "", quota)` and the tests just hanged up.
