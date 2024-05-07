package.path = package.path .. ";/?.lua;/?/init.lua"

local BetterErrors = require('better-errors');
local Error = BetterErrors.new;
local error = BetterErrors.throw;


-- Default reporter
local defaultReporter = function()
    local indent = -1;
    return function (eventname, details)
        if (eventname == nil) then
            -- ignore
        elseif (eventname == 'INIT') then
            -- ignored
        elseif (eventname == 'OPENED') then
            -- ignored
        elseif (eventname == 'NEW_TEST_GROUP_OPEN') then
            -- ignored
        elseif (eventname == 'NEW_TEST_GROUP_CLOSED') then
            -- ignored
        elseif (eventname == 'NEW_UNIT_TEST') then
            -- ignored
        elseif (eventname == 'CLOSED') then
            -- ignored
        elseif (eventname == 'TESTING_START') then
            -- ignored
        elseif (eventname == 'TEST_GROUP_START') then
            indent = indent + 1;
            print(string.format('%s%s', string.rep('  ', indent), details.title));
        elseif (eventname == 'TEST_GROUP_END') then
            indent = indent - 1;
        elseif (eventname == 'TEST_GROUP_SKIPPED') then
            -- ignored
        elseif (eventname == 'UNIT_TEST_START') then
            -- ignored
        elseif (eventname == 'UNIT_TEST_END') then
            if (details.success == true) then
                print(string.format('%s [ok] %s', string.rep('  ', indent), details.title));
            else
                print(string.format('%s [error] %s', string.rep('  ', indent), details.title));
                print(string.format('%s  %s', string.rep('  ', indent), details.result[1]));
            end
        elseif (eventname == 'UNIT_TEST_SKIPPED') then
            -- ignored
        elseif (eventname == 'TESTING_END') then
            -- ignored
        elseif (eventname == 'ERROR') then
            -- ignored
        else
            print(eventname);
        end
    end
end

-- consts
local eventname = {
    INIT = 'INIT',
    OPENED = 'OPENED',
    CLOSED = 'CLOSED',
    NEW_TEST_GROUP_OPEN = 'NEW_TEST_GROUP_OPEN',
    NEW_TEST_GROUP_CLOSED = 'NEW_TEST_GROUP_CLOSED',
    TEST_GROUP_START = 'TEST_GROUP_START',
    TEST_GROUP_END = 'TEST_GROUP_END',
    TEST_GROUP_SKIPPED = 'SKIPPED_TEST_GROUP',
    NEW_UNIT_TEST = 'NEW_UNIT_TEST',
    UNIT_TEST_START = 'UNIT_TEST_START',
    UNIT_TEST_END = 'UNIT_TEST_END',
    UNIT_TEST_SKIPPED = 'UNIT_TEST_SKIPPED',
    TESTING_START = 'TESTING_START',
    TESTING_END = 'TESTING_END',
    ERROR = 'ERROR',
};

local errortypes = {
    INVALID_CALLBACK = 'INVALID_CALLBACK',
    NOT_A_GROUP = 'NOT_A_GROUP',
    TEST_NOT_FOUND = 'TEST_NOT_FOUND'
};

