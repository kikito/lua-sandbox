# v1.0.1 (2021-01)

- Fix a bug in which the base environment wasn't overrideable with `false`

# v1.0.0 (2021-01)

- Added support for all major versions of PUC Rio Lua and LuaJIT
- Only Lua strings are admitted now, "naked Lua" functions are not permitted any more
- Bytecode is blocked in all versions of Lua except PUC Rio Lua 5.1
- The library throws an error when attempting to use quotas in LuaJIT
- Environments are now strictly read-only
- Environments can have metatables with indexes, and they are respected
- Environments can override the base environment

# v0.5.0 (2013)

Initial version
