
---@class Expect
---@field errored boolean
---@field error any
---@field results any[]
local Expect = {};

---The expected result did not return expected values
---@param ... any The value(s) the result should equal. This is not an or/and, but compares each index of the result to each index of the value(s) given
function Expect:toEqual(...)
    if (self.errored == true) then
        error('Threw an unexpected error: ' .. tostring(self.error[1]));
    end

    local results = self.results;
    if (results == nil) then
        results = {};
    end
    local args = {...};
    if (args == nil) then
        args = {};
    end
    local len = #args;
    if (len < #results) then
        error('returned more values('..#results..') than expected('..len..')');
    elseif (len > #results) then
        error('returned fewer values('..#results..') than expected('..len..')');
    else
        local index,raise = 1, false;
        while (index <= len) do
            if (args[index] ~= results[index]) then
                raise = true;
                break;
            end
            index = index + 1;
        end
        if (raise) then
            error('returned value('..tostring(results[index])..') did not equal expected value('..tostring(args[index])..')');
        end

        return self;
    end
end

---The expected result returned values that it should not
---@param ... any The value(s) the result should not have equaled. This is not an or/and, but compares each index of the result to each index of the value(s) given
function Expect:toNotEqual(...)
    if (self.errored) then
        error('Threw an unexpected error: ' .. tostring(self.error[1]));
    end

    local isEqual = pcall(Expect.toEqual, self, ...);
    if (isEqual == true) then
        error('returned values equaled expected values');
    else
        return self;
    end
end

function Expect:toBe(...)
    if (self.errored) then
        error('Threw an unexpected error: ' .. tostring(self.error[1]));
    else

        local results = self.results;
        if (results == nil) then
            results = {};
        end

        local args = {...};
        if (args == nil) then
            args = {};
        end

        local len = #args;
        if (len < #results) then
            error('returned more values('..#results..') than expected('..len..')');
        elseif (len > #results) then
            error('returned fewer values('..#results..') than expected('..len..')');
        else
            local index,raise = 1, false;
            while (index <= len) do
                if (args[index] ~= type(results[index])) then
                    raise = true;
                    break;
                end
                index = index + 1;
            end
            if (raise) then
                error('returned value type('..type(results[index])..') did not equal expected type ('..args[index]..')');
            end
            return self;
        end
    end
end

---The expected result did not throw an error when it should have
function Expect:toThrow()
    if (self.errored ~= true) then
        error("Did not throw an error when such was expected");
    else
        return self
    end
end

---The expected result threw an error would it should not
function Expect:toNotThrow()
    if (self.errored == true) then
        error("Threw an error when such was not expected: " .. tostring(self.error[1]));
    else
        return true;
    end
end

---Creates an Expect instance from the result of `callback()`
---@param callback any
---@param isValue boolean? If true the input is taken as a literal value instead of a callback
---@return Expect
local function expect(callback, isValue)
    local results, success;
    if (isValue ~= true and type(callback) == 'function') then
        results = table.pack(pcall(callback));
        success = results[1];
        table.remove(results, 1);
    else
        success = true;
        results = {callback}
    end

    local state;
    if (success) then
        state = {
            errored = false,
            results = results
        }
    else
        state = {
            errored = true,
            error = results
        }
    end
    return setmetatable(state, { __index = Expect });
end

return { expect = expect, Expect = Expect };