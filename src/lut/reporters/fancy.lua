local BetterErrors = require('better-errors');
local error = BetterErrors.throw;
local Error = BetterErrors.new;

local suites = {};

-- event handlers
local eh = {};

function eh.INIT(event)
    local suiteid = event.suiteid;
    if (suites[suiteid] == nil) then
        suites[suiteid] = {
            type = 'root',
            id = suiteid,
            parent = nil,
            children = {},
            idmap = {},
            state = 0, -- 0 = initializing, 1 = accepting tests, 2 = adding tests done, 3 = testing
            depth = 0,
            tests = { total = 0, ran = 0, passed = 0, failed = 0, skipped = 0 },
            skipped = false
        };
        suites[suiteid].idmap[suiteid] = suites[suiteid];
    else
        error(Error('INVALID_ENTRY', { id = suiteid, message = string.format('A test suite with id `%s` already exists', suiteid) }))
    end
end

function eh.OPENED(event)
    local suite = suites[event.suiteid];
    if (suite.state == 0) then
        suite.state = 1;
    else
        error(Error('INVALID_STATE', { message = 'The test suit is not in a state to begin accepting test entries' }));
    end
end

function eh.NEW_TEST_GROUP_OPEN(event)
    local suite = suites[event.suiteid];

    if (suite.idmap[event.id] ~= nil) then
        error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has already been registered', event.id) }));
    elseif (suite.state == 1) then
        local parent = suite.idmap[event.parentid];
        if (parent == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('An entry parent was not found with an id of `%s`', event.id) }));
        elseif (parent.type == 'root' or parent.type == 'group') then
            local group = {
                type = 'group',
                parent = parent,
                id = event.id,
                children = {},
                title = event.title,
                index = event.index,
                depth = parent.depth + 1,
                tests = { total = 0, ran = 0, passed = 0, failed = 0 },
                state = 0
            };
            table.insert(parent.children, group);
            suite.idmap[event.id] = group;
        else
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('Entry parent with an id of `%s` is not a group', event.id) }));
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state to accept test entries' }));
    end
end

function eh.NEW_TEST_GROUP_CLOSED(event)
    local suite = suites[event.suiteid];
    if (suite.state == 1) then
        local group = suite.idmap[event.id];
        if (group == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has not been registered', event.id) }));
        elseif (group.type ~= 'root' and group.type ~= 'group') then
            error(Error('INVALID_ENTRY', { id = event.id, message = 'Entry is not a group' }));
        elseif (group.state == 0) then
            group.state = 1;
        else
            error(Error('INVALID_STATE', { message = 'Entry with an id of `' .. tostring(group.id)..'` is not open' }));
        end
    else
        error(Error('INVALID_STATE', { message = 'Test suite is not in a state to accept test entries' }));
    end
end

function eh.NEW_UNIT_TEST(event)
    local suite = suites[event.suiteid];
    if (suite.idmap[event.id] ~= nil) then
        error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has already been registered', event.id) }));
    elseif (suite.state == 1) then
        local parent = suite.idmap[event.parentid];
        if (parent == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('An entry parent was not found with an id of `%s`', event.id) }));
        elseif (parent.type == 'root' or parent.type == 'group') then
            local test = {
                type = 'test',
                parent = parent,
                id = event.id,
                index = event.index,
                title = event.title,
                depth = parent.depth + 1,
                state = 0,
                skipped = false,
                result = {}
            };
            table.insert(parent.children, test);
            suite.idmap[event.id] = test;
            local p = parent;
            repeat
                p.tests.total = p.tests.total + 1;
                p = p.parent;
            until (p == nil);
        else
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('Entry parent with an id of `%s` is not a group', event.id) }));
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state to accept test entries' }));
    end
end

function eh.CLOSED(event)
    local suite = suites[event.suiteid];
    if (suite.state == 1) then
        suite.state = 2;
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state to accept test entries' }));
    end
end

function eh.TESTING_START(event)
    local suite = suites[event.suiteid];
    if (suite.state == 2) then
        suite.state = 3;
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state to begin testing' }));
    end
