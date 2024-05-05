package.path = package.path .. ";/?.lua;/?/init.lua"

local describe,it,test = require('lut').lut();
local expect = require('expect').expect;
local Array = require('array');

describe('Array.new()', function()
    it('Creates an array', function ()
        expect(function ()
            return getmetatable(Array.new()).__index;
        end):toEqual(Array)
    end);
    it('Creates an array with initial values', function ()
        expect(function ()
            return table.unpack(Array.new(1,2,3));
        end):toEqual(1,2,3)
    end);
    it('Values are retrievable', function ()
        expect(function()
            return Array.new(1,2,3)[2];
        end):toEqual(2);
    end);
    it('Values are updatable', function ()
        expect(function()
            local array = Array.new(1,2,3);
            array[2] = "abc";
            return array[2];
        end):toEqual("abc");
    end);
    it('Indexes can be arbitrarily set', function ()
        expect(function ()
            local array = Array.new();
            array[12] = "test";
            return array[12];
        end):toEqual("test");
    end);
    it('Arbitrarily set indexes update length', function ()
        expect(function ()
            local array = Array.new();
            array[12] = "test";
            return #array;
        end):toEqual(12);
    end);
    it('Accepts nil as an initial value', function ()
        expect(function ()
            local array = Array.new(1, nil, 3);
            return #array;
        end):toEqual(3);
    end);
end);

describe('Array.concat()', function ()
    it('Does not raise an error', function ()
        expect(function ()
            Array.concat();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function()
        expect(getmetatable(Array.concat()).__index, true):toEqual(Array);
    end);
    it('Adds members from the parameters to the resulting Array', function ()
        local array = Array.concat({1}, {2}, {3});
        expect(function ()
            return table.unpack(array);
        end):toEqual(1,2,3);
    end);
    it('Excludes non-indexed fields', function ()
        local array = Array.concat({1, test = 2}, {3});
        expect(function ()
            return table.unpack(array);
        end):toEqual(1,3);
    end);
end);

describe('Array:all()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():all();
        end):toThrow();
    end);
    it('Calls the callback with each value in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):all(function (value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                end
                return true;
            end);
            return count,ordered;
        end):toEqual(3,true);
    end);
    it('Returns true if all items match callback', function()
        expect(function ()
            return Array.new(true,true,true):all(function (value) return value == true; end);
        end):toEqual(true);
    end);
    it('Returns false if any items fail to match callback', function()
        expect(function ()
            return Array.new(true,true,false):all(function (value) return value == true; end);
        end):toEqual(false);
    end);
    it('Returns false if there\'s no items and atLeastOne parameter is specified', function()
        expect(function ()
            return Array.new():all(function (value) return value == true; end, true);
        end):toEqual(false);
    end);
end);

describe('Array:any()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():any();
        end):toThrow();
    end);
    it('Calls the callback with each item in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):any(function(value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                ---@diagnostic disable-next-line missing-return
                end
            end);
            return count,ordered;
        end):toEqual(3,true);
    end);
    it('Returns true if atleast one item matches the callback', function()
        expect(function ()
            return Array.new(false,false,true):any(function (value) return value == true; end);
        end):toEqual(true);
    end);
    it('Returns false if no items match the callback', function()
        expect(function ()
            return Array.new(false,false,false):any(function (value) return value == true; end);
        end):toEqual(false);
    end);
    it('Returns true if the array is empty and allowEmpty is true', function()
        expect(function ()
            return Array.new():any(function (value) return value == true; end, true);
        end):toEqual(true);
    end);
end);

describe('Array:concat()', function ()
--[[
    Array:concat() is already tested via Array.concat tests
]]
end);

describe('Array:each()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():each();
        end):toThrow();
    end);
    it('Calls the callback with each value in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):each(function (value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                ---@diagnostic disable-next-line missing-return
                end
            end);
            return count,ordered;
        end):toEqual(3,true);
    end);
    it('Returns the array instance', function ()
        local array = Array.new(1,2,3);
        expect(function()
            return array:each(function () end);
        end):toEqual(array);
    end);
end);

describe('Array:filter()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():filter();
        end):toThrow();
    end);
    it('Calls the callback with each value in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):filter(function (value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                ---@diagnostic disable-next-line missing-return
                end
            end);
            return count,ordered;
        end):toEqual(3, true);
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new(1,2,3);
            ---@diagnostic disable-next-line missing-return
            local result = array:filter(function () end);
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Filters out non-matching items', function ()
        expect(function (...)
            local array = Array.new(1,2,3,4):filter(function (value)
                return value == 2 or value == 4;
            end);
            return #array,table.unpack(array);
        end):toEqual(2,2,4)
    end);
