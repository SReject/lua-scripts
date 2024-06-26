package.path = package.path .. ";/?.lua;/?/init.lua"

local BetterErrors = require('better-errors');
local Error = BetterErrors.new;
local error = BetterErrors.throw;

---@class (exact) sreject.Expect.metavalue.all

---@class (exact) sreject.Expect.metavalue.any

---@class (exact) sreject.Expect.metavalue.ignore

---@class (exact) sreject.Expect.metavalue.ignoreRest

-- Packs multi-values returns from a pcall into a table
---@return boolean,table<number, any>
local function tpcall(fnc, ...)
    local function packpcall(res, ...)
        return res, table.pack(...);
    end
    return packpcall(pcall(fnc, ...))
end

-- metavalue tracking
local ignored = setmetatable({}, { __newindex = function () end, __metatable = {} });
local ignoredRest = setmetatable({}, { __newindex = function () end, __metatable = {} });
local metavalues = setmetatable({}, { __mode = 'k' });

---@class (exact) sreject.Expect.validated
---@field passed boolean
---@field negated boolean
---@field index number?
---@field expected any?
---@field actual any?

---Performs a test against the instance's actual values
---@param self sreject.Expect The Expect instance to be tested
---@param validator fun(self: sreject.Expect, index: number, expected: any, actual: any):boolean Validator function; must return true if the test passed, false otherwise
---@param expects {[any]: any} The expected value(s) to provide to the validator
---@return sreject.Expect.validated
local function validate(self, validator, expects)

    -- At which index to stop iterating (inclusive)
    local stop;

    -- A singular value should be used as the expected counterpart to each stored-value being tested
    if (#expects == 1 and metavalues[expects[1]] ~= nil and metavalues[expects[1]].type == 'all') then
        local value = metavalues[expects[1]].value;
        expects = setmetatable({}, { __index = function () return value; end });
        stop = #(self.value);
    else
        stop = math.max(#(self.value), #expects);
    end


    local passed = true;
    local exp,got,index;

    for idx=1,stop,1 do

        -- track current index b/c idx is local to the for body
        index = idx;

        -- get expected and actual values
        exp, got = expects[idx], self.value[idx];

        -- exp = ignoreRest -> exit loop
        if (exp == ignoredRest) then
            break;

        -- testing the value at the current index should NOT be skipped
        elseif (exp ~= ignored) then

            -- expected value is a metavalue
            if (metavalues[exp] ~= nil) then
                local mexpect = metavalues[exp];

                -- invalid meta value
                if (mexpect.type ~= 'any') then
                    -- TODO: Error
                end

                -- 'any of' meta value -> Loop over each entry testing it against the actual value
                -- if a test passes, this iteration of the outer for-loop has passed
                local aValue = mexpect.value;
                local aPass = false;
                for i,aExp in ipairs(aValue) do
                    aPass = validator(self, idx, aExp, got);
                    if (aPass) then
                        exp = aExp;
                        break;
                    end
                end
                if (aPass == false) then
                    passed = false;
                    break;
                end

            -- not a meta value; compare expected value directly with the actual value
            elseif (validator(self, idx, exp, got) ~= true) then
                passed = false;
                break;
            end
        end
    end

    -- negated result
    if (self.negate) then
        self.negate = false;
        return { passed = (not passed), negated = true };

    -- passing result
    elseif (passed) then
        return { passed = true, negated = false };

    -- failure result
    else
        return { passed = false, negated = false, index = index, expected = exp, actual = got };
    end
end

---@class (exact) sreject.Expect
---@field package parent sreject.Expect|nil The parent Expect instance
---@field package negate boolean Indicates the next check should be negated
---@field package success boolean Indicates whether the initial attempt to retrieve values raised an error
---@field package value {[number]: any} The values being validataed
---@field package suppress boolean When true, instead of throwing the result will be stored for retrieval
---@field package result boolean Tracking property when suppress is truthy
local Expect = {};

---Creates a shallow copy of an Expect instance
---@param subject sreject.Expect The subject to copy
---@param fields {[string]: any} key-value pairs of fields to overwrite
---@return sreject.Expect
local function subcopy(subject, fields)
    local instance = {};
    for k,v in next, subject, nil do
        instance[k] = v;
    end
    if (fields ~= nil) then
        for k,v in next, fields, nil do
            instance[k] = v;
        end
    end
    return setmetatable(instance, { __index = Expect });
end

---Resets negation flag set by `:isnt()`
---@return sreject.Expect self The current Expect instance
function Expect:is()
    self.negate = false;
    return self;
end

---Negates (reverses) the result of the next check
---@return sreject.Expect # The current Expect instance
function Expect:isnt()
    self.negate = true;
    return self;
end

---Negates (reverses) the result of the next check
---@return sreject.Expect # The current Expect instance
function Expect:doesnt()
    return self:isnt()
end

---Create a new child Expect instance from values at the given indexes of the current instance
---
---Throws: `INIT_FAILED` - (*fatal*) `:sub()` cannot be used when the initial retrieval of values failed
---@param ... number The indexes to reference
---@return sreject.Expect Child # A new Expect instance
function Expect:sub(...)
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    else
        local indexes, values = {...}, {};
        for i=1,#indexes,1 do
            table.insert(values, self.value[i]);
        end
        return subcopy(self, {parent = self, value = values });
    end
end

---Creates a new child Expect instance from the current instance, using the
---error as the base value and setting the success flag to true for the child instance.
---
---Throws: `INIT_SUCCEEDED` - (*fatal*) `:suberror()` cannot be used if the retrieval of initial values was successful
---@return sreject.Expect Child
function Expect:suberror()
    if (self.success == true) then
        error(Error('INIT_SUCCEEDED', { message = 'cannot be used if initial retrieval of values is successful'}));
    else
        return subcopy(self, { parent = self, success = true });
    end
end

---Returns to the parent of a :sub() or :suberror() Expect instance
---
---Throws: `INIT_FAILED` - (*fatal*) `:sup()` cannot be used when the initial retrieval of values failed
---
---Throws: `NO_PARENT` - (*fatal*) `:sup()` cannot be used on non-child instances
---@return sreject.Expect Parent # The parent Expect instance
function Expect:sup()
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    elseif (self.parent == nil) then
        error(Error('NO_PARENT', { message = 'current instance does not have a parent' }));
    else
        return self.parent;
    end
end

---Equality check via comparing the actual value against the corresponding expected value
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:equal()s` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_EQUAL` - An actual value did not equal the corresponding expected value
---
---Throws: `EXPECTED_NOT_TYPE_OF` - When negated, an actual value equalled the corresponding expected value
---@param ... any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:equals(...)
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    elseif (self.suppress and self.result == false) then
        return self;
    else
        local test = validate(self, function (self, index, expect, actual) return expect == actual end, table.pack(...))
        if (test.passed == false) then
            if (self.suppress) then
                self.result = false;

            elseif (test.negated) then
                error(Error('EXPECTED_NOT_EQUAL', { message = 'actual value(s) are equal to expected values'}));
            else
                error(Error('EXPECTED_EQUAL', { message = 'actual value(s) are not equal to expect values'}));
            end
        end
        return self;
    end
end

---Equality check via comparing the actual value against the corresponding expected value
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:equal()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_EQUAL` - An actual value did not equal the corresponding expected value
---
---Throws: `EXPECTED_NOT_EQUAL` - When negated, an actual value equalled the corresponding expected value
---@param ... any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:equal(...)
    return self:equals(...);
end

---Equality check via comparing the actual value against the corresponding expected value
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:equal()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_EQUAL` - An actual value did not equal the corresponding expected value
---
---Throws: `EXPECTED_NOT_EQUAL` - When negated, an actual value equalled the corresponding expected value
---@param ... any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:toEqual(...)
    return self:equals(...);
end

---Negated equality check via comparing the actual value against the corresponding expected value
---
---Throws: `INIT_FAILED` - (*fatal*) `:equal()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_NOT_EQUAL` - An actual value equalled the corresponding expected value
---@param ... any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:toNotEqual(...)
    return self:isnt():equals(...);
end

---Type check via comparing the result of calling `type()` for each actual value against the corresponding expected value
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:of()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_TYPE_OF` - The stored values' types did not equal those that were expected
---
---Throws: `EXPECTED_NOT_TYPE_OF` - When negated, the stored values' types did equal those that were expected
---@param ... string|string|sreject.Expect.metavalue.all|sreject.Expect.metavalue.any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:of(...)
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    elseif (self.suppress and self.result == false) then
        return self;
    else
        local test = validate(self, function (self, index, expect, actual) return expect == type(actual); end, table.pack(...))
        if (test.passed == false) then
            if (self.suppress) then
                self.result = false;
            elseif (test.negated) then
                error(Error('EXPECTED_NOT_TYPE_OF', { message = 'actual value(s) were of expected type value'}));
            else
                error(Error('EXPECTED_NOT_TYPE_OF', { message = 'actual value(s) were not of expected type value'}));
            end
        end
        return self;
    end
end

---Type check via comparing the result of calling `type()` for each actual value against the corresponding expected value
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:toBe()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_TYPE_OF` - The stored values' types did not equal those that were expected
---
---Throws: `EXPECTED_NOT_TYPE_OF` - When negated, the stored values' types did equal those that were expected
---@param ... string|string|sreject.Expect.metavalue.all|sreject.Expect.metavalue.any The corresponding type to test the actual values against
---@return sreject.Expect
function Expect:toBe(...)
    return self:of(...);
end

---Inhertance check via comparing each actual value's `metatable.__index` against the specified expected values
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:a()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_INSTANCE_OF` - The actual values' metatable index did not equal those that were expected
---
---Throws: `EXPECTED_NOT_INSTANCE_OF` - When negated, the actual values' metatable index did equal those that were expected
---@param ... any The corresponding class to test the actual values against
---@return sreject.Expect
function Expect:as(...)
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    elseif (self.suppress and self.result == false) then
        return self;
    else
        local test = validate(
            self,
            function (self, index, expect, actual)
                return actual ~= nil and expect == getmetatable(actual).__index;
            end,
            table.pack(...)
        )
        if (test.passed == false) then
            if (self.suppress) then
                self.result = false;
            elseif (test.negated) then
                error(Error('EXPECTED_NOT_INSTANCE_OF', { message = 'actual value(s) were instances of expected value'}));
            else
                error(Error('EXPECTED_INSTANCE_OF', { message = 'actual value(s) were not instances of expected value'}));
            end
        end
        return self;
    end
end

---Requires that the input threw an error
---
---Negatable
---
---Throws: `EXPECTED_TO_THROW` - The retrieval of initial values failed to throw an expected error
---
---Throws: `EXPECTED_NOT_TO_THROW` - When negated, the retrieval of initial values threw an unexpected error
function Expect:throws()
    if (self.suppress and self.result == false) then
        return self;
    end
    local passed = self.success == false;
    local negated = self.negate;
    if (self.negate) then
        self.negate = false;
        passed = (not passed);
    end
    if (passed == false) then
        if (self.suppress) then
            self.result = false;
        elseif (negated) then
            error(Error('EXPECTED_TO_THROW', { message = 'retrevial of actual value(s) did not raise an error'}));
        else
            error(Error('EXPECTED_NOT_TO_THROW', { message = 'retrieval of actual value(s) raised an error'}));
        end
    end
    return self;
end

---Requires that the input threw an error
---
---Negatable
---
---Throws: `EXPECTED_TO_THROW` - The retrieval of initial values failed to throw an expected error
---
---Throws: `EXPECTED_NOT_TO_THROW` - When negated, the retrieval of initial values threw an unexpected error
function Expect:throw()
    return self:throws();
end

---Requires that the input threw an error
---
---Negatable
---
---Throws: `EXPECTED_TO_THROW` - The retrieval of initial values failed to throw an expected error
---
---Throws: `EXPECTED_NOT_TO_THROW` - When negated, the retrieval of initial values threw an unexpected error
function Expect:toThrow()
    return self:throws();
end

---Expects retrieval of initial values not to throw an error
---
---Negatable
---
---Throws: `EXPECTED_NOT_TO_THROW` - The retrieval of initial values threw an unexpected error
function Expect:toNotThrow()
    return self:isnt():throws();
end

---Requires the instance's actual values to pass a given validation function
---
---Negatable
---
---Throws: `INIT_FAILED` - (*fatal*) `:validate()` cannot be used when the initial retrieval of values failed
---
---Throws: `EXPECTED_VALIDATE` - actual values did not pass the provided callback
---
---Throws: `EXPECTED_NOT_VALIDATE` - actual values passed the provided callback when they should not have
---@param callback fun(value: any, index: number, state: table):boolean
---@return sreject.Expect
function Expect:validate(callback)
    if (self.success == false) then
        error(Error('INIT_FAILED', { message = 'retrieves of initial values failed' }));
    elseif (self.suppress and self.result == false) then
        return self;
    else
        local index;
        local pass = true;
        local state = {};
        for idx,value in ipairs(self.value) do
            index = idx;
            pass = callback(value, index, state);
            if (pass ~= true) then
                pass = false;
                break;
            end
        end
        local negated = self.negate;
        if (negated) then
            self.negate = false;
            pass = (not pass);
        end
        if (pass == false) then
            if (self.suppress) then
                self.result = false;
            elseif (negated) then
                error(Error('EXPECTED_NOT_VALIDATE', { message = 'actual value(s) passsed validation callback' }));
            else
                error(Error('EXPECTED_VALIDATE', { message = 'actual value(s) did not pass validation callback' }));
            end
        end
        return self;
    end
end

---Retrieves the result if throwing errors is suppressed for the instance
---
---Throws: `NOT_SUPPRESSED` - (*fatal*) Error reporting for the instance was not suppressed so the result cannot be retrieved
---@return boolean
function Expect:done()
    if (self.suppress ~= true) then
        error(Error('NOT_SUPPRESSED', { message = 'instance does not have raising errors suppressed' }));
    end
    return self.result;
end


local exports = { consts = {} };

---Creates an Expect instance using provided values as the base value
---@param ... any Values to use as the base value
---@return sreject.Expect
function exports.expect(...)
    return setmetatable({
        parent = nil,
        negate = false,
        success = true,
        value = table.pack(...),
        suppress = false,
        result = true
    }, { __index = Expect });
end

---Creates an Expect instance using the result of calling `callback` as the base value
---@param callback any The function to call to get the base value
---@return sreject.Expect
function exports.expectf(callback, ...)
    if (type(callback) ~= 'function') then
        error(Error('INVALID_CALLBACK', { message = 'callback is not a function' }));
    end

    local success, value = tpcall(callback, ...);
    return setmetatable({
        parent = false,
        negate = false,
        success = success,
        value = value,
        suppress = false,
        result = true
    }, { __index = Expect });
end

---Creates an Expect instance using provided values as the base value
---
---Instead of raising errors when validation fails the result is tracked and
---can be retrieved with :done()
---@param ... any Values to use as the base value
---@return sreject.Expect
function exports.suspect(...)
    return setmetatable({
        parent = nil,
        negate = false,
        success = true,
        value = table.pack(...),
        suppress = true,
        result = true
    }, { __index = Expect });
end

---Creates an Expect instance using the result of calling `callback` as the base value
---
---Instead of raising errors when validation fails the result is tracked and
---can be retrieved with :done()
---@param callback any The function to call to get the base value
---@return sreject.Expect
function exports.suspectf(callback, ...)
    if (type(callback) ~= 'function') then
        error(Error('INVALID_CALLBACK', { message = 'callback is not a function' }));
    end

    local success, value = tpcall(callback, ...);
    return setmetatable({
        parent = false,
        negate = false,
        success = success,
        value = value,
        suppress = true,
        result = true
    }, { __index = Expect });
end

---@class sreject.expect.Mock
---@field calls {[number]: { args: {[number]: any}, success?: boolean, result: any }}
---@field [any] any

---Creates a mocked function
---@param fn fun(...):any The function to wrap
---@return sreject.expect.Mock
function exports.Mock(fn)
    local mocked = { calls = {} };

    function mocked.reset()
        for i,k in next, mocked, nil do
            if (i ~= 'reset' and i ~= 'fn') then
                mocked[i] = nil;
            end
        end
    end

    function mocked.fn(...)
        local callInfo = {
            args = table.pack(...);
        }
        table.insert(mocked.calls, callInfo);
        if (type(fn) == 'function') then
            local success,result = tpcall(fn, ...);
            callInfo.success = success;
            callInfo.result = result;
            if (success == true) then
                return table.unpack(result);
            else
                error(result,2);
            end
        else
            return fn;
        end
    end;
    return mocked
end;

---Skips the corresponding actual value for the test
---@return sreject.Expect.metavalue.ignore
function exports.consts.ignore() return ignored; end

---Skips the remaining actual values in a test
---@return sreject.Expect.metavalue.ignoreRest
function exports.consts.ignoreRest() return ignoredRest; end

---Creates a new 'all' meta value
---
---Cannot be used within itself or within the `any()` metavalue
---@param value any The value to use for each comparison test against the 'all' meta value
---@return sreject.Expect.metavalue.all
function exports.consts.all(value)
    local result = {};
    metavalues[result] = { type = 'all', value = value }
    return result
end

---Creates a new 'any' meta value
---
---Cannot be used within itself
---@param ... any A list of values that will be compared against before the test fails
---@return sreject.Expect.metavalue.any
function exports.consts.any(...)
    local result = {};
    metavalues[result] = { type = 'any', value = table.pack(...) }
    return result;
end

return exports;