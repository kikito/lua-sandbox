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


  describe('when handling infinite loops', function()
    it('throws an error with infinite loops', function()
      assert.has_error(function() sandbox("while true do end") end)
    end)

    it('#focus accepts a limit param', function()
      --assert.no_has_error(function() sandbox("for i=1,10000 do end") end)
      assert.has_error(function() sandbox("for i=1,10000 do end", {limit = 50}) end)
    end)
  end)

end)
