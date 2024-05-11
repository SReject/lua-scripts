-- Local references to globals; done for access speed
local insert,rawset,remove,setmetatable,sort,tostring,unpack = table.insert,rawset,table.remove,setmetatable,table.sort,tostring,table.unpack;

---Array class
---@class sreject.Array
---@field length number Read-only
local Array = {};

---Array method-queue class
---@class sreject.ArrayMethodQueue : sreject.Array
---@field subject sreject.Array
---@field tasks sreject.Array
---@field taskGroup { task: "group", tasks: sreject.Array }
local ArrayMethodQueue = setmetatable({}, {
    ---@param self sreject.ArrayMethodQueue
    __index = function (self, key)
        if (type(self.subject[key]) == 'function') then
            return function(...)
                local res = self:exec();
                return res[key](res, ...);
            end
        else
            return nil
        end
    end
});

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

---Returns an array containing the numerically-indexed members of the subject table
---If the subject is an Array instance it is returned as-is
---@param subject table
---@return sreject.Array
function Array.from(subject)
    if (Array.isArray(subject)) then
        return subject;
    elseif (type(subject) ~= 'table') then
        error('input is not a table');
    else
        local result = Array.new();
        local index = 0;
        for i,value in next, subject, nil do
            if (type(i) == 'number') then
                index = index + 1;
                result[index] = value;
            end
        end
        return result;
    end
end

---Returns whether the subject is an Array instance
---@param subject any
---@return boolean
function Array.isArray(subject)
    while (type(subject) == 'table') do
        local mt = getmetatable(subject);
        if (mt.__index == Array) then
            return true;
        end
        if (type(mt.__index) ~= 'table') then
            return false;
        end
        subject = mt.__index;
    end
    return false;
end

---Returns true if all elements result in the callback returning true
---@param callback fun(value: any, index: number, array: sreject.Array): boolean
---@param atLeastOne boolean? If specified, at least one element must result in the callback returning true
---@return boolean
function Array:all(callback, atLeastOne)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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

---Returns a new array instance containing only one of each equivulant value from the base Array instance
---@param allowNil boolean? Allows a nil be to added to the result if such a value has not been encountered
---@return sreject.Array # A new Array instance
function Array:dedupe(allowNil)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        local noNil = true;
        local encountered = {};
        local result = Array.new();
        local insertIndex = 0;
        for index=1, #self, 1 do
            local value = self[index];
            if (value == nil) then
                if (noNil and allowNil) then
                    insertIndex = insertIndex + 1;
                    noNil = false;
                end
            elseif (encountered[value] == nil) then
                insertIndex = insertIndex + 1;
                encountered[value] = true;
                result[insertIndex] = value;
            end
        end
        rawset(result, 'length', insertIndex);
        return result;
    end
end

---Calls the callback for each item in the array.
---@param callback fun(value: any, index: number, array: sreject.Array): nil
---@return sreject.Array # The current array instance
function Array:each(callback)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end

---Returns an iterator function for the Array instance
---@return (fun(subject: sreject.Array, index?: number):number,any?), sreject.Array, number?
function Array:iterator()
    return function (subject, index)
        if (index == nil) then
            index = 1;
        else
            index = index + 1;
        end
        return index, subject[index];
    end, self, 0;
end
Array.iter = Array.iterator;

---Joins items in the array into a singular string
---@param delimiter string The delimiter to place between items
---@param callback (fun(value: any, index: number, array: sreject.Array): string)? Function to handle stringification of values
---@return string
function Array:join(delimiter, callback)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(delimiter) ~= 'string') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        local len = #self;
        if (len > 0) then
            local result = remove(self, len);
            rawset(self, 'length', len - 1);
            return result;
        end
    end
end

---Adds the value(s) to the end of the array
---@param ... any The value(s) to add
---@return sreject.Array # The current array instance
function Array:push(...)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end

