sandbox.lua
===========

A pure-lua solution for running untrusted Lua code.

The default behavior is restricting access to "dangerous" functions in Lua, such as `os.execute`.

It's possible to provide extra functions via the `options.env` parameter.

Infinite loops are prevented via the `debug` library.

Supported Lua versions:
======================

All the features of sandbox.lua work in the following Lua environments:


* PUC-Rio Lua 5.1 **allows execution of bytecode**, which is a huge limitation (see the bytecode section below)
* PUC-Rio Lua 5.2, 5.3, 5.4 have total support.
* LuaJIT is not protected against infinite loops (see the notes in `options.quota` below)

Usage
=====

Require the module like this:

``` lua
local sandbox = require 'sandbox'
```

Then you can use `sandbox.run` and `sandbox.protect`

### sandbox.run(code, options, ...)

`sandbox.run(code, options, ...)` sandboxes and executes `code` with the given `options` and extra params.

`code` must be a string with Lua code inside.

`options` is described below.

Any extra parameters will just be passed to the sandboxed function when executed, and available on the top-level scope via the `...` varargs parameters.

In other words, `sandbox.run(c, o, ...)` is equivalent to `sandbox.protect(c, o)(...)`.

Notice that if `code` throws an error, it is *NOT* captured by `sandbox.run`. Use `pcall` if you want your app to be immune to errors, like this:

``` lua
local ok, result = pcall(sandbox.run, 'error("this just throws an error")')
```

### sandbox.protect(code, options)

`sandbox.protect("lua code")` (or `sandbox("lua code")`) produces a sandboxed function, without executing it.

The resulting sandboxed function works as regular functions as long as they don't access any insecure features:

```lua
local sandboxed_f = sandbox(function() return 'hey' end)
local msg = sandboxed_f() -- msg is now 'hey'
```

Sandboxed options can not access unsafe Lua modules. (See the [source code](https://github.com/kikito/sandbox.lua/blob/master/sandbox.lua#L35) for a list)

When a sandboxed function tries to access an unsafe module, an error is produced.

```lua
local sf = sandbox.protect([[
  os.execute('rm -rf /') -- this will throw an error, no damage done
end
]])

sf() -- error: os.execute not found
```

Sandboxed code will eventually throw an error if it contains infinite loops (note: this feature is not available in LuaJIT):

```lua
local sf = sandbox.protect([[
  while true do end
]])

sf() -- error: quota exceeded
```

### Bytecode

It is possible to exit a sandbox using specially-crafted Lua bytecode. References:

* http://apocrypha.numin.it/talks/lua_bytecode_exploitation.pdf
* https://github.com/erezto/lua-sandbox-escape
* https://gist.github.com/corsix/6575486

Because of this, the sandbox deactivates bytecode in all the versions of Lua where it is possible:

* PUC-Rio Lua 5.2, 5.3, 5.4
* LuaJIT

In other words, _all except PUC-Rio Lua 5.1_.

** The sandbox can be exploited in PUC-Rio Lua 5.1 via bytecode **

The only reason we keep Lua 5.1 in the list of supported versions of Lua is because
sandboxing can help against users attempting to delete a file by mistake. _It does not provide
protection against malicious users_.

As a result we _strongly recommend updating to a more recent version when possible_.

### options.quota

Note: This feature is not available in LuaJIT

`sandbox.lua` prevents infinite loops from halting the program by hooking the `debug` library to the sandboxed function, and "counting instructions". When
the instructions reach a certain limit, an error is produced.

This limit can be tweaked via the `quota` option. But default, it is 500000.

It is not possible to exhaust the machine with infinite loops; the following will throw an error after invoking 500000 instructions:

``` lua
sandbox.run('while true do end') -- raise errors after 500000 instructions
sandbox.run('while true do end', {quota=10000}) -- raise error after 10000 instructions
```

If the quota is low enough, sandboxed code with too many calculations might fail:

``` lua
local code = [[
  local count = 1
  for i=1, 400 do count = count + 1 end
  return count
]]

sandbox.run(code, {quota=100}) -- raises error before the code ends
```

If you want to turn off the quota completely, pass `quota=false` instead.


### options.env

Use the `env` option to inject additional variables to the environment in which the sandboxed code is executed.

    local msg = sandbox.run('return foo', {env = {foo = 'This is a global var on the the environment'}})

The `env` variable will be used as an "index" by the sandbox environment, but it will *not* be modified at all (changes
to the environment are thus lost). The only way to "get information out" from the sandboxed environments are:

Through side effects, like writing to a database. You will have to provide the side-effects functions in `env`:

    local val = 1
    local env = { write_db = function(new_val) val = new_val end }
    sandbox.run('write_db(2)')
    assert(val = 2)

Through returned values:

    local env = { amount = 1 }
    local result = sandbox.run('return amount + 1', { env = env })
    assert(result = 2)


Installation
============

Just copy sandbox.lua wherever you need it.

License
=======

This library is released under the MIT license. See MIT-LICENSE.txt for details

Specs
=====

This project uses [busted](https://github.com/Olivine-Labs/busted) for its specs. In order to run them, install it and then:

```
cd /path/to/where/the/spec/folder/is
busted spec/*
```
