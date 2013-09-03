sandbox.lua
===========

A pure-lua solution for running untrusted Lua code.

For now, sandbox.lua only works with Lua 5.1.x.

Usage
=====

    local sandbox = require 'sandbox'

    -- sandbox can handle both strings and functions
    local msg  = sandbox(function() return 'this is untrusted code' end)
    local msg2 = sandbox("return 'this is also untrusted code'")

    sandbox(function()
      -- see sandbox.lua for a list of safe and unsafe operations
      return ('I can use safe operations, like string.upper'):upper()
    end)

    -- Attempting to invoke unsafe operations (such as os.execute) is not possible
    sandbox(function()
      os.execute('rm -rf /') -- this will throw an error, no damage don
    end)

    -- It is not possible to exhaust the machine with infinite loops; the following
    -- will throw an error after invoking 500000 instructions:
    sandbox('while true do end')

    -- The amount of instructions executed can be tweaked via the quota option
    sandbox('while true do end', {quota=10000}) -- throw error after 10000 instructions

    -- It is also possible to use the env option to add additional variables to the environment
    sandbox('return foo', {env = {foo = 'This was on the environment'}})

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





