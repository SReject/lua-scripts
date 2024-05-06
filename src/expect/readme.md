# Expect - A lua assertion library

## Exports

### `expect(values...)`
Returns a new [Expect instance](#expect%20instance) using the specified value(s) as the values to be validated.
```lua
---@param ... any The literal values to be validated
---@return Expect
function expect(...) end
```

### `expectf(callback, ...)`
Returns a new [Expect instance](#expect%20instance) using the result(s) of calling the callback function as the values to be validated.
```lua
---@param callback fun(...):any The callback function to call to retrieve values for validation
---@param ... any paramters to pass to the callback
---@return Expect
function expectf(callback, ...) end
```

### `suspect(values...)`
Returns a new [Expect instance](#expect%20instance) using the specified value(s) as the values to be validated.

Validation failure errors will be suppressed. The state of validation can be retrieved with [`instance:done()`](#instance:done)
```lua
---@param ... any The literal values to be validated
---@return Expect
function suspect(...) end
```

### `suspectf(callback, ...)`
Returns a new [Expect instance](#expect%20instance) using the result(s) of calling the callback function as the values to be validated.

Validation failure errors will be suppressed. The state of validation can be retrieved with [`instance:done()`](#instance:done)
```lua
---@param callback fun(...):any The callback function to call to retrieve values for validation
---@param ... any paramters to pass to the callback
---@return Expect
function suspectf(callback, ...) end
```

### `Mock(callback)`
Wraps the specified function so that calls to it will be tracked and returns a [`Mock Instance`](#mock%20instance);
```lua
---@param callback any|fun(...):any The callback to wrap. If the value is not a function, a function that returns the given value will be used
---@return Mock
function mock(callback)
```

### `consts`
A dictionary of metavalues/functions that can be used to alter how validation is handled

See [Metavalues](#metavalues) for more information

## Expect Instances
Instances of Expect may have the following methods.

Method calls can be chained together to formulate complex validations. eg, `expect():method():method()`

### `is()`
Resets the 'negate next' flag
```lua
---@return Expect
function Expect:is() end
```

### `isnt()`
Sets the 'negate next' flag, resulting in the next validation method call to result in the opposite of what it typically would.

That is, if validation passes, it would be considered to have failed and vice-versa.
```lua
---@return Expect
function Expect:isnt() end
function Expect:doesnt() end
```

### `equals(values...)`
Compares each actual value against the cooresponding parameter

May throw:
- [`INIT_FAILED`](#INIT_FAILED)
- [`EXPECTED_EQUAL`](#EXPECTED_EQUAL)
- [`EXPECTED_NOT_EQUAL`](#EXPECTED_NOT_EQUAL)

```lua
---@param ... any The cooresponding value to compare against
---@return Expect
function Expect:equals(...) end
function Expect:equal(...) end
function Expect:toEqual(...) end
function Expect:toNotEqual(...) end
```

### `of(types...)`
Compares each actual value's `type()` against the cooresponding parameter

May throw:
- [`INIT_FAILED`](#INIT_FAILED)
- [`EXPECTED_TYPE_OF`](#EXPECTED_TYPE_OF)
- [`EXPECTED_NOT_TYPE_OF`](#EXPECTED_NOT_TYPE_OF)

```lua
---@param ... string|all|any The cooresponding type to compare against
---@return Expect
function Expect:of(...) end
function Expect:toBe(...) end
function Expect:toNotBe(...) end
```

### `as(class...)`
Compares each actual value's `getmetatable().__index` against the cooresponding parameter

May throw:
- [`INIT_FAILED`](#INIT_FAILED)
- [`EXPECTED_INSTANCE_OF`](#EXPECTED_INSTANCE_OF)
- [`EXPECTED_NOT_INSTANCE_OF`](#EXPECTED_NOT_INSTANCE_OF)

```lua
---@param ... any The cooresponding metatable value to compare against
---@return Expect
function Expect:as(...) end
```

### `validate(callback)`
Calls the callback for each actual value and assumes validation passes if the callback returns `true` otherwise it assumes failure

May Throw:
- [`INIT_FAILED`](#INIT_FAILED)

```lua
---@param callback fun(value: any, index: number, state: table): boolean
---@return Expect
function Expect:validate(callback) end
```

### `throws()`
Requires that the attempt to get initial values resulted in an error being thrown

May throw:
- [`EXPECTED_TO_THROW`](#EXPECTED_TO_THROW)
- [`EXPECTED_NOT_TO_THROW`](#EXPECTED_NOT_TO_THROW)

```lua
---@return Expect
function Expect:throws() end
function Expect:throw() end
function Expect:toThrow() end
function Expect:toNotThrow() end
```

### `done()`
Returns the current state of validation; `true` if passing, `false` if not

Only applicable to Expect instances created with [`suspect()`](#suspect()) or [`suspectf()`](#suspect())

May Throw:
- ['NOT_SUPPRESSED'](#NOT_SUPPRESSED)

```lua
---@return boolean
function Expect:done() end
```



### `sub(indexes...)`
Returns a clone of the current Expect instance after updating its values to only include those at the specified indexes

May Throw:
- [`INIT_FAILED`](#INIT_FAILED)

```lua
---@param ... number The indexes to include
function Expect:sub(...) end
```

### `suberror()`
Returns a clone of the current Expect instance after updating its values to that of the initialization error and reseting the 'errored' flag to false(indicating success)

May Throw:
- [`INIT_SUCCEEDED`](#INIT_SUCCEEDED)

```lua
---@return Expect
function Expect:suberror() end
```

### `sup()`
Returns a child clone's original Expect instance

May Throw:
- [`INIT_SUCCEEDED`](#INIT_SUCCEEDED)
- [`NO_PARENT](#NO_PARENT)

```lua
---@return Expect
function Expect:sup() end
```


## Mock Instance

Represents a wrapped function for purposes of tracking calls, arguments of said calls, and results of each call to the wrapped function.

Arbitrary values can be applied to mock's instance and they will persist until `.reset()` is called

### `.reset()`
Resets the mock back to the initial state by clearing the `.calls` list and removing any arbitrary stored values

```lua
---@return Mock
function Mock.reset() end
```

### `.fn`
The wrapping function to be used in place of the wrapped function

```lua
---@type fun(...) end
local Mock.fn
```

### `.calls`
The current list of calls made to the mock function

`#instance.calls` can be used to retrieve the number of times the mock function has been called

```lua
---@class Mock.call
---@field args any[] The list of arguments provided to the call
---@field success boolean True if the call did not result in an error
---@field result any If the call did not error, the result of the call, otherwise the error information

---@type Mock.call[]
local Mock.call
```

## Meta values
Meta values (not to be confused with meta-anything in lua) are values that represent abstract notions or alter how validation is handled

### `consts.ignore()`
Indicates that validation of the cooresponding value to be tested should be skipped

```lua
---@return Expect.metavalue.ignore
function consts.ignore() end
```

### `consts.ignoreRest()`
Indicates that validation of the remaining values to be tested should be skipped

```lua
---@return Expect.metavalue.ignore
function consts.ignoreRest() end
```

### `consts.any(values...)`
Indicates validation of the cooresponding value may pass if any of the given values result in the test passing

```lua
---@param ... any A selection of values
---@return Expect.metavalue.any
function consts.any(values) end
```

### `consts.all(value)`
Indicates that validation should use the singular given value as the expected value for the test
```lua
---@param value any
---@return Expect.metavalue.all
function consts.all(value) end
```

## Errors

All errors take the form of an Expect Error:

```lua
---@class Expect.Error
---@field type string The error type
---@field message string A short human readable error message
---@field description string A longer human readable message explaining what the error indicates
---@field details any? Details specific to the error instance
```

### Fatal Errors
Fatal Errors are runtime errors that cannot be suppresed

#### `INIT_FAILED`
Indicates that the initial retrieval of values resulted in an error being raised.

Raised by methods that rely on the values successfully being retrieved to perform their task.

```lua
---@class Expect.InitFailed : Expect.Error
---@field details nil
```

#### `INIT_SUCCEEDED`
Indicates that the initial retrieval of values did NOT result in an error.

Raised by methods that rely on error information to perform their task.

```lua
---@class Expect.InitSucceeded : Expect.Error
---@field details nil
```

#### `NOT_SUPPRESSED`
Indicates that validation errors were not suppressed

Raised by methods that rely on validation errors being suppressed

```lua
---@class Expect.NotSuppressed : Expect.Error
---@field details nil
```

#### `NO_PARENT`
Indicates that the current Expect instance does not have a parent instance

Raised by methods that rely on a parent instance being present

```lua
---@class Expect.InitSucceeded : Expect.Error
---@field details nil
```

#### `INVALID_CALLBACK`
Indicates that a callback was not a callable function

Raised by methods that require a callback parameter be a function

```lua
---@class Expect.InvalidCallback : Expect.Error
---@field details nil
```



### Validation Errors

Validation errors are runtime errors that are suppressed when using `suspect()` or `suspectf()`

Validation errors extend the base Expect.Error by the following

```lua
---@class Expect.ValidationError : Expect.Error
---@field details { passed: boolean, negated: boolean, index: number?, expected: any?, actual: any? }
```

#### `EXPECTED_EQUAL`
Indicates that equivalency validation failed

#### `EXPECTED_NOT_EQUAL`
Indicates that equivullancy validation did not fail when it should have

#### `EXPECTED_TYPE_OF`
Indicates that type equivalency validation failed

#### `EXPECTED_TYPE_OF`
Indicates that type equivalency validation did not fail when it should have

#### `EXPECTED_INSTANCE_OF`
Indicates that metatable.__index equivalency validation failed

#### `EXPECTED_NOT_INSTANCE_OF`
Indicates that metatable.__index equivalency validation failed

#### `EXPECTED_VALIDATE`
Indicates that a validation callback resulted in validation failing

#### `EXPECTED_NOT_VALIDATE`
Indicates that a validation callback did not result in validation failing when it should have