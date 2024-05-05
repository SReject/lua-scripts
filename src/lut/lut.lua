-- Default reporter
local defaultReporter = function()
    local indent = -1;
    return function (eventname, details)
        if (eventname == nil) then
            -- ignore
        elseif (eventname == 'ERROR') then
            -- ignore
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
                print(string.format('%s  ', string.rep('  ', indent), details.result[1]));
            end
        elseif (eventname == 'UNIT_TEST_SKIPPED') then
            -- ignored
        elseif (eventname == 'TESTING_END') then
            -- ignored
        else
            print(eventname);
        end
    end
end

-- consts
local eventname = {
    ERROR = 'ERROR',
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
    TESTING_END = 'TESTING_END'
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

    local reporter;
    if (reportHandler) then
        reporter = reportHandler(state.id);
    else
        reporter = defaultReporter();
    end

    reporter(eventname.OPENED);

    local function describe(title, callback)
        local group = {
            type = 'group',
            parent = state,
            title = title,
            children = {}
        };
        group.id = tostring(group);
        table.insert(state.children, group);
        reporter(eventname.NEW_TEST_GROUP_OPEN, { parentid = state.id, id = group.id, index = #state.children, title = title });

        if (type(callback) ~= 'function') then
            if (callback ~= nil) then
                reporter(eventname.ERROR, { type = errortypes.INVALID_CALLBACK, args = { message = "specified callback is invalid", id = group.id, value = callback }});
            end
            group.callback = function () end
        end

        state = group;
        callback();
        state = group.parent;
        reporter(eventname.NEW_TEST_GROUP_CLOSED, { parentid = state.id, id = group.id });
    end;

    local function it(title, callback)
        local test = {
            type = 'test',
            parent = state.id,
            title = title,
            callback = callback
        };
        test.id = tostring(test);
        table.insert(state.children, test);
        reporter(eventname.NEW_UNIT_TEST, { parentid = state.id, id = test.id, index = #state.children, title = title });
        if (type(callback) ~= 'function') then
            if (callback ~= nil) then
                reporter(eventname.ERROR, { type = errortypes.INVALID_CALLBACK, args = { message = "specified callback is invalid", id = test.id, value = callback }});
            end
            test.callback = function () end
        end
    end;

    local function test(...)
        -- reset to root state element
        while (state.parent ~= nil) do
            state = state.parent --[[@as sreject.lut.state]];
        end

        reporter(eventname.CLOSED);
        reporter(eventname.TESTING_START);

        -- walk nested children until we arrive at the test-group indicated by parameters
        local walk = {...};

        local startIndex = 0;
        for idx=1,#walk,1 do
            if (state.type ~= 'group') then
                reporter(eventname.ERROR, { type = errortypes.NOT_A_GROUP, args = { message = "attempted referencing members within a non group", id = state.id } });
                return;
            end

            local group = state.children;
            local index = walk[idx];
            if (type(index) == 'string') then
                for i,v in ipairs(state.children) do
                    if (v.title == index) then
                        index = i;
                        break;
                    end
                end
                if (type(index) == 'string') then
                    reporter(eventname.ERROR, { type = errortypes.TEST_NOT_FOUND, args = { message = "no test found", id = state.id, type = 'title', index = index}});
                    return;
                end
            else
                index = idx;
            end
            if (state.children[index] == nil) then
                reporter(eventname.ERROR, { type = errortypes.TEST_NOT_FOUND, args = { message = "no test found", id = state.id, type = 'index', index = index }});
                return;
            end

            -- report skipped groups/tests that occur before the targeted test(s)
            for skipIndex=1,#state.children - 1,1 do
                local child = group[skipIndex];
                if (child.type == 'group') then
                    reporter(eventname.TEST_GROUP_SKIPPED, { id = child.id, title = child.title });
                else
                    reporter(eventname.UNIT_TEST_SKIPPED, { id = child.id, title = child.title });
                end
            end

            startIndex = index;
            state = state.children[index];
        end

        if (state.type == 'group') then
            if (state.parent ~= nil) then
                reporter(eventname.TEST_GROUP_START, { id = state.id, title = state.title });
            end
            local function testChildren(children)
                for i,child in next,children,nil do
                    if (child.type == 'group') then
                        reporter(eventname.TEST_GROUP_START, { id = child.id, title = child.title });
                        testChildren(child.children);
                        reporter(eventname.TEST_GROUP_END, { id = child.id });
                    else
                        reporter(eventname.UNIT_TEST_START, { id = child.id, title = child.title });

                        local result = table.pack(pcall(child.callback));
                        local success = table.remove(result, 1);
                        if (success == true) then
                            reporter(eventname.UNIT_TEST_END, { id = child.id, success = true, result = result, title = child.title });
                        else
                            reporter(eventname.UNIT_TEST_END, { id = child.id, success = false, result = result, title = child.title });
                        end
                    end
                end
            end
            testChildren(state.children);

            if (state.parent ~= nil) then
                reporter(eventname.TEST_GROUP_END, { id = state.id });
            end
        else
            reporter(eventname.UNIT_TEST_START, { id = state.id, title = state.title });
            local result = table.pack(pcall(state.callback));
            local success = table.remove(result, 1);
            if (success == true) then
                reporter(eventname.UNIT_TEST_END, { id = state.id, success = true, result = result, title = state.title });
            else
                reporter(eventname.UNIT_TEST_END, { id = state.id, success = false, result = result, title = state.title });
            end
        end

        if (startIndex > 0) then
            -- report skipped groups/tests that occur after the targeted test(s)
            while (true) do
                if (startIndex < #state.children) then
                    for idx=startIndex+1,#state.children,1 do
                        local child = state.children[idx];
                        if (child.type == 'group') then
                            reporter(eventname.TEST_GROUP_SKIPPED, { id = child.id, title = child.title });
                        else
                            reporter(eventname.UNIT_TEST_SKIPPED, { id = child.id, title = child.title });
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
        reporter(eventname.TESTING_END);
    end;

    return describe, it, test;
end

return { lut = lut };