---Creates a new method queue
---@return sreject.ArrayMethodQueue
function Array:queue()
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        return setmetatable({
            subject = self,
            tasks = Array.new()
        }, { __index = ArrayMethodQueue });
    end
end

---Reduces the array by calling the callback with the previous call's result
---and the current element
---
---@param callback fun(result: any, currentValue: any, index: number, self: any): any
---@param initialValue any The starting value
---@return any
function Array:reduce(callback, initialValue)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (type(callback) ~= 'function') then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end
Array.delete = Array.remove;

---Creates a new array containing the current array's items in reverse order
---@return sreject.Array
function Array:reverse()
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        local instance = Array.new();
        local itemCount = 0;
        for index=#self, 1, -1 do
            itemCount = itemCount + 1;
            rawset(instance, itemCount, self[index]);
        end
        rawset(instance, 'length', #self);
        return instance;
    end
end

---Removes the first item of the array and returns it
---@return any
function Array:shift()
    if (Array.isArray(self) == false) then
        error('subject is not array');
    elseif (#self) then
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
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end

---Returns a new array sorted based on the result of callback
---@param callback (fun(aValue: any, bValue: any):boolean)? Returning true indicates aValve comes before bValve
---@return sreject.Array # A new Array instance
function Array:sort(callback, sortSelf)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        local instance;
        if (sortSelf == true) then
            instance = self;
        else
            instance = self:slice();
        end
        sort(instance, callback)
        return instance;
    end
end

---Altars the array by deleting then inserting values
---@param start number? The starting position; values less than 1 are assumed to mean from the end of the array
---@param delete number? The number of items to delete at the specified start position
---@param ... any? The items to insert at the starting position once deletions have been done
---@return sreject.Array # The current array instance
function Array:splice(start, delete, ...)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
        if (delete ~= nil and delete ~= 0) then
            self:remove(start, delete);
        end
        self:insert(start, ...);
        return self;
    end
end

---Creates a new array containing the non-nil values of the current array
---@return sreject.Array
function Array:sweep()
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end

---Adds the specified value(s) to the start of the array
---@param ... any
---@return sreject.Array # The current Array instance
function Array:unshift(...)
    if (Array.isArray(self) == false) then
        error('subject is not array');
    else
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
end

--#endregion

---@param self sreject.ArrayMethodQueue
local function amqAddGroupTask(self, fn)
    if (self.taskGroup == nil) then
        self.taskGroup = { task = "group", tasks = Array.new() };
    end
    self.taskGroup.tasks:push({
        task = "method",
        fn = fn
    });
    return self;
end

---Queues: Removing duplicate values from the array
---@param allowNil boolean? Allows a nil be to added to the result if such a value has not been encountered
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:dedupe(allowNil)
    local seen = {};
    local noSeenNil = true;
    return amqAddGroupTask(self, function (value)
        if (value == nil) then
            if (allowNil and noSeenNil) then
                noSeenNil = false;
                return false, nil;
            end
        elseif (seen[value] == nil) then
            return false, value;
        end
        return true;
    end);
end

---Calls the callback for each item in the array.
---@param callback fun(value: any, index: number, array: sreject.Array): nil
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:each(callback)
    return amqAddGroupTask(self, function (value, index, array)
        callback(value, index, array);
        return true, value;
    end);
end
ArrayMethodQueue.forEach = ArrayMethodQueue.each;

---Queues: Removing items from the array that do not pass the callback
---@param callback fun(value: any, index: number, array: sreject.Array):boolean
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:filter(callback)
    return amqAddGroupTask(self, function (value, index, array)
        return callback(value, index, array) == true, value;
    end);
end

---Queues: Transforming values by calling the callback on each element of the array
---@param callback fun(value: any, index: number, array: sreject.Array): any
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:map(callback)
    return amqAddGroupTask(self, function (value, index, array)
        return true, callback(value, index, array)
    end);
end

---Queues: Removing nil values from the array
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:sweep()
    return amqAddGroupTask(self, function (value, index, array)
        return value ~= nil, value;
    end);
end

---@param self sreject.ArrayMethodQueue
---@param fn fun(self: sreject.Array, ...: unknown[]):any
---@param ... any
local function amqAddMethodTask(self, fn, ...)
    if (self.taskGroup ~= nil) then
        self.tasks:push(self.taskGroup);
        self.taskGroup = nil;
    end
    self.tasks:push({ task = "method", fn = fn, args = table.pack(...) });
    return self;
end

---Queues: Adding numerical-indexes from the given arrays to the subject array
---@param ... sreject.Array|{[number]: any} The arrays to concatinate
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:concat(...)
    return amqAddMethodTask(self, function (...)
        local args, index = table.pack(...), 0;
        local subject;
        if (self.subject == args[1]) then
            subject = Array.new();
        else
            subject = args[1];
            index = 1;
        end
        local size = #subject
        for i, entry in next, args, index do
            for ii,item in Array.from(entry):iter() do
                size = size + 1;
                subject[size] = item;
            end
        end
        rawset(subject, 'length', size);
        return subject;
    end, ...);
end

---Queues: Inserting items at the given position
---@param position number? if start is nil the start of the array is assumed, if start is less than one start it is assumed to count backwards from the end of the array
---@param ... any The values to insert
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:insert(position, ...)
    return amqAddMethodTask(self, Array.insert, position, ...);
end

---Queues: Adding the value(s) to the end of the array
---@param ... any The value(s) to add
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:push(...)
    return amqAddMethodTask(self, Array.push, ...);
end

---Queues: Reversing the array
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:reverse()
    return amqAddMethodTask(self, function (subject)
        local target = subject == self.subject and Array.new() or subject;
        local len = #subject;
        for i=1,math.floor(len / 2),1 do
            local ii = len + 1 - i;
            target[i], target[ii] = subject[ii], subject[i];
        end
        return target;
    end);
end

---Queues: Sorting the array
---@param callback (fun(aValue: any, bValue: any):boolean)? Returning true indicates aValve comes before bValve
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:sort(callback)
    ---@param callback fun():boolean
    return amqAddMethodTask(self, function (subject, callback)
        if (self.subject == subject) then
            subject = Array.new();
            for i,k in self.subject:iter() do
                subject.push(k);
            end
        end
        table.sort(subject, callback);
        return subject;
    end, callback);
end

---Queues: Altaring the array by deleting then inserting values
---@param position number? The starting position; values less than 1 are assumed to mean from the end of the array
---@param count number? The number of items to delete at the specified start position
---@param ... any? The items to insert at the starting position once deletions have been done
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:splice(position, count, ...)
    return amqAddMethodTask(self, Array.splice, position, count, ...);
end

---Queues: Adding the specified value(s) to the start of the array
---@param ... any
---@return sreject.ArrayMethodQueue
function ArrayMethodQueue:unshift(...)
    return amqAddMethodTask(self, Array.unshift, ...);
end

---Executes queued method(s) and returns the result
---@return sreject.Array
function ArrayMethodQueue:exec()
    if (self.taskGroup ~= nil) then
        self.tasks.push(self.taskGroup);
    end
    if (#self.tasks == 0) then
        return self.subject;
    else
        local subject = self.subject;
        for _,task in self.tasks:iter() do
            if (task.task == 'group') then
                local result = Array.new();
                for index, value in subject:iter() do
                    local keep = true;
                    for _,gtask in task.tasks:iter() do
                        local continue, res = gtask.fn(value, index, subject);
                        if (continue) then
                            value = res;
                        else
                            keep = false;
                            break;
                        end
                    end
                    if (keep) then
                        result.push(value);
                    end
                end
                subject = result;
            else
                subject = task.fn(subject, table.unpack(task.args));
            end
        end
        return subject;
    end
end
ArrayMethodQueue.execute = ArrayMethodQueue.exec;
ArrayMethodQueue.run = ArrayMethodQueue.exec;

return { Array = Array, ArrayMethodQueue = ArrayMethodQueue };