local term, colors = term,colors;

local function write(text, color)
    local current = table.pack(term.getTextColor());
    if (color ~= nil) then
        term.setTextColor(colors[color]);
    end
    term.write(text);
    term.setTextColor(table.unpack(current));
end

local function writeTitleBlock(indent, title, pass, fail, count)
    term.clearLine();
    term.write((' '):rep(indent * 2));
    if (pass == '?') then
        write('[', 'gray');
        write(tostring(pass), 'yellow');
        write(',', 'gray');
        write(tostring(tostring(fail)), 'yellow');
        write('/', 'gray');
        write(tostring(count), 'yellow');
        write(']', 'gray');
    else
        write('[', 'gray');
        write(tostring(pass), 'lime');
        write(',', 'gray');
        write(tostring(tostring(fail)), 'red');
        write('/', 'gray');
        write(tostring(count));
        write(']', 'gray');
    end
    write(string.format(' %s', title));
    local ignore,line = term.getCursorPos();
    term.setCursorPos(1, line + 1);
end

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

return function()
    term.clear();
    term.setCursorPos(1,1);
    local indent = -1;
    local testGroup = {
        parent = nil,
        children = {};
        count = 0,
        pass = 0,
        fail = 0,
        messages = {},
        cursor = {1,1}
    };

    ---Produces a new testing group
    ---@param title string The testing group's title
    ---@param callback fun():nil The testing group's body
    local function describe(title, callback)
        local groupStart = testGroup.cursor[2];

        local messageGroup = {
            parent = testGroup,
            children = {},
            count = 0,
            pass = 0,
            fail = 0,
            messages = {},
            cursor = {1, groupStart + 1}
        };
        table.insert(testGroup.children, messageGroup);
        testGroup = messageGroup;
        indent = indent + 1;

        writeTitleBlock(indent, title, '?');


        callback();


        -- Update group header
        term.setCursorPos(1, groupStart);
        writeTitleBlock(indent, title, messageGroup.pass, messageGroup.fail, messageGroup.count);
        if (messageGroup.fail > 0) then
            for index,result in ipairs(messageGroup.messages) do
                if (result.state == 1) then
                    write((' '):rep((indent + 1) * 2));
                    write('o', 'green');
                    write((' %s'):format(result.title), 'lightGray');
                else
                    write((' '):rep((indent + 1) * 2));
                    write('x', 'red');
                    write((' %s'):format(result.title));
                    -- TODO: write out error message
                    local ignore,line = term.getCursorPos();
                    term.setCursorPos((indent + 2) * 2 + 3, line + 1);
                    write(result.error, 'red');
                end
                local ignore,line = term.getCursorPos();
                term.setCursorPos(1, line + 1);
            end
            local ignore,line = term.getCursorPos();
            term.setCursorPos(1, line + 1);
        end

        indent = indent - 1;
        testGroup = testGroup.parent;
        testGroup.cursor = table.pack(term.getCursorPos());
    end

    -- A singular test
    ---@param title string The test's title
    ---@param callback fun():nil The callback; it should raise an error if the test failed
    local function it(title, callback)
        indent = indent + 1;
        testGroup.count = testGroup.count + 1;
        local success,result = pcall(callback);
        if (success) then
            testGroup.pass = testGroup.pass + 1;
            table.insert(testGroup.messages, {
                title = title,
                index = testGroup.count,
                state = 1
            });
        else
            testGroup.fail = testGroup.fail + 1;
            table.insert(testGroup.messages, {
                title = title,
                index = testGroup.count,
                state = 0,
                error = result
            });
        end
        indent = indent - 1;
    end

    return describe,it,expect;
end