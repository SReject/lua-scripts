-- Packs multi-value returns from a pcall into a table
---@return boolean,table<number, any>
local function tpcall(fnc, ...)
    local function packpcall(res, ...)
        return res, table.pack(...);
    end
    return packpcall(pcall(fnc, ...))
end

local function Mock(fn)
    local mocked = { calls = {} };
    function mocked.fn(...)
        local callInfo = {
            args = table.pack(...);
        }
        table.insert(mocked.calls, callInfo);
        local success,result = tpcall(fn, ...);
        callInfo.success = success;
        callInfo.result = result;
        if (success == true) then
            return table.unpack(result);
        else
            error(result,2);
        end
    end;
    return mocked
end;

return { Mock = Mock };