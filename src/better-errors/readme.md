# Better Errors
Adds better error instancing than what is provided by Lua

# Example
```lua
local BetterErrors = require('better-errors');

-- When called, creates a new BetterError error instance
local Error = BetterErrors.new;

-- Replace the context's `error()` with BE's throw()
-- so that a stack trace will be created with the error
-- is raised
local error = BetterErrors.throw;

-- Create a new error
local myError = Error('MY_ERROR_TYPE', { message = 'I did an error' })

-- Raise the error
error(myError);
```

# Usage
BetterErrors exports a table of key-value pairing

### `new()`
Creates a new BetterErrors [Error instance](#error-instance)

```lua
---@param errtype string # The error type; eg 'GENERIC_ERROR'
---@param data {[any]: any}? # key-value pairing of data to append to the error
---@return ErrorInstance
function BetterErrors.new(errtype, data) end
```

### `wrap(errtype, data)`
Returns a wrapper function that creates a BetterErrors error instance and applies the default values to the instance.

```lua
---@param errtype string The error type; eg 'GENERIC_ERROR'
---@param data {[any]: any}? key-value pairing of data to append to the error
---@return fun(data: (string|{[any]: any})?): ErrorInstance # if data is a string, it will be used as the instance's `message` property
function BetterErrors.wrap(errtype, data) end
```

### `throw(error)`
Raises an error

```lua
---@param error string|ErrorInstance|any # The error to raise. If its a string, a generic error will be created and the string will be used as the error's `message` property
function BetterErrors.throw(error) end
```

## Error Instance
Represents a BetterErrors error instance.

Instances have the following properties, though more may be added after creation

#### `.type`
The error type as specified when the instance was created; eg `GENERIC_ERROR'

```lua
---@type string
local Error.type;
```

#### `.message`
The message accompanying the error

```lua
---@type string
local Error.message?;
```

#### `.stacktrace`
The stack trace of the thrown error. Only applicable if the error has been passed to `throw()`

```lua
---@type {name: string --[[ The callers function name ]], source: string --[[ the file the caller is from ]], line: number, column: number}[]?
local Error.stacktrace
```
