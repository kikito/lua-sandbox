local sandbox = require 'sandbox'

describe('sandbox.run', function()

  describe('when handling base cases', function()
    it('can run harmless functions', function()
      local r = sandbox.run(function() return 'hello' end)
      assert.equal(r, 'hello')
    end)

    it('can run harmless strings', function()
      local r = sandbox.run("return 'hello'")
      assert.equal(r, 'hello')
    end)

    it('has access to safe methods', function()
      assert.equal(10,      sandbox.run("return tonumber('10')"))
      assert.equal('HELLO', sandbox.run("return string.upper('hello')"))
      assert.equal(1,       sandbox.run("local a = {3,2,1}; table.sort(a); return a[1]"))
      assert.equal(10,      sandbox.run("return math.max(1,10)"))
    end)

    it('does not allow access to not-safe stuff', function()
      assert.has_error(function() sandbox.run('return setmetatable({}, {})') end)
      assert.has_error(function() sandbox.run('return string.rep("hello", 5)') end)
      assert.has_error(function() sandbox.run('return _G.string.upper("hello")') end)
    end)
  end)

  describe('when handling string.rep', function()
    it('does not allow pesky string:rep', function()
      assert.has_error(function() sandbox.run('return ("hello"):rep(5)') end)
    end)

    it('restores the value of string.rep', function()
      sandbox.run("")
      assert.equal('hellohello', string.rep('hello', 2))
    end)

    it('restores string.rep even if there is an error', function()
      assert.has_error(function() sandbox.run("error('foo')") end)
      assert.equal('hellohello', string.rep('hello', 2))
    end)

    it('passes parameters to the function', function()
      assert.equal(sandbox.run(function(a,b) return a + b end, {}, 1,2), 3)
    end)
  end)


  describe('when the sandboxed function tries to modify the base environment', function()

    it('does not allow modifying the modules', function()
      assert.has_error(function() sandbox.run("string.foo = 1") end)
      assert.has_error(function() sandbox.run("string.char = 1") end)
    end)

    it('does not persist modifications of base functions', function()
      sandbox.run('error = function() end')
      assert.has_error(function() sandbox.run("error('this should be raised')") end)
    end)

    it('DOES persist modification to base functions when they are provided by the base env', function()
      local env = {['next'] = 'hello'}
      sandbox.run('next = "bye"', {env=env})
      assert.equal(env['next'], 'bye')
    end)
  end)


  describe('when given infinite loops', function()

    it('throws an error with infinite loops', function()
      assert.has_error(function() sandbox.run("while true do end") end)
    end)

    it('restores string.rep even after a while true', function()
      assert.has_error(function() sandbox.run("while true do end") end)
      assert.equal('hellohello', string.rep('hello', 2))
    end)

    it('accepts a quota param', function()
      assert.no_has_error(function() sandbox.run("for i=1,100 do end") end)
      assert.has_error(function() sandbox.run("for i=1,100 do end", {quota = 20}) end)
    end)

  end)


  describe('when given an env option', function()
    it('is available on the sandboxed env', function()
      assert.equal(1, sandbox.run("return foo", {env = {foo = 1}}))
    end)

    it('does not hide base env', function()
      assert.equal('HELLO', sandbox.run("return string.upper(foo)", {env = {foo = 'hello'}}))
    end)

    it('can modify the env', function()
      local env = {foo = 1}
      sandbox.run("foo = 2", {env = env})
      assert.equal(env.foo, 2)
    end)
  end)

end)