end

function eh.TEST_GROUP_START(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        -- TODO: Report start of test group
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.TEST_GROUP_END(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        -- TODO: Report result of test group
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.TEST_GROUP_SKIPPED(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        local group = suite.idmap[event.id];
        if (group == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has not been registered', event.id) }));
        else

            -- update parent chain
            local p = group.parent
            while (p ~= nil) do
                p.tests.skipped = p.tests.skipped + group.tests.total
                p = p.parent;
            end

            -- update self
            group.tests.skipped = group.tests.total
            group.skipped = true;

            -- Update children chains
            local childrenToUpdate = { table.unpack(group.children) }
            while (childrenToUpdate[1] ~= nil) do
                local child = table.remove(childrenToUpdate, 1);
                child.skipped = true;
                if (child.type == 'group') then
                    child.tests.skipped = child.tests.total
                    for i,grandchild in ipairs(child.children) do
                        table.insert(childrenToUpdate, grandchild);
                    end
                end
            end
            -- TODO: Report skip
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.UNIT_TEST_START(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        local test = suite.idmap[event.id];
        if (test == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has not been registered', event.id) }));

        elseif (test.state == 0) then
            test.state = 1;
            -- TODO: report test start
        else
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('The test entry with id `%s` is not in a state to be tested', event.id) }));
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.UNIT_TEST_END(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        local test = suite.idmap[event.id];
        if (test == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has not been registered', event.id) }));

        elseif (test.state == 1) then
            test.state = 2;
            test.success = event.success;
            local result = test.result

            if (event.success == true) then
                -- TODO: report test passed

            elseif (#result > 1) then
                -- Multivalue error - This shouldn't be possible
                -- but just in case this block is here to handle it
                -- in the future
            else

                local err = result[1];
                if (type(err) == 'string') then
                    err = BetterErrors.extract(err);
                    test.result = { err }
                end

                if (BetterErrors.isError(err)) then
                    -- TODO: Report BetterError error
                else
                    -- TODO: Report Error
                end
            end

            -- TODO: report test finished
        else
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('The test entry with id `%s` has not started testing', event.id) }));
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.UNIT_TEST_SKIPPED(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then
        local test = suite.idmap[event.id];
        if (test == nil) then
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('A test entry with id `%s` has not been registered', event.id) }));
        elseif (test.state == 0) then
            local p = test.parent
            while (p ~= nil) do
                p.tests.skipped = p.tests.skipped + 1;
                p = p.parent;
            end
            test.skipped = true;
            test.state = 2;

            -- TODO Report test skipped
        else
            error(Error('INVALID_ENTRY', { id = event.id, message = string.format('The test entry with id `%s` is not in a state to be tested', event.id) }));
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.TESTING_END(event)
    local suite = suites[event.suiteid];
    if (suite.state == 3) then

        -- TODO: close out report

        -- reset test results
        for i,entry in next, suite.idmap do
            entry.skipped = false;
            if (entry.type == 'group') then
                entry.tests.ran = 0;
                entry.tests.passed = 0;
                entry.tests.failed = 0;
                entry.tests.skipped = 0;
                entry.state = 0;
            elseif (entry.type == 'test') then
                entry.state = 0;
                entry.result = {};
            end
            suite.state = 2;
        end
    else
        error(Error('INVALID_STATE', { message = 'The test suite is not in a state of testing' }));
    end
end

function eh.ERROR(event)

end

function eh.UNKNOWN_EVENT(name, event)

end

local exports = {};
function exports.reporter(event, details)
    if (event == nil) then
        -- error
    elseif (details == nil) then
        --error
    elseif (details.suiteid == nil) then
        -- error
    elseif (event ~= 'INIT' and suites[details.suiteid] == nil) then
        -- error
    elseif (details.id == nil) then
        -- error
    elseif (eh[event] == nil) then
        eh.UNKNOWN_EVENT(event, details);
    else
        eh[event](details);
    end
end
return exports;