end);

describe('Array:find()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():find();
        end):toThrow();
    end);
    it('Calls the callback with each value in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):find(function (value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                ---@diagnostic disable-next-line missing-return
                end
            end);
            return count,ordered;
        end):toEqual(3,true);
    end);
    it('Returns the first matching index', function ()
        expect(function ()
            return Array.new("a", "b", "c", "a", "b", "c"):find(function (value)
                return value == "c";
            end);
        end):toEqual(3);
    end);
end);

describe('Array:findLast()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():findLast();
        end):toThrow();
    end);
    it('Calls the callback with each value in reverse order', function()
        expect(function ()
            local count = 3;
            local ordered = true;
            Array.new(1,2,3):findLast(function (value)
                if (count ~= value) then
                    ordered = false;
                end
                ---@diagnostic disable-next-line missing-return
                count = count - 1;
            end);
            return count,ordered;
        end):toEqual(0, true);
    end);
    it('Returns the last matching index', function ()
        expect(function ()
            return Array.new("a", "b", "c", "a", "b", "c"):findLast(function (value)
                return value == "c";
            end);
        end):toEqual(6);
    end);
end);

describe('Array:insert()', function ()
    it('Does not raise an error', function ()
        expect(function ()
            Array.new():insert();
        end):toNotThrow();
    end);
    it('Returns the current array instance', function ()
        local array = Array.new();
        expect(array:insert(), true):toEqual(array);
    end);
    it('Adds items', function ()
        local array = Array.new();
        array:insert(1, "a");
        expect(array[1], true):toEqual('a');
    end);
    it('Shifts items', function ()
        local array = Array.new("b");
        array:insert(1, "a");
        expect(function ()
            return array[1],array[2]
        end):toEqual('a', 'b');
    end);
    it('Updates size', function ()
        local array = Array.new();
        array:insert(1, "a");
        expect(#array, true):toEqual(1);
    end);
    it('Inserts items at specified start position', function ()
        local array = Array.new('a', 'd');
        array:insert(2, 'b', 'c');
        expect(function ()
            return #array,table.unpack(array);
        end):toEqual(4,'a','b','c','d');
    end);
    it('Properly handles negetive positions', function ()
        local array = Array.new('a', 'c');
        array:insert(-1, 'b');
        expect(function ()
            return #array,table.unpack(array);
        end):toEqual(3,'a','b','c');
    end);
end);

describe('Array:join()', function ()
    it('Throws an error when delimiter is not a string', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():join();
        end):toThrow();
    end);
    it('Returns a string', function ()
        expect(Array.new():join(''), true):toBe('string');
    end);
    it('Concatinates array items into a string using tostring()', function ()
        expect(Array.new(1,2,3):join(''), true):toBe('string'):toEqual('123');
    end);
    it('Delimits items by the given delimiter', function ()
        expect(Array.new(1,2,3):join(','), true):toBe('string'):toEqual('1,2,3');
    end);
    it('Leverages the stingifier callback when specified', function ()
        expect(Array.new('a','b','c'):join(',', string.upper), true):toEqual('A,B,C')
    end);
    it('Converts values from stingifier callback to strings', function ()
        expect(Array.new(1,2,3):join(',', function (value) return value; end),true):toEqual('1,2,3');
    end);
end);

describe('Array:map()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():map();
        end):toThrow();
    end);
    it('Calls the callback with each item in order', function()
        expect(function ()
            local count = 0;
            local ordered = true;
            Array.new(1,2,3):map(function(value)
                count = count + 1;
                if (count ~= value) then
                    ordered = false;
                end
            end);
            return ordered and count == 3;
        end):toEqual(true);
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new(1,2,3);
            local result = array:map(function () end);
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Transforms values for the resulting Array', function()
        expect(function ()
            local array = Array.new('a', 'b', 'c');
            local result = array:map(function (value)
                return value:upper()
            end);
            return #result,table.unpack(result);
        end):toEqual(3, 'A', 'B', 'C');
    end);
end)

describe('Array:pop()', function ()
    it('Does not raise an error', function ()
        expect(function ()
            Array.new():pop();
        end):toNotThrow();
    end);
    it('Removes the last item from the array', function ()
        expect(function ()
            local array = Array.new("a", "b", "c");
            array:pop();
            return #array, array[#array], array[3]
        end):toEqual(2, "b")
    end);
    it('Returns the item that was removed', function ()
        expect(Array.new("a", "b", "c"):pop()):toEqual("c");
    end);
end);

