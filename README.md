sandbox.lua
===========

A pure-lua solution for running untrusted Lua code.

For now, sandbox.lua only works with Lua 5.1.x.

Usage
=====

    local sandbox = require 'sandbox'

`sandbox(f, options)` and `sandbox.protect(f, options)` are synonyms. They return a sandboxed version of `f`.
`options` is not required. So far the only possible options are `env` and `quota` (see below)

    local sandboxed_f = sandbox(function() return 'hey' end)
    local msg = sandboxed_f() -- msg is now 'hey'

`sandbox.run(f)` sanboxes a function and executes it. f can be either a string or a function

    local msg  = sandbox.run(function() return 'this is untrusted code' end)
    local msg2 = sandbox.run("return 'this is also untrusted code'")

Only safe modules and operations can be accessed from the sandboxed mode. See the source code for a list of safe/unsafe operations.

    sandbox.run(function()
      return string.upper('string.upper is a safe operation.')
    end)

Attempting to invoke unsafe operations (such as `os.execute`) is not permitted

    sandbox.run(function()
      os.execute('rm -rf /') -- this will throw an error, no damage don
    end)

It is not possible to exhaust the machine with infinite loops; the following will throw an error after invoking 500000 instructions:

    sandbox.run('while true do end')

The amount of instructions executed can be tweaked via the `quota` option (default value: 500000 instructions)

    sandbox.run('while true do end', {quota=10000}) -- throw error after 10000 instructions

It is also possible to use the env option to add additional variables to the environment

    sandbox.run('return foo', {env = {foo = 'This was on the environment'}})

If provided, the env variable will be heavily modified by the sanbox (adding base modules like string)
The sandboxed code can also modify the env

    local env = {amount = 1}
    sandbox.run('amount = amount + 1', {env = env})
    assert(env.amount = 2)

Finally, you may pass parameters to the sandboxed function directly in `sandbox.run`. Just add them after the `options` param.

    local secret = sandbox.run(function(a,b) return a + b, {}, 1, 2)
    assert(secret == 3)


Installation
============

Just copy sandbox.lua wherever you need it.

License
=======

This library is released under the MIT license. See MIT-LICENSE.txt for details

Specs
=====

This project uses [busted](http://olivinelabs.com/busted/) for its specs. In order to run them, install `busted` and then:

    cd /path/to/where/the/spec/folder/is
    busted





