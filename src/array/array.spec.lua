package.path = package.path .. ";/?.lua;/?/init.lua"

-- expect/expect.lua
local ExpectLib = require('expect');
local expect = ExpectLib.expect;
local expectf = ExpectLib.expectf;
local ignore = ExpectLib.consts.ignore();
local Mock = ExpectLib.Mock;

-- lut/lut.lua
local describe,it,test = require('lut').lut();

-- /array.lua
local Array = require('array');

local function inOrder(retvalue)
    local mock;
    mock = Mock(function (value)
        if (value ~= #mock.calls) then
            mock.ordered = false;
        end
        return retvalue;
    end);
    mock.ordered = true;
    return mock;
end

describe('Array.new()', function()

    it('Creates an array', function ()
        expectf(Array.new)
            :as(Array);
    end);

    it('Creates an array with initial values', function ()
        expect(table.unpack(Array.new(1,2,3)))
            :equals(1,2,3);
    end);

    it('Values are retrievable', function ()
        expect(Array.new(1,2,3)[2])
            :equals(2);
    end);

    it('Values are updatable', function ()
        local array = Array.new(1,2,3);
        array[2] = "abc";
        expect(array[2])
            :equals("abc");
    end);

    it('Indexes can be arbitrarily set', function ()
        local array = Array.new();
        array[12] = "test";
        expect(array[12])
            :equals("test");
    end);

    it('Arbitrarily set indexes update length', function ()
        local array = Array.new();
        array[12] = "test";
        expect(#array)
            :equals(12);
    end);

    it('Accepts nil as an initial value', function ()
        expect(#(Array.new(1, nil, 3)))
            :equals(3);
    end);
end);

describe('Array.concat()', function ()

    it('Does not raise an error', function ()
        expectf(Array.concat)
            :isnt()
            :throws();
    end);

    it('Returns a new Array instance', function()
        expect(Array.concat())
            :as(Array)
    end);

    it('Adds members from the parameters to the resulting Array', function ()
        expect(table.unpack(Array.concat({1}, {2}, {3})))
            :equals(1,2,3);
    end);

    it('Excludes non-indexed fields', function ()
        expect(table.unpack(Array.concat({1, test = 2}, {3})))
            :equals(1,3);
    end);
end);

describe('Array:all()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.all, Array.new())
            :throws();
    end);

    it('Calls the callback with each value in order and returns true', function()
        local mock = inOrder(true);
        expect(Array.new(1, 2, 3):all(mock.fn), #mock.calls, mock.ordered)
            :equals(true, 3, true);
    end);

    it('Returns false if any items fail to match callback', function()
        expect(Array.new(true, true, false):all(function (value) return value == true; end))
            :equals(false);
    end);

    it('Returns false if there\'s no items and atLeastOne parameter is specified', function()
        expect(Array.new():all(function () return true end, true))
            :equals(false);
    end);
end);

describe('Array:any()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.any, Array.new())
            :throws()
    end);

    it('Calls the callback with each item in order', function()
        local mock = inOrder(false);
        expect(Array.new(1,2,3):any(mock.fn), #mock.calls, mock.ordered)
            :equals(false, 3, true);
    end);

    it('Returns true if atleast one item matches the callback', function()
        expect(Array.new(1, 2, 3):any(function (value) return value == 3 end))
            :equals(true);
    end);

    it('Returns true if atleast one item matches the callback', function()
        expect(Array.new(1, 2, 3):any(function (value) return value == 4 end))
            :equals(false);
    end);

    it('Returns true if the array is empty and allowEmpty is true', function()
        expect(Array.new():any(function (value) return value == true; end, true))
            :equals(true);
    end);
end);

describe('Array:concat()', function ()
    --Array:concat() is already tested via Array.concat tests
end);

describe('Array:each()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.each, Array.new())
            :throws()
    end);

    it('Calls the callback with each value in order', function()
        local mock = inOrder();
        expect(Array.new(1,2,3):each(mock.fn), #mock.calls, mock.ordered)
            :equals(ignore, 3, true);
    end);

    it('Returns the array instance', function ()
        local array = Array.new(1,2,3);
        expect(array:each(function () end)):equals(array);
    end);
end);

describe('Array:filter()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.filter, Array.new()):throws();
    end);

    it('Calls the callback with each value in order', function()
        local mock = inOrder(true);
        expect(Array.new(1, 2, 3):filter(mock.fn), #mock.calls, mock.ordered)
            :equals(ignore, 3, true);
    end);

    it('Returns a new Array instance', function()
        local array = Array.new(1,2,3);
        expectf(Array.filter, array, function()end)
            :as(Array)
            :isnt():equals(array);
    end);

    it('Filters out non-matching items', function ()
        local result = Array.new(1,2,3,4):filter(function (value)
            return value == 2 or value == 4;
        end);
        expect(table.unpack(result))
            :equals(2,4);
    end);
end);

describe('Array:find()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.find, Array.new()):throws();
    end);

    it('Calls the callback with each value in order', function()
        local mock = inOrder();
        expect(Array.new(1, 2, 3):find(mock.fn), #mock.calls, mock.ordered)
            :equals(ignore, 3, true);
    end);

    it('Returns the first matching index', function ()
        local result = Array.new("a", "b", "c", "a", "b", "c"):find(function (value)
            return value == "c";
        end)
        expect(result):equals(3);
    end);
end);

describe('Array:findLast()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.findLast, Array.new()):throws();
    end);

    it('Calls the callback with each value in reverse order', function()
        expectf(function ()
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
        end):equals(0, true);
    end);

    it('Returns the last matching index', function ()
        local result = Array.new("a", "b", "c", "a", "b", "c"):findLast(function (value)
            return value == "c";
        end)
        expect(result):equals(6);
    end);
end);

describe('Array:insert()', function ()

    it('Does not raise an error', function ()
        expect(Array.insert, Array.new())
            :isnt()
            :throws();
    end);

    it('Returns the current array instance', function ()
        local array = Array.new();
        expect(array:insert())
            :equals(array);
    end);

    it('Adds items', function ()
        local array = Array.new();
        array:insert(1, "a");
        expect(array[1])
            :equals('a');
    end);

    it('Shifts items', function ()
        local array = Array.new("b");
        array:insert(1, "a");
        expect(table.unpack(array))
            :equals('a', 'b');
    end);

    it('Updates size', function ()
        local array = Array.new();
        array:insert(1, "a");
        expect(#array)
            :equals(1);
    end);

    it('Inserts items at specified start position', function ()
        local array = Array.new('a', 'd');
        array:insert(2, 'b', 'c');
        expect(#array, table.unpack(array))
            :equals(4,'a','b','c','d');
    end);

    it('Properly handles negetive positions', function ()
        local array = Array.new('a', 'c');
        array:insert(-1, 'b');
        expect(#array, table.unpack(array))
            :equals(3,'a','b','c');
    end);
end);

describe('Array:join()', function ()

    it('Throws an error when delimiter is not a string', function()
        expectf(Array.join, Array.new())
            :throws();
    end);

    it('Returns a string', function ()
        expect(Array.new():join(''))
            :of('string');
    end);

    it('Concatinates array items into a string using tostring()', function ()
        expect(Array.new(1,2,3):join(''))
            :of('string')
            :equals('123');
    end);

    it('Delimits items by the given delimiter', function ()
        expect(Array.new(1,2,3):join(','))
            :of('string')
            :equals('1,2,3');
    end);

    it('Treats nil as an empty string', function ()
        expect(Array.new(1,nil,2):join(''))
            :of('string')
            :equals('12');
    end);

    it('Leverages the stingifier callback when specified', function ()
        expect(Array.new('a','b','c'):join(',', string.upper))
            :equals('A,B,C')
    end);

    it('Converts values from stingifier callback to strings', function ()
        expect(Array.new(1,2,3):join(',', function (value) return value; end))
            :equals('1,2,3');
    end);
end);

describe('Array:map()', function ()

    it('Throws an error when callback is not a function', function()
        expectf(Array.map, Array.new())
            :throws();
    end);

    it('Calls the callback with each value in order', function()
        local mock = inOrder(true);
        expect(Array.new(1, 2, 3):map(mock.fn), #mock.calls, mock.ordered)
            :equals(ignore, 3, true);
    end);

    it('Returns a new Array instance', function()
        local array = Array.new();
        expect(array:map(function () end))
            :as(Array)
            :isnt():equals(array);
    end);

    it('Transforms values for the resulting Array', function()
        local array = Array.new('a', 'b', 'c');
        local result = array:map(string.upper);
        expect(#result, table.unpack(result))
            :equals(3, 'A', 'B', 'C');
    end);
end);

describe('Array:pop()', function ()
    it('Does not raise an error', function ()
        expectf(Array.pop, Array.new())
            :isnt():throws();
    end);
    it('Removes the last item from the array', function ()
        local array = Array.new("a", "b", "c");
        array:pop();
        expect(#array, array[#array], array[3])
            :equals(2, "b")
    end);
    it('Returns the item that was removed', function ()
        expect(Array.new("a", "b", "c"):pop())
            :equals("c");
    end);
end);

describe('Array:push()', function ()

    it('Does not raise an error', function ()
        expect(Array.push, Array.new())
            :isnt():throws();
    end);

    it('Adds an item to the array', function ()
        local array = Array.new('a');
        array:push('b');
        expect(#array, array[2])
            :equals(2, 'b');
    end);

    it('Adds multiple items to the array', function ()
        local array = Array.new("a");
        array:push('b', 'c')
        expect(#array, array[2], array[3])
            :equals(3, 'b', 'c');
    end);

    it('Returns the array instance', function ()
        local array = Array.new();
        expect(array:push("a"))
            :equals(array);
    end);
end);

describe('Array:reduce()', function ()
    it('Throws an error when callback is not a function', function()
        expectf(Array.reduce, Array.new())
            :throws();
    end);

    it('Calls the callback for each item', function()
        local count = 0;
        Array.new(1,2,3):reduce(function()
            count = count + 1;
        end);
        expect(count)
            :equals(3);
    end);

    it('Passes the initial value to the callback only once', function ()
        local gotInitValue = 0;
        Array.new(1,2,3):reduce(function(value)
            if (value == "a") then
                gotInitValue = gotInitValue + 1;
            end
            return {};
        end, "a");
        expect(gotInitValue)
            :equals(1);
    end);

    it('Passes the accumulated value to the callback', function ()
        local didAccumulate = false;
        Array.new(1,2,3):reduce(function (prev, cur)
            if (prev > 0) then
                didAccumulate = true;
            end
            return prev + 1
        end, 0);
        expect(didAccumulate)
            :equals(true);
    end);

    it('Returns the accumulated resulted', function ()
        local result = Array.new(1,2,3):reduce(function (prev, cur)
            return prev + cur;
        end,0)
        expect(result)
            :equals(6);
    end);
end);

describe('Array:remove()', function ()

    it('Does not raise an error', function ()
        expectf(Array.remove, Array.new())
            :isnt():throws();
    end);

    it('Returns a new Array instance', function()
        local array = Array.new();
        expect(array:remove())
            :as(Array)
            :isnt():equals(array);
    end);

    it('Removes an item from the array', function ()
        local array = Array.new('a');
        array:remove(1,1);
        expect(#array)
            :equals(0)
    end);

    it('Returns removed items as an array', function ()
        local array = Array.new('a');
        local removed = array:remove(1,1);
        expect(#removed, removed[1])
            :equals(1, 'a');
    end);

    it('Can delete more than one item', function ()
        local array = Array.new('a', 'b', 'c');
        local removed = array:remove(1, 2);
        expect(#array, array[1], removed[1], removed[2])
            :equals(1, 'c', 'a', 'b');
    end);

    it('Properly handles a negetive start parameter', function ()
        local array = Array.new('a','b','c');
        local removed = array:remove(-2, 1);
        expect(#array, array[2], removed[1])
            :equals(2, 'c', 'b');
    end);
end);

describe('Array:reverse()', function ()
    it('Does not raise an error', function ()
        expect(Array.reverse, Array.new())
            :isnt():throws();
    end);

    it('Returns a new Array instance', function()
        local array = Array.new(1,2,3);
        expect(array:reverse())
            :as(Array)
            :isnt():equals(array);
    end);

    it('Reverses the array\'s item order', function ()
        local result = Array.new(1,2,3):reverse();
        expect(#result, table.unpack(result))
            :equals(3, 3, 2, 1);
    end);
end);

describe('Array:shift()', function ()

    it('Does not raise an error', function()
        expect(Array.shift, Array.new())
            :isnt():throws();
    end);

    it('Removes the first item', function ()
        local array = Array.new("a", "b", "c");
        array:shift();
        expect(#array, array[1]):equals(2, 'b');
    end);

    it('Returns the the item that was removed', function ()
        expect(Array.new("a", "b", "c"):shift())
            :equals("a");
    end);
end);

describe('Array:slice()', function ()

    it('Does not raise an error', function()
        expectf(Array.slice, Array.new())
            :isnt():throws();
    end);

    it('Returns a new Array instance', function()
        local array = Array.new();
        expect(array:slice())
            :as(Array)
            :isnt():equals(array);
    end);

    it('Copies indexable items from start to end', function ()
        local result = Array.new(1, 2, 3):slice();
        expect(#result, table.unpack(result))
            :equals(3,1,2,3);
    end);

    it('Copies items from the specified start to end', function ()
        local result = Array.new(0,1,2,3):slice(2);
        expect(#result, table.unpack(result))
            :equals(3,1,2,3);
    end);

    it('Returns an empty array if specified start is greater than length', function ()
        expect(#(Array.new():slice(1))):equals(0);
    end);

    it('Copies upto the specified stopping point', function ()
        local result = Array.new(1, 2, 3, 4, 5, 6, 7):slice(1, 4);
        expect(#result, table.unpack(result))
            :equals(3, 1, 2, 3);
    end);

    it('Properly handles a negetive start', function ()
        local result = Array.new(1, 2, 3):slice(-2);
        expect(#result, table.unpack(result))
            :equals(2, 2, 3);
    end);

    it('Properly handles a negetive stop', function ()
        local result = Array.new(1,2,3):slice(1, -1);
        expect(#result, table.unpack(result))
            :equals(2, 1, 2);
    end);
end);

describe('Array:sort()', function ()

    it('Does not raise an error', function ()
        expectf(Array.sort, Array.new())
            :isnt():throws();
    end);

    it('Returns a new Array instance', function ()
        local array = Array.new(1,2,3);
        expect(array:sort())
            :as(Array)
            :isnt():equals(array);
    end);

    it('Returns the current Array instance if sortSelf is true', function ()
        local array = Array.new(1,2,3);
        expect(array:sort(nil, true))
            :as(Array)
            :equals(array);
    end);

    it('Sorts the array using default callback', function ()
        expect(table.unpack(Array.new(2,1,3):sort()))
            :equals(1,2,3);
    end);

    it('Sorts the array using a specified callback', function ()
        local mock = Mock(function (a, b) return a > b end);
        local array = Array.new(2,1,3):sort(mock.fn);
        expect(#mock.calls > 0, table.unpack(array))
            :equals(true, 3, 2, 1);
    end);
end)

describe('Array:splice()', function ()

    it('Does not raise an error', function ()
        expectf(Array.slice, Array.new())
            :isnt():throws()
    end);

    it('Returns the array instance', function ()
        local array = Array.new();
        expect(array:splice())
            :equals(array);
    end);

    it('Removes an item from the array', function ()
        local array = Array.new('a');
        array:splice(1, 1);
        expect(#array)
            :equals(0)
    end);

    it('Inserts an item into the array', function ()
        local array = Array.new('a', 'c');
        array:splice(2, nil, 'b');
        expect(#array, array[2])
            :equals(3, 'b');
    end);
end);

describe('Array:sweep()', function()

    it('Does not raise an error', function()
        expect(Array.sweep, Array.new())
            :isnt():throws();
    end);

    it('Returns a new Array instance', function()
        local array = Array.new(1,2,3);
        expect(array:sweep())
            :as(Array)
            :isnt():equals(array);
    end);

    it('Removes only nil values', function ()
        local res = Array.new(0,false,nil,3):sweep();
        expect(#res, table.unpack(res))
            :equals(3, 0, false, 3);
    end);
end);

describe('Array:unshift()', function ()

    it('Does not raise an error', function()
        expectf(Array.unshift, Array.new())
            :isnt():throws();
    end);

    it('Returns the current Array instance', function ()
        local array = Array.new();
        expect(array:unshift()):equals(array);
    end);

    it('Adds an item to the start of the array', function ()
        local array = Array.new("a"):unshift('z');
        expect(#array, array[1])
            :equals(2, "z");
    end);

    it('Adds multiple items to the start of the array', function ()
        expect(table.unpack(Array.new("a"):unshift('x', 'y', 'z')))
            :equals('x', 'y', 'z', 'a');
    end);
end);
--[[
describe('Method Call Buffering -- TODO', function ()
    -- TODO
end);
--]]
describe('Method Aliasing', function ()
    it('Maps :delete() to :remove()', function ()
        expect(Array.delete)
            :equals(Array.remove);
    end);
    it('Maps :every() to :all()', function ()
        expect(Array.every)
            :equals(Array.all);
    end);
    it('Maps :forEach() to :each()', function ()
        expect(Array.forEach)
            :equals(Array.each);
    end);
    it('Maps :some() to :any()', function ()
        expect(Array.some)
            :equals(Array.any);
    end);
end);

test();