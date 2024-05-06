-- Local references to globals; done for access speed
local insert,rawset,remove,setmetatable,sort,tostring,unpack = table.insert,rawset,table.remove,setmetatable,table.sort,tostring,table.unpack;

local BUFFERABLE_GROUPABLE_METHODS = {
    sweep = true,
    map = true,
    each = true,
    filter = true,
    forEach = true,
};

local BUFFERABLE_METHODS = {
    concat = true,
    push = true,
    unshift = true,
    slice = true,
    reverse = true,
};

---Array class
---@class sreject.Array
---@field length number Read-only
local Array = {};

---Creates a new Array instance
---@constructor
---@param ... any The values to insert into the array
---@return sreject.Array
function Array.new(...)
    local instance = {
        length = 0
    };

    instance = setmetatable(instance, {
        __index = Array,
        __newindex = function (self, index, value)
            if (index == 'length') then
                error('length cannot be altered');

            elseif (type(index) == 'number') then
                if (index > instance.length) then
                    rawset(instance, 'length', index);
                end
                rawset(instance, index, value);

            else
                rawset(instance, index, value)
            end
        end,
        __len = function(self)
            return instance.length;
        end
    });

    local args = {...};
    if (#args) then
        for ignored,value in next, args, nil do
            insert(instance, value);
        end
    end

    rawset(instance, 'length', #args);
    return instance;
end

---Creates a new array containing indexed items from the specified arrays
---@param ... sreject.Array|{[number]: any} The arrays to concatinate
---@return sreject.Array
function Array.concat(...)
    local instance = Array.new();
    local arrays = {...};
    local itemCount = 0;
    for ignore,array in next, arrays, nil do
        for index=1,#array,1 do
            itemCount = itemCount + 1;
            rawset(instance, itemCount, array[index]);
        end
    end
    rawset(instance, 'length', itemCount);
    return instance;
end

---Returns true if all elements result in the callback returning true
---@param callback fun(value: any, index: number, array: sreject.Array): boolean
---@param atLeastOne boolean? If specified, at least one element must result in the callback returning true
---@return boolean
function Array:all(callback, atLeastOne)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');

    else
        local matched = true;
        if (atLeastOne == true) then
            matched = false;
        end
        for index=1,#self,1 do
            if (not callback(self[index], index, self)) then
                return false
            end
            matched = true;
        end
        return matched;
    end
end
Array.every = Array.all;

---Returns true if atleast one item in the array results in the callback returning true
---@param callback fun(value: any, index: number, array: sreject.Array): boolean
---@param allowEmpty boolean? Returns true if the array is empty
---@return boolean
function Array:any(callback, allowEmpty)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    elseif (#self == 0 and allowEmpty == true) then
        return true;
    else
        for index=1,#self,1 do
            if (callback(self[index], index, self)) then
                return true;
            end
        end
        return false;
    end
end
Array.some = Array.any;

---Calls the callback for each item in the array.
---@param callback fun(value: any, index: number, array: sreject.Array): nil
---@return sreject.Array # The current array instance
function Array:each(callback)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        for index=1,#self,1 do
            callback(self[index], index, self);
        end
        return self;
    end
end
Array.forEach = Array.each;

---Returns a new array containing only items that resulted in the callback returning true
---@param callback fun(value: any, index: number, array: sreject.Array):boolean
---@return sreject.Array # A new array instance
function Array:filter(callback)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        local instance = Array.new();
        local itemCount = 0;

        for index=1,#self,1 do
            if (callback(self[index], index, self)) then
                itemCount = itemCount + 1;
                rawset(instance, itemCount, self[index]);
            end
        end

        rawset(instance, 'length', itemCount);
        return instance;
    end
end

---Finds the first element that results in the callback returning true and
---returns the index of that element. If an element cannot be found `nil` is
---returned
---
---@param callback fun(value: any, index: number, array: sreject.Array): boolean
---@return number|nil Index The index found; if no index is found `nil` is returned
function Array:find(callback)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        for index=1,#self,1 do
            if (callback(self[index], index, self)) then
                return index;
            end
        end
    end
end

---Finds the last element that results in the callback returning true and
---returns the index of that element. If an element cannot be found `nil` is
---returned
---
---@param callback fun(value: any, index: number, array: sreject.Array): boolean
---@return number|nil Index The index found; if no index is found `nil` is returned
function Array:findLast(callback)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        for index=#self,1,-1 do
            if (callback(self[index], index, self)) then
                return index;
            end
        end
    end
end

---Inserts items at the given position
---@param start number? if start is nil the start of the array is assumed, if start is less than one start it is assumed to count backwards from the end of the array
---@param ... any The values to insert
---@return sreject.Array # The current array instance
function Array:insert(start, ...)
    local values = {...};
    if (#values < 1) then
        return self;
    end

    if (start == nil) then
        start = 1;
    elseif (start < 1) then
        start = #self + 1 + start;
        if (start < 1) then
            start = 1;
        end
    end

    local len = #self;

    for idx=0,(#values -1),1 do
        insert(self, start + idx, values[idx + 1]);
    end

    rawset(self, 'length', len + #values);
    return self;
end

---Joins items in the array into a singular string
---@param delimiter string The delimiter to place between items
---@param callback (fun(value: any, index: number, array: sreject.Array): string)? Function to handle stringification of values
---@return string
function Array:join(delimiter, callback)
    if (type(delimiter) ~= 'string') then
        error('delimiter must be a string');
    else
        local toStr;
        if (callback) then
            toStr = function (value, index, array)
                local result = callback(value, index, array);
                if (result == nil) then
                    result = '';
                elseif (type(result) ~= 'string') then
                    result = tostring(result);
                end
                return result;
            end;
        else
            toStr = function (value)
                if (value == nil) then
                    return '';
                end
                return tostring(value);
            end
        end

        local result = '';
        local len = #self;
        for index=1,len,1 do
            result = result .. toStr(self[index], index, self);
            if (index < len) then
                result = result .. delimiter;
            end
        end
        return result;
    end
end

---Creates a new array containing values returned by calling the callback on each element of the array
---@param callback fun(value: any, index: number, array: sreject.Array): any
---@return sreject.Array
function Array:map(callback)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        local instance = Array.new();
        for index=1,#self,1 do
            local value = callback(self[index], index, self);
            rawset(instance, index, value);
        end

        rawset(instance, 'length', #self);
        return instance;
    end
end

---Removes the last item from from the array and returns it
---@return any
function Array:pop()
    local len = #self;
    if (len > 0) then
        local result = remove(self, len);
        rawset(self, 'length', len - 1);
        return result;
    end
end

---Adds the value(s) to the end of the array
---@param ... any The value(s) to add
---@return sreject.Array # The current array instance
function Array:push(...)
    local values = {...};
    local len = #values;
    local index = 1;
    local itemCount = #self;
    repeat
        itemCount = itemCount + 1;
        rawset(self, itemCount, values[index]);
        index = index + 1;
    until (index > len);

    rawset(self, 'length', itemCount);
    return self;
end

---Reduces the array by calling the callback with the previous call's result
---and the current element
---
---@param callback fun(result: any, currentValue: any, index: number, self: any): any
---@param initialValue any The starting value
---@return any
function Array:reduce(callback, initialValue)
    if (type(callback) ~= 'function') then
        error('callback parameter must be a function');
    else
        local result = initialValue;
        for index=1,#self,1 do
            result = callback(result, self[index], index, self);
        end
        return result;
    end
end

---Removes one or more items starting at the given position
---@param start number? The starting position; If nil starting position is assumed start of the array. If less than 1 starting position is assumed to be from end of array
---@param amount number? The amount of items to delete; if nil or less than 1 all items from `start` onward(inclusive) are removed
---@return sreject.Array # An array of items there were deleted
function Array:remove(start, amount)
    if (start == nil) then
        start = 1;
    elseif (start < 1) then
        start = #self + 1 + start;
        if (start < 1) then
            start = 1;
        end
    end

    if (start > #self) then
        return Array.new();
    end

    local remaining = #self - start + 1;
    if (amount == nil or amount < 1) then
        amount = remaining;
    elseif (amount > remaining) then
        amount = remaining;
    end

    if (amount < 1) then
        return Array.new();
    end

    local instance = Array.new();
    local itemCount = #self;
    while (amount > 0 and itemCount > 0) do
        local index = start + amount - 1;
        instance:unshift(self[index]);
        remove(self, index);
        rawset(self, 'length', #self - 1);
        amount = amount - 1;
        itemCount = itemCount - 1;
    end
    return instance;
end
Array.delete = Array.remove;

---Creates a new array containing the current array's items in reverse order
---@return sreject.Array
function Array:reverse()
    local instance = Array.new();
    local itemCount = 0;
    for index=#self, 1, -1 do
        itemCount = itemCount + 1;
        rawset(instance, itemCount, self[index]);
    end
    rawset(instance, 'length', #self);
    return instance;
end

---Removes the first item of the array and returns it
---@return any
function Array:shift()
    if (#self) then
        local item = remove(self, 1);
        rawset(self, 'length', #self - 1);
        return item;
    end
end

---Returns a new array containing a subsection of values from the current array instance
---@param start number? The starting position; values less than zero are assumed to mean from the end of the array
---@param stop number? The stopping position (exclusive); values less than zero are assumed to mean from the end of the array.
---@return sreject.Array # A new Array instance
function Array:slice(start, stop)
    local len = #self;
    if (start == nil or start == 0) then
        start = 1;

    elseif (start < 1) then
        start = len + 1 + start;
        if (start < 1) then
            start = 1;
        end
    elseif (start > len) then
        return Array.new();
    end

    if (stop == nil or stop == 0) then
        stop = len + 1;
    elseif (stop < 1) then
        stop = len + 1 + stop;
    elseif (stop > len + 1) then
        stop = len + 1;
    end

    if (stop <= start) then
        return Array.new();
    end

    local instance = Array.new();
    local itemCount = 0;
    while (start < stop) do
        itemCount = itemCount + 1;
        rawset(instance, itemCount, self[start]);
        start = start + 1;
    end
    rawset(instance, 'length', itemCount);
    return instance;
end

---Returns a new array sorted based on the result of callback
---@param callback (fun(aValue: any, bValue: any):boolean)? Returning true indicates aValve comes before bValve
---@return sreject.Array # A new Array instance
function Array:sort(callback, sortSelf)
    local instance;
    if (sortSelf == true) then
        instance = self;
    else
        instance = self:slice();
    end
    sort(instance, callback)
    return instance;
end

---Altars the array by deleting then inserting values
---@param start number? The starting position; values less than 1 are assumed to mean from the end of the array
---@param delete number? The number of items to delete at the specified start position
---@param ... any? The items to insert at the starting position once deletions have been done
---@return sreject.Array # The current array instance
function Array:splice(start, delete, ...)
    if (delete ~= nil and delete ~= 0) then
        self:remove(start, delete);
    end
    self:insert(start, ...);
    return self;
end

---Creates a new array containing the non-nil values of the current array
---@return sreject.Array
function Array:sweep()
    local instance = Array.new();
    if (#self == 0) then
        return instance;
    end

    local itemCount = 0;
    for index=0,#self,1 do
        local value = self[index];
        if (value ~= nil) then
            itemCount = itemCount + 1;
            rawset(instance, itemCount, value);
        end
    end
    rawset(instance, 'length', itemCount);
    return instance;
end

---Adds the specified value(s) to the start of the array
---@param ... any
---@return sreject.Array # The current Array instance
function Array:unshift(...)
    local values = {...};
    local len = #values;
    local itemCount = #self;

    local index = 1;
    repeat
        insert(self, index, values[index]);
        index = index + 1;
        itemCount = itemCount + 1;
    until (index > len);

    rawset(self, 'length', itemCount);
    return self;
end

---Represents a pending Array Method Buffer
---@class sreject.ArrayMethodBuffer : sreject.Array
---@field begin nil
---@field exec fun():any Executes buffered methods

---Returns an Array-like object that buffers methods until `:exec()` is called.
---
---The following methods, will called, will be buffered:
---`:concat` `:each`, `:filter`, `:forEach`, `:map`, `:push`, `:reverse`,
---`:slice`, `:sweep`, `:unshift`
---
---All other Array.* methods will result in the buffer being executed, the
---method being called against the result, and the returned value from the
---method being returned to the caller
---@return sreject.ArrayMethodBuffer
function Array:buffer()
    local subject = self;
    local tasks = {};
    local taskGroup = nil;
    local instance = {};
    return setmetatable(instance, {
        __index = function (_, key)
            if (key == 'exec') then
                if (taskGroup ~= nil) then
                    tasks.insert(taskGroup);
                    taskGroup = nil;
                end
                setmetatable(instance, { __index = function ()
                    error('method-buffer already executed');
                end});
                local result = subject;
                for _, task in next, tasks, nil do
                    if (task.type == 'group') then
                        local newResult = Array.new();
                        for index, value in next, result, nil do
                            local skipAdd = false
                            for _, method in next, task.actions do
                                local methodName = method.method;
                                if (methodName == 'sweep') then
                                    if (value == nil) then
                                        skipAdd = true;
                                        break;
                                    end
                                elseif (methodName == 'filter') then
                                    local filtered = method.params[1](value, index, subject);
                                    if (not filtered) then
                                        skipAdd = true;
                                        break;
                                    end
                                elseif (methodName == 'map') then
                                    value = method.params[1](value, index, subject);
                                elseif (methodName == 'each' or methodName == 'forEach') then
                                    method.params[1](value, index, subject);
                                else
                                    error('unknown method in iteration group: ' .. methodName);
                                end
                            end
                            if (skipAdd == false) then
                                insert(newResult, value);
                            end
                        end
                        result = newResult;
                    else
                        result = Array[task.method](result, unpack(task.params));
                    end
                end
                tasks = nil;
                ---@diagnostic disable-next-line cast-local-type
                subject = nil;
                return result;
            elseif (key == 'buffer') then
                return nil;
            elseif (BUFFERABLE_GROUPABLE_METHODS[key] ~= nil) then
                if (taskGroup == nil) then
                    taskGroup = { type = "group", tasks = {}};
                end
                return function(...)
                    insert(taskGroup.tasks, { type = "method", method = key, params = {...} });
                end
            elseif (BUFFERABLE_METHODS[key] ~= nil) then
                return function(...)
                    if (taskGroup ~= nil) then
                        tasks.insert(taskGroup);
                        taskGroup = nil;
                    end
                    insert(tasks, { type = "method", method = key, params = {...} })
                end
            elseif ( Array[key] ~= nil) then
                return function(...)
                    if (taskGroup ~= nil) then
                        tasks.insert(taskGroup);
                        taskGroup = nil;
                    end
                    insert(tasks, { type = "method", method = key, params = {...}});
                    instance.exec();
                end
            else
                return nil;
            end
        end
    }) --[[@as sreject.ArrayMethodBuffer]];
end

return { Array = Array };