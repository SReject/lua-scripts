local exports = {};

local BetterErrorsInstanceIndex = {};

---@class sreject.BetterErrors.stackTraceItem
---@field name string The calling function's name
---@field source string The source file
---@field line number The line of `source`
---@field column number the column in `line`

---@class sreject.BetterErrors.Error
---@field type string
---@field message string?
---@field stacktrace sreject.BetterErrors.stackTraceItem[]?
---@field [any] any

local BetterErrors = {};
exports.Error = BetterErrors;

---Creates a new BetterErrors Error instance
---@param errtype string The error type
---@param data {[any]: any}? Data to append to the error
---@return sreject.BetterErrors.Error
function exports.new(errtype, data)

    if (type(errtype) ~= 'string' or errtype == '') then
        BetterErrors.throw(BetterErrors.new('INVALID_ERROR_TYPE'), 2);
    end

    local instance = setmetatable({ type = errtype }, {
        __index = BetterErrorsInstanceIndex,
        __tostring = function(self)
            if (exports.isError(self) ~= true) then
                BetterErrors.throw(BetterErrors.new('INVALID_ERROR_TYPE'), 2);
            end
            local result = self.type;
            if (self.message) then
                result = result .. ': ' .. self.message
            end
            if (self.stacktrace) then
                for i,stack in next, self.stacktrace, nil do
                    result = result .. string.format('\n  at %s (%s:%s:%s)', stack.name, stack.source, stack.line, stack.column);
                end
            end
            return result;
        end
    });
    if (type(data) == 'table') then
        for i,k in next, data, nil do
            if (i ~= 'type' and i ~= 'stacktrace') then
                instance[i] = k;
            end
        end
    end
    return instance;
end

function exports.extract(message)
    if (message == nil or message == '') then
        return exports.new('Error');
    end

    if (type(message) ~= 'string') then
        exports.throw(exports.new('INVALID_MESSAGE', { message = 'cannot extract error information from non-strings'}), 2);
    end

    if (string.sub(message, 1,1) == '/') then

        local file,line,column,msg = string.match(message, '([\\\\/][^"*<>|?]+):(%d*):(%d*).*');

        if (file == nil or line == nil or column == nil or msg == nil) then
            return exports.new('ERROR', { message = message });
        end

        line = line == '' and -1 or tonumber(line) --[[@as number]];
        column = column == '' and -1 or tonumber(column) --[[@as number]];

        while (string.sub(message, 1, 1) == ' ') do
            msg = msg.sub(message, 2, 1);
        end

        local err = exports.new('ERROR', { message = msg });
        err.stacktrace = {
            { source = file, line = line, column = column, name = '(unknown)' };
        }
        return err;

    end
    return exports.new('Error', { message = message });
end

---Creates a wrapping function that provides defaults for a BetterErrors Error
---instance
---@param errtype string The error type
---@param defaults {[any]: any}? default values to apply to the error instance
---@return (fun(data: {[any]:any}?): sreject.BetterErrors.Error) # Function to create a new error using the given defaults
function exports.wrap(errtype, defaults)
    if (type(errtype) ~= 'string' or errtype == '') then
        BetterErrors.throw(BetterErrors.new('INVALID_ERROR_TYPE'), 2);
    end

    ---Creates a new BetterErrors Error instance
    ---@param data {[any]:any}? Data to apply to the error
    ---@return sreject.BetterErrors.Error # A new BetterErrors Error instance
    return function(data)
        local err = BetterErrors.new(errtype, defaults);
        if (type(data) == 'string') then
            err.message = data;
        elseif(type(data) == 'table') then
            for key,value in next, data, nil do
                if (key ~= 'type' and key ~= 'stacktrace') then
                    err[key] = value;
                end
            end
        end
        return err;
    end
end

---Raises an error
---@param err any The error to throw, if `err` is a string a generic BetterError Error is created and `err` is used as the message; Other non- BetterError Error instance inputs are raised as-is
---@param level number? The index to start at when compiling the stack trace(defaults to 1; indicating the beginning)
function exports.throw(err, level)

    if (type(err) == 'string') then
        err = exports.extract(err);
    end

    if (exports.isError(err)) then

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

            local entry = { source = stSource, line = stLine, column = stColumn, name = stName };
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

---Returns whether the subject is a BetterErrors Error instance
---@param subject any
---@return boolean
function exports.isError(subject)
    return type(subject) == 'table' and getmetatable(subject).__index == BetterErrorsInstanceIndex;
end

return exports;