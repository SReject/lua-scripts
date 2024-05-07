local exports = {};

local BetterError = {};
exports.Error = BetterError;

function BetterError.new(errtype, data)
    if (type(errtype) ~= 'string' or errtype == '') then
        BetterError.throw(BetterError.new('INVALID_ERROR_TYPE', 2));
    end

    local instance = setmetatable({ type = errtype }, {
        __index = BetterError,
        __tostring = function(self)
            if (getmetatable(self).__index ~= BetterError) then
                BetterError.throw(BetterError.new('INVALID_ERROR_TYPE', 2));
            end

            local result = self.type;
            if (self.message) then
                result = result .. ': ' .. self.message
            end
            for i,stack in next, self.stacktrace, nil do
                result = result .. string.format('\n  at %s (%s:%s:%s)',
                    stack.name,
                    stack.source,
                    stack.line,
                    stack.column
                );
            end
            return result;
        end
    });
    if (type(data) == 'table') then
        for i,k in next, data, nil do
            if (i ~= 'type' and i ~= 'stack') then
                instance[i] = k;
            end
        end
    end
    return instance;
end

function BetterError.wrap(errtype, data)
    if (type(errtype) ~= 'string' or errtype == '') then
        BetterError.throw(BetterError.new('INVALID_ERROR_TYPE', 2));
    end
    return function(message)
        if (message ~= nil and type(message) ~= 'string') then
            BetterError.throw(BetterError.new('INVALID_MESSAGE_TYPE', 2));
        end
        local err = BetterError.new(errtype, data);
        err.message = message or '';
    end
end

function exports.throw(err, level)
    if (type(err) == 'string') then
        -- TODO: Attempt to exact file:line:column info from error
        err = BetterError.new('Error', { message = err });
    end

    if (getmetatable(err).__index == BetterError) then

        -- determine where to start the stack trace at
        if (type(level) ~= 'number' or level < 1) then
            level = 2;
        else
            level = 2 + math.floor(level);
        end

        -- build stack trace
        local stack = {};
        local id = level
        local dinfo = debug.getinfo(id);

        repeat
            ---@diagnostic disable-next-line undefined-field
            local stName, stSource, stLine, stColumn = dinfo.name, dinfo.source, dinfo.currentline, dinfo.currentcolumn;

            if (stName == nil) then
                stName = "(anonymous)"
            end

            if (type(stSource) == 'string') then
                if (stSource:sub(1,1) == '@') then
                    stSource = stSource:sub(2);
                end
                if (stSource == '') then
                    stSource = '(unknown)';
                end
            else
                stSource = '(unknown)'
            end

            if (stLine == nil) then
                stLine = -1;
            end

            if (stColumn == nil) then
                stColumn = -1;
            end

            local entry = {
                source = stSource,
                line = stLine,
                column = stColumn,
                name = stName
            }

            table.insert(stack, entry);

            id = id + 1;
            dinfo = debug.getinfo(id);
            if (dinfo == nil) then
                entry.name = '(root)'
            end
        until (dinfo == nil)
        err.stacktrace = stack;
    end

    -- raise error
    error(err, level);
end

return exports;