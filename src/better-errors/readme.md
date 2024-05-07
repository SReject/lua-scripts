# Better Error
Adds better error instancing than what is provided by Lua

# Example
```lua
local BetterError = require('better-error');

-- When called, creates a new BetterError error instance
local Error = BetterError.Error.new;

-- Replace the context's `error()` with Better Error's throw()
local error = BetterError.throw;

-- Create a new error
local myError = Error('MY_ERROR_TYPE', { message = 'I did an error' })

-- Raise the error
error(myError);
```