local function lut(reportHandler)

    ---@class sreject.lut.state
    local state = {
        parent = nil;
        type = 'group',
        title = '',
        children = {}
    }
    state.id = tostring(state);

    local suiteid = state.id;

    local reporter;
    if (reportHandler) then
        reporter = reportHandler;
    else
        reporter = defaultReporter();
    end

    reporter(eventname.INIT, { suiteid = suiteid, id = suiteid });

    reporter(eventname.OPENED, { suiteid = suiteid, id = suiteid });

    local function describe(title, callback)

        title = title or ('Index: ' .. (#state.children + 1));

        local group = {
            type = 'group',
            parent = state,
            title = title,
            children = {}
        };
        group.id = tostring(group);
        table.insert(state.children, group);

        reporter(eventname.NEW_TEST_GROUP_OPEN, { suiteid = suiteid, parentid = state.id, id = group.id, index = #state.children, title = title });

        if (callback == nil) then
            callback = function () end;
            group.callback = callback;

        elseif (type(callback) == 'function') then
            group.callback = callback;

        else
            reporter(eventname.ERROR, { suiteid = suiteid, type = errortypes.INVALID_CALLBACK, message = "specified callback is invalid", id = group.id, value = callback });
            error(Error('INVALID_CALLBACK', { message = 'invalid describe() callback parameter specified' }), 2);
        end

        state = group;
        callback();
        state = group.parent;

        reporter(eventname.NEW_TEST_GROUP_CLOSED, { suiteid = suiteid, parentid = state.id, id = group.id });
    end;

    local function it(title, callback)

        title = title or ('Index: ' .. (#state.children + 1));

        local test = {
            type = 'test',
            parent = state.id,
            title = title,
            callback = callback
        };
        test.id = tostring(test);
        table.insert(state.children, test);

        reporter(eventname.NEW_UNIT_TEST, { suiteid = suiteid, parentid = state.id, id = test.id, index = #state.children, title = title });

        if (callback == nil) then
            callback = function () end;
            test.callback = callback;

        elseif (type(callback) == 'function') then
            test.callback = callback;

        elseif (type(callback) ~= 'function') then
            reporter(eventname.ERROR, { suiteid = suiteid, type = errortypes.INVALID_CALLBACK, message = "specified it() callback is invalid", id = test.id, value = callback });

            error(Error('INVALID_CALLBACK', { message = 'invalid it() callback parameter specified'}), 2);
        end
    end;

    local function test(...)

        reporter(eventname.CLOSED, { suiteid = suiteid, id = suiteid });

        -- reset state to root element
        while (state.parent ~= nil) do
            state = state.parent --[[@as sreject.lut.state ]]
        end

        reporter(eventname.TESTING_START, { suiteid = suiteid, id = suiteid });

        -- walk nested children until we arrive at the test-group indicated by parameters
        local walk = {...};
        local startIndex = 0;
        for idx=1, #walk, 1 do

            if (state.type ~= 'group') then
                reporter(eventname.ERROR, { suiteid = suiteid, type = errortypes.NOT_A_GROUP, message = "attempted referencing members within a non group", id = state.id });
                error(Error('NOT_A_GROUP', { message = 'Attempted to reference non-existant group'}), 2);
            end

            local group = state.children;
            local index = walk[idx];

            -- Find matching string
            if (type(index) == 'string') then
                for i,v in ipairs(state.children) do
                    if (v.title == index) then
                        index = i;
                        break;
                    end
                end
                if (type(index) == 'string') then
                    reporter(eventname.ERROR, { suiteid = suiteid, type = errortypes.TEST_NOT_FOUND, message = "no test found", id = state.id, searchtype = 'title', index = index });
                    error(Error('TEST_NOT_FOUND', { message = 'no test found at indicated walk index'}), 2);
                end
            else
                index = idx;
            end

            -- Invalid index
            if (state.children[index] == nil) then
                reporter(eventname.ERROR, { suiteid = suiteid, type = errortypes.TEST_NOT_FOUND, message = "no test found", id = state.id, searchtype = 'index', index = index });
                error(Error('TEXT_NOT_FOUND', { message = 'not test found at indicated walk index'}), 2);
            end

            -- report skipped groups/tests that occur before the targeted test(s)
            for skipIndex=1,#state.children - 1,1 do
                local child = group[skipIndex];
                if (child.type == 'group') then
                    reporter(eventname.TEST_GROUP_SKIPPED, { suiteid = suiteid, id = child.id, title = child.title });
                else
                    reporter(eventname.UNIT_TEST_SKIPPED, { suiteid = suiteid, id = child.id, title = child.title });
                end
            end

            startIndex = index;
            state = state.children[index];
        end

        if (state.type == 'group') then

            if (state.parent ~= nil) then
                reporter(eventname.TEST_GROUP_START, { suiteid = suiteid, id = state.id, title = state.title });
            end

            local function testChildren(children)
                for i,child in next,children,nil do
                    if (child.type == 'group') then
                        reporter(eventname.TEST_GROUP_START, { suiteid = suiteid, id = child.id, title = child.title });
                        testChildren(child.children);
                        reporter(eventname.TEST_GROUP_END, { suiteid = suiteid, id = child.id });
                    else
                        reporter(eventname.UNIT_TEST_START, { suiteid = suiteid, id = child.id, title = child.title });
                        local result = table.pack(pcall(child.callback));
                        local success = table.remove(result, 1);
                        if (success == true) then
                            reporter(eventname.UNIT_TEST_END, { suiteid = suiteid, id = child.id, success = true, result = result, title = child.title });
                        else
                            reporter(eventname.UNIT_TEST_END, { suiteid = suiteid, id = child.id, success = false, result = result, title = child.title });
                        end
                    end
                end
            end
            testChildren(state.children);
            if (state.parent ~= nil) then
                reporter(eventname.TEST_GROUP_END, { suiteid = suiteid, id = state.id });
            end

        else
            reporter(eventname.UNIT_TEST_START, { suiteid = suiteid, id = state.id, title = state.title });
            local result = table.pack(pcall(state.callback));
            local success = table.remove(result, 1);
            print('test state: ', success);
            if (success == true) then
                reporter(eventname.UNIT_TEST_END, { suiteid = suiteid, id = state.id, success = true, result = result, title = state.title });
            else
                reporter(eventname.UNIT_TEST_END, { suiteid = suiteid, id = state.id, success = false, result = result, title = state.title });
            end
        end

        if (startIndex > 0) then
            -- report skipped groups/tests that occur after the targeted test(s)
            while (true) do
                if (startIndex < #state.children) then
                    for idx=startIndex+1,#state.children,1 do
                        local child = state.children[idx];
                        if (child.type == 'group') then
                            reporter(eventname.TEST_GROUP_SKIPPED, { suiteid = suiteid, id = child.id, title = child.title });
                        else
                            reporter(eventname.UNIT_TEST_SKIPPED, { suiteid = suiteid, id = child.id, title = child.title });
                        end
                    end
                end
                startIndex = 0;
                if (state.parent == nil) then
                    break;
                end
                state = state.parent
            end
        end

        reporter(eventname.TESTING_END, { suiteid = suiteid });
    end

    return describe, it, test;
end

return { lut = lut };