# Array
Array.lua is an [Object Orientated Programming](https://www.lua.org/pil/16.html) library for Lua inspired by javascript's Array functionality.

Features include easy [modification](), [manipulation](), [iteration](), and [chaining](#chaining)

# Usage

Array.lua is an [Object Orientated Programming](https://www.lua.org/pil/16.html) library.

### Requiring
```lua
-- Array instancer
local Array = require('array').Array.new;
```

### Instancing
To create a new instance call `Array.new()` with the initial values of the array

```lua
local example = require('array').Array.new("a", "b", "c" ) -- { "a", "b", "c" }
```




# Properties
Array instances have the following properties

### `.length`
Returns the length of the array

```lua
---@type number
local Array.length
```




# Modification
The following methods modify the underlaying Array instance

### `.insert(array, position, ...)`
Inserts the given item(s) into the array at the given position then returns the Array instance.

If `position` is nil, the beginning of the array is assumed.

If `position` is less than 1, it is assumed to be counting backwards from the end of the array.

[`Chainable`](#chaining)

```lua
---@param array Array
---@param position number?,
---@param ... any?
---@return Array
function Array.insert(array, position, ...) end
```

### `.pop(araray)`
Removes the last item from the array and returns the removed item. If there is no item to remove, `nil` is returned

```lua
---@param array Array
---@return any
function Array.pop(array) end
```

### `.push(array, ...)`
Adds the given item(s) to the end of the array and returns the Array instance

[Chainable](#chaining)

```lua
---@param array Array
---@param ... any
---@return Array
function Array.push(array, ...) end
```

### `.remove(array, position, count)`
Removes `count` number of items from the array at the given position and then returns the Array instance

If `position` is nil, the beginning of the array is assumed.

If `position` is less than 1, it is assumed to be counting backwards from the end of the array.

If `count` is nil, all items from `position` onward are removed

If `count` is less than 1, the number of items to be removed is equal to subtracting `count` from the number of items from `position` onwards.

[`Chainable`](#chaining)

```lua
---@param array Array
---@param position number?,
---@param count number?
---@return Array
function Array.remove(array, position, count) end
function Array.delete(array, position, count) end
```

### `.shift(araray)`
Removes the first item from the array and returns the removed item. If there is no item to remove, `nil` is returned

```lua
---@param array Array
---@return any
function Array.shift(array) end
```

### `.splice(array, positition, count, ...)`
Removes `count` number of items from the array at the given position, inserts the given item(s) into the array at the given position, and then returns the Array instance

If `position` is nil, the beginning of the array is assumed.

If `position` is less than 1, it is assumed to be counting backwards from the end of the array.

if `count` is `nil` or less than 1, no deletions will occur.

[`Chainable`](#chaining)

```lua
---@param array Array
---@param position number?,
---@param count number?
---@param ... any
---@return Array
function Array.splice(array, position, count, ...) end
```

### `.unshift(array, item...)`
Adds the given item(s) to the start of the array and returns the Array instance

[Chainable](#chaining)

```lua
---@param array Array
---@param ... any
---@return Array
function Array.unshift(array, ...) end
```




# Manipulation
The following methods manipulate the underlaying Array instance without altering it.

### `.concat(array...)`

Creates a new Array instance, adds the items from each given array, then returns the new instance.

[chainable](#chainable)

```lua
---@param ... Array
---@return Array
function Array.chainable(...) end
```

### `.join(delimiter, stringifier)`
Joins items in the array into a singular string that is returned.

If `stringifier` is specified, it will be called for each item in the array and its result will be converted to a string for concatenation to the result

```lua
---@param array Array
---@param delimiter string
---@param stringifier (fun (value, index, self):string)?
function Array.join(array, delimiter, stringifier) end
```


### `.sort(callback, sortSelf)`
Returns a new Array instance containing the items of the base array instances in sorted order

If `callback` must be nil or follow Lua's [sort callback](https://www.lua.org/pil/19.3.html).

If `sortSelf` is `true` the base array instance is sorted instead of new instance being created.

[Chainable](#chaining)

```lua
---@param array Array
---@param callback (fun(a,b):boolean)?
---@param sortSelf boolean?
function Array.sort(array, callback, sortSelf) end
```

### `.sweep()`
Returns a new Array instance containing only the non-nil items of the base array instance

```lua
---@param array Array
---@return Array
function Array.sweep(array) end
```

# Iteration

### `.all(testCallback, atLeastOne)`
Returns a boolean value indicating whether all values of the array passed `testCallback()`

It is assumed that an item passes if `testCallback()` returns true. All other values are assumed false.

If `atLeastOne` is true empty arrays will result in `false` being returned

```lua
---@param array Array
---@param testCallback fun(value: any, index: number, array: Array):boolean
---@param atLeastOne boolean?
---@return boolean
function Array.all(array, testCallback, atLeastOne) end
```

### `.any(testCallback, allowEmpty)`
Returns a boolean value if any item in the array passes `testCallback()`

It is assumed that an item passes if `testCallback()` returns true. All other values are assumed false.

If `allowEmpty` is true empty arrays will result in `true` being returned

```lua
---@param array Array
---@param testCallback fun(value: any, index: number, array: Array):boolean
---@param allowEmpty boolean?
---@return boolean
function Array.any(array, testCallback, allowEmpty) end
```

### `.filter(testCallback)`
Returns a new Array instance containing only the items from the base array instance that pass `testCallback()`.

It is assumed that an item passes if `testCallback()` returns true. All other values are assumed false.

[Chainable](#chaining)

```lua
---@param array Array
---@param testCallback fun(value: any, index: number, array: Array):boolean
---@return Array
function Array.filter(array, testCallback) end
```

### `.find(testCallback, position)`
Returns the first index at or beyond `position` that passes `testCallback()`, if no item passes `nil` is returned

It is assumed that an item passes if `testCallback()` returns true. All other values are assumed false.

if `position` is nil the start of the array is assumed

if `position` is less than 1, it assumed to be counting backwards from the end of the array

```lua
---@param array Array
---@param testCallback fun(value: any, index: number, array: Array):boolean
---@return number|nil
function Array.find(array, testCallback) end
```

### `.findLast(testCallback, stopPosition)`
Traverses the array in reverse order upto and including `stopPosition` and returns the first index that passes `testCallback()`. if no item passes `nil` is returned

It is assumed that an item passes if `testCallback()` returns true. All other values are assumed false.

if `stopPosition` is nil the start of the array is assumed

if `stopPosition` is less than 1, it assumed to be counting backwards from the end of the array

```lua
---@param array Array
---@param testCallback fun(value: any, index: number, array: Array):boolean
---@param stopPosition number?
---@return number|nil
function Array.find(array, testCallback) end
```

### `.each(callback)`
Calls the given `callback` for each item in the array in the order they appear.

[Chainable](#chaining)

```lua
---@param array Array
---@param callback fun(value: any, index: number, array: Array):nil
---@return Array
function Array.each(array, callback) end
function Array.forEach(array, callback) end
```

### `.map(transformer)`
Returns a new Array instance containing values returned by calling the specified `transformer()` for each item in the array.

[Chainable](#chaining)

```lua
---@param array Array
---@param transformer fun(value: any, index: number, array:Array):any
---@return Array
function Array.map(array, callback) end;
```

### `.reduce(reducer, initialValue)`
Returns the end result of calling the specified `reducer()` for each item in the array.

`reducer()` will be passed `initialValue` for the first item of the array, and subquent calls be be passed the returned value of the previous `reducer()` call.

```lua
---@param array Array
---@param reducer fun(accumulator: any, value: any, index: number, array: Array):any
---@param initialValue any?
---@return any
function Array.reduce(array, reducer, initialValue) end
```




# Chaining
Any method that returns an Array instance may be chained into another array-related method call

```lua
-- Not using chaining, leveraging a result-tracking variable
local result = Array.new(1, 2, 3, 26);
result = Array.map(result, function (value) return string.char(96 + value)); -- {"a", "b", "c", "z"}
result = Array.map(result, string.upper); -- {"A", "B", "C", "Z"}
result = Array.filter(result, function (value) return value ~= "Z" end); -- {"A", "B", "C"}
result = Array.reverse(result); -- {"C", "B", "A"}
print(result.join(result, ',')); -- "C,B,A"

-- Not using chaining or result-tracking variable
print(
    Array.join(
        Array.reverse(
            Array.filter(
                Array.map(
                    Array.map(
                        Array.new(1, 2, 3, 26),
                        function (value) return string.char(96 + value)
                    ), -- {"a", "b", "c", "z"}
                    string.upper
                ), -- {"A", "B", "C", "Z"}
                function (value) return value ~= "Z" end
            ) -- {"A", "B", "C"}
        ), -- {"C", "B", "A"}
        ","
    ) -- "C,B,A"
);

-- Using chaining; no result-tracking variable needed
print(
    Array.new(1, 2, 3, 26)
        :map(function (value) return string.char(96 + value)) -- {"a", "b", "c", "z"}
        :map(string.upper) -- {"A", "B", "C", "Z"}
        :filter(function (value) return value ~= "Z" end) -- {"A", "B", "C"}
        :reverse() -- {"C", "B", "A"}
        :join(",") -- "C,B,A"
);
```