describe('Array:push()', function ()
    it('Does not raise an error', function ()
        expect(function()
            Array.new():push(1);
        end):toNotThrow()
    end);
    it('Adds an item to the array', function ()
        expect(function()
            local array = Array.new("a");
            array:push("b");
            return #array,array[2];
        end):toEqual(2,"b");
    end);
    it('Adds multiple items to the array', function ()
        expect(function()
            local array = Array.new("a");
            array:push("b", "c")
            return #array,array[3];
        end):toEqual(3, "c");
    end);
    it('Returns the array instance', function ()
        local array = Array.new();
        expect(array:push("a"), true):toEqual(array);
    end);
end);

describe('Array:reduce()', function ()
    it('Throws an error when callback is not a function', function()
        expect(function ()
            ---@diagnostic disable-next-line missing-parameter
            Array.new():reduce();
        end):toThrow();
    end);
    it('Calls the callback for each item', function()
        expect(function ()
            local count = 0;
            Array.new(1,2,3):reduce(function()
                count = count + 1;
            end);
            return count;
        end):toEqual(3);
    end);
    it('Passes the initial value to the callback only once', function ()
        expect(function ()
            local gotInitValue = 0;
            Array.new(1,2,3):reduce(function(value)
                if (value == "a") then
                    gotInitValue = gotInitValue + 1;
                end
                return {};
            end, "a");
            return gotInitValue;
        end):toEqual(1);
    end);
    it('Passes the accumulated value to the callback', function ()
        expect(function ()
            local didAccumulate = false;
            Array.new(1,2,3):reduce(function (prev, cur)
                if (prev > 0) then
                    didAccumulate = true;
                end
                return prev + 1
            end,0);
            return didAccumulate;
        end):toEqual(true);
    end);
    it('Returns the accumulated resulted', function ()
        expect(Array.new(1,2,3):reduce(function (prev, cur)
            return prev + cur;
        end,0), true):toEqual(6);
    end);
end);

