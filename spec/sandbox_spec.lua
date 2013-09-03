local sandbox = require 'sandbox'

describe('sandbox', function()

  it('can run harmless functions', function()
    local r = sandbox(function() return 'hello' end)
    assert.equal(r, 'hello')
  end)

  it('can run harmless strings', function()
    local r = sandbox("return 'hello'")
    assert.equal(r, 'hello')
  end)

  it('has access to safe methods', function()
    assert.equal(10,      sandbox("return tonumber('10')"))
    assert.equal('HELLO', sandbox("return string.upper('hello')"))
    assert.equal(1,       sandbox("local a = {3,2,1}; table.sort(a); return a[1]"))
    assert.equal(10,      sandbox("return math.max(1,10)"))
  end)

  it('does not allow access to not-safe stuff', function()
    assert.has_error(function() sandbox('return setmetatable({}, {})') end)
    assert.has_error(function() sandbox('return string.rep("hello", 5)') end)
    assert.has_error(function() sandbox('return _G.string.upper("hello")') end)
  end)

  it('does not allow pesky string:rep', function()
    assert.has_error(function() sandbox('return ("hello"):rep(5)') end)
  end)

  it('restores the value of string.rep', function()
    sandbox("")
    assert.equal('hellohello', string.rep('hello', 2))
  end)

  it('restores string.rep even if there is an error', function()
    assert.has_error(function() sandbox("error('foo')") end)
    assert.equal('hellohello', string.rep('hello', 2))
  end)

  it('should not persist modifying the packages', function()
    sandbox("string.foo = 1")
    assert.is_nil(sandbox("return string.foo"))
  end)


  describe('when handling infinite loops', function()

    it('throws an error with infinite loops', function()
      assert.has_error(function() sandbox("while true do end") end)
    end)

    it('restores string.rep even after a while true', function()
      assert.has_error(function() sandbox("while true do end") end)
      assert.equal('hellohello', string.rep('hello', 2))
    end)

    it('accepts a quota param', function()
      assert.no_has_error(function() sandbox("for i=1,100 do end") end)
      assert.has_error(function() sandbox("for i=1,100 do end", {quota = 20}) end)
    end)

  end)

  describe('when given an env option', function()
    it('is available on the sandboxed env', function()
      assert.equal(1, sandbox("return foo", {env = {foo = 1}}))
    end)

    it('does not hide base env', function()
      assert.equal('HELLO', sandbox("return string.upper(foo)", {env = {foo = 'hello'}}))
    end)

    it('can not modify the env', function()
      local env = {foo = 1}
      sandbox("foo = 2", {env = env})
      assert.equal(env.foo, 1)
    end)
  end)

  describe('when given a refs option', function()
    it('is available on the sandboxed env', function()
      assert.equal(1, sandbox("return foo", {refs = {foo = 1}}))
    end)

    it('does not hide base env', function()
      assert.equal('HELLO', sandbox("return string.upper(foo)", {refs = {foo = 'hello'}}))
    end)

    it('can modify the refs', function()
      local refs = {foo = 1}
      sandbox("foo = 2", {refs = refs})
      assert.equal(refs.foo, 2)
    end)

    it('can modify the ref tables keys', function()
      local refs = {items = {quantity = 1}}
      sandbox("items.quantity = 2", {refs = refs})
      assert.equal(refs.items.quantity, 2)
    end)


  end)



end)
