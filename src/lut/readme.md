# LUT - Lua unit tests
Wanna test your awesome script but writing tests isn't awesome?! Well look no further beca... nevermind, writing tests is never awesome. This is a library to make writing them less-not-awesome.


# Usage
Lut exports a table with a an entry-point field, `lut`, which is a factory function. It must be called to get access to the good bits
```lua
---Creates a new testing group.
---
---Testing groups can be nested inside of testing groups
---@function Describe
---@param title string # The title to display
---@param body fun():nil # The group's body

---Creates a unit test
---@function It
---@param title string # The title of the unit test
---@param body fun():nil # The unit test to run. it should return nil for success, or raise an error for failures

---Runs the tests
---@function Test
---@param ... number|string # Will walk the test structure and only run the specified test-group/unit-test

---@function Lut
---@param reporter? # A lut-compatible output reporter
---@return Describe,It,Test # Testing methods
local lut = require('lut').lut;

---@type Describe,It,Test
local describe, it, test = lut();
```

# Example
Check out [array.spec.lua](../array/array.spec.lua)