describe('Array:remove()', function ()
    it('Does not raise an error', function ()
        expect(function ()
            Array.new():remove();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new();
            ---@diagnostic disable-next-line missing-return
            local result = array:remove();
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Removes an item from the array', function ()
        local array = Array.new('a');
        array:remove(1,1);
        expect(#array, true):toEqual(0)
    end);
    it('Returns removed items as an array', function ()
        local array = Array.new('a');
        local removed = array:remove(1,1);
        expect(#removed, true):toEqual(1);
        expect(removed[1], true):toEqual('a');
    end);
    it('Can delete more than one item', function ()
        local array = Array.new('a','b','c');
        local removed = array:remove(1,2);
        expect(#array, true):toEqual(1);
        expect(array[1], true):toEqual('c');
        expect(removed[1], true):toEqual('a');
        expect(removed[2], true):toEqual('b');
    end);
    it('Properly handles a negetive start parameter', function ()
        local array = Array.new('a','b','c');
        local removed = array:remove(-2,1);
        expect(#array, true):toEqual(2);
        expect(array[2], true):toEqual('c');
        expect(removed[1], true):toEqual('b');
    end);
end);

describe('Array:reverse()', function ()
    it('Does not raise an error', function ()
        expect(function ()
            Array.new(1,2,3):reverse();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new(1,2,3);
            local result = array:reverse();
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Reverses the array\'s item order', function ()
        expect(function ()
            local result = Array.new(1,2,3):reverse();
            return #result, table.unpack(result);
        end):toEqual(3, 3, 2, 1);
    end);
end);

describe('Array:shift()', function ()
    it('Does not raise an error', function()
        expect(function()
            Array.new("a"):shift();
        end):toNotThrow();
    end);
    it('Removes the first item', function ()
        expect(function()
            local array = Array.new("a", "b", "c");
            array:shift();
            return #array,array[1]
        end):toEqual(2, "b");
    end);
    it('Returns the the item that was removed', function ()
        expect(Array.new("a", "b", "c"):shift(), true):toEqual("a");
    end);
end);

describe('Array:slice()', function ()
    it('Does not raise an error', function()
        expect(function()
            Array.new():slice();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new();
            local result = array:slice();
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Copies indexable items from start to end', function ()
        expect(function ()
            local result = Array.new(1,2,3):slice();
            return #result,table.unpack(result);
        end):toEqual(3,1,2,3);
    end);
    it('Copies items from the specified start to end', function ()
        expect(function ()
            local result = Array.new(0,1,2,3):slice(2);
            return #result,table.unpack(result);
        end):toEqual(3,1,2,3);
    end)
    it('Returns an empty array if specified start is greater than length', function ()
        expect(function ()
            local result = Array.new():slice(1);
            return #result
        end):toEqual(0);
    end);
    it('Copies upto the specified stopping point', function ()
        expect(function ()
            local result = Array.new(1,2,3,4,5,6,7):slice(1,4);
            return #result,table.unpack(result);
        end):toEqual(3,1,2,3);
    end);
    it('Properly handles a negetive start', function ()
        expect(function ()
            local result = Array.new(1,2,3):slice(-2);
            return #result,table.unpack(result);
        end):toEqual(2,2,3);
    end);
    it('Properly handles a negetive stop', function ()
        expect(function ()
            local result = Array.new(1,2,3):slice(1, -1);
            return #result,table.unpack(result);
        end):toEqual(2,1,2);
    end);
end);

describe('Array:sort()', function ()
    it('Does not raise an error', function ()
        expect(function()
            Array.new():sort();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function ()
        expect(function ()
            local array = Array.new(1,2,3);
            local result = array:sort();
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Returns the current Array instance', function ()
        expect(function ()
            local array = Array.new(1,2,3);
            local result = array:sort(nil, true);
            return result == array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Sorts the array using default callback', function ()
        expect(function ()
            return table.unpack(Array.new(2,1,3):sort());
        end):toEqual(1,2,3);
    end);
    it('Sorts the array using a specified callback', function ()
        expect(function ()
            return table.unpack(Array.new(2,1,3):sort(function (a,b)
                return a > b;
            end));
        end):toEqual(3,2,1);
    end);
end)

describe('Array:splice()', function ()
    it('Does not raise an error', function ()
        expect(function()
            Array.new():splice();
        end):toNotThrow();
    end);
    it('Returns the array instance', function ()
        local array = Array.new();
        expect(array:splice(), true):toEqual(array);
    end);
    it('Removes an item from the array', function ()
        local array = Array.new('a');
        array:splice(1, 1);
        expect(#array, true):toEqual(0)
    end);
    it('Inserts an item into the array', function ()
        local array = Array.new('a', 'c');
        array:splice(2, nil, 'b');
        expect(#array, true):toEqual(3);
        expect(array[2], true):toEqual('b');
    end);
end)

describe('Array:sweep()', function()
    it('Does not raise an error', function()
        expect(function ()
            Array.new():sweep();
        end):toNotThrow();
    end);
    it('Returns a new Array instance', function()
        expect(function ()
            local array = Array.new(1,2,3);
            local result = array:sweep();
            return result ~= array and getmetatable(result).__index == Array
        end):toEqual(true);
    end);
    it('Removes only nil values', function ()
        expect(function()
            local res = Array.new(0,false,nil,3):sweep();
            return #res,table.unpack(res);
        end):toEqual(3,0,false,3);
    end)
end);

describe('Array:unshift()', function ()
    it('Does not raise an error', function()
        expect(function()
            Array.new("a"):unshift("b");
        end):toNotThrow();
    end);
    it('Adds an item to the start of the array', function ()
        expect(function()
            local array = Array.new("a");
            array:unshift("z");
            return #array,array[1]
        end):toEqual(2, "z");
    end);
    it('Adds multiple items to the start of the array', function ()
        expect(function()
            local array = Array.new("a");
            array:unshift('x', 'y', 'z');
            return #array,array[1],array[2],array[3],array[4]
        end):toEqual(4, 'x', 'y', 'z', 'a');
    end);
    it('Returns the array instance', function ()
        local array = Array.new();
        expect(array:unshift('a'), true):toEqual(array);
    end);
end);

describe('Method Call Buffering -- TODO', function ()
    -- TODO
end);

describe('Method Aliasing', function ()
    it('Maps :delete() to :remove()', function ()
        expect(Array.delete, true):toEqual(Array.remove);
    end);
    it('Maps :every() to :all()', function ()
        expect(Array.every, true):toEqual(Array.all);
    end);
    it('Maps :forEach() to :each()', function ()
        expect(Array.forEach, true):toEqual(Array.each);
    end);
    it('Maps :some() to :any()', function ()
        expect(Array.some, true):toEqual(Array.any);
    end);
end);

test();