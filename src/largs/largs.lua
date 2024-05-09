local exports = {};

local function smatch(subject, pattern, position)
    position = position or 1;

    local found = string.find(subject, pattern, position);
    if (found == nil or found ~= position) then
        return false;
    end

    return true, string.match(subject, pattern, position);
end

local function trim(subject)
    while (string.sub(subject, 1,1) == ' ') do
        subject = string.sub(subject, 2, 1);
    end
    while (string.sub(subject, -1, 1) == ' ') do
        subject = string.sub(subject, 1, -1);
    end
    return subject;
end

local function isNum(value)
    if (value == nil) then
        return false;
    end
    if (type(value) == 'string') then
        value = tonumber(value);
    end
    if (type(value) ~= 'number') then
        return false;
    end
    if (value ~= value) then
        return false;
    end

    local strValue = tostring(value);
    return strValue ~= tostring(0/0) and strValue ~= tostring(-(0/0));
end

function exports.largs(options, vargs)

    local index = 0;
    while (index < #vargs) do
        index = index + 1;
        ::next::

        -- Convert {"-key=value"} to {"-key", "value"}
        local matched, flag, value = smatch(vargs[index], '%s*-+([^=%s]*)%s*=%s*(.*)');
        if (matched) then
            vargs[index] = '-' .. flag;
            index = index + 1;
            table.insert(vargs, index, trim(value));
            goto continue;
        end

        -- Convert {"--key .."} to {'-key', '..'}
        matched, flag, value = smatch(vargs[index], '%s*--+([^=%s])(.*)');
        if (matched) then
            vargs[index] = '-' .. flag;
            value = trim(vargs);
            if (value ~= '') then
                table.insert(vargs, index + 1, value);
            end
            goto continue;
        end

        -- Remove empty flags {"--"} to {}
        matched, value = smatch(vargs[index], '--+%s*(.*)');
        if (matched) then
            value = trim(value);
            if (value ~= '') then
                vargs[index] = value;
            else
                table.remove(vargs, index);
            end
            goto next;
        end

        ::continue::
    end

    if (options == nil) then
        options = {};
    end
    if (options.options == nil) then
        options.options = {};
    end
    if (options.aliases == nil) then
        options.aliases = {};
    end

    local result = {};
    index = 0;
    while (index < #vargs) do
        index = index + 1;

        local arg = vargs[index];

        local fchar = string.sub(arg, 1, 1);
        if (fchar == '') then
            goto continue;

        elseif (fchar ~= '-') then
            table.insert(result, { type = 'value', values = { arg } });
            goto continue;
        end

        arg = string.sub(arg, 2);

        local value = { type = 'flag', originalName = arg };

        -- de-alias arg
        if (options.aliases[arg]) then
            arg = options.aliases[arg];
        end
        value.name = arg;
        local argOpts = options.options[arg];

        -- toggle; flag does not accept a parameter
        if (argOpts == nil or argOpts.type == nil or argOpts.type == 'toggle') then
            value.values = { true };
            table.insert(result, value);
            goto continue;
        end

        -- boolean; flag accepts a boolean value of "true" or "false"
        if (argOpts.type == 'boolean') then
            local default = true;
            if (argOpts.default ~= nil) then
                default = argOpts.default;
            end


            local peek = vargs[index + 1];
            if (peek == nil or peek == '') then
                value.values = { default }
            else
                peek = string.lower(peek);
                if (peek == 'true') then
                    value.values = { true };
                    index = index + 1;

                elseif (peek == 'false') then
                    value.values = { false };
                    index = index + 1;
                else
                    value.values = default;
                end
            end
            table.insert(result, value);
            goto continue;
        end

        -- number; flag accepts a numerical value
        if (argOpts.type == 'number') then
            local default = 0;
            if (argOpts.default ~= nil) then
                default = argOpts.default;
            end

            local peek = vargs[index + 1];
            if (peek == nil or peek == '') then
                value.values = { default };

            elseif (peek ~= nil) then
                peek = tonumber(peek);
                if (isNum(peek) == true) then
                    value.values = { peek };
                    index = index + 1;
                else
                    value.values = { default };
                end
            end
            table.insert(result, value);
            goto continue;
        end

        -- string; flag accepts a singular string value
        if (argOpts.type == 'string') then
            local peek = vargs[index + 1];
            if (peek == nil or peek == '') then
                value.values = { argOpts.default or '' };
            else
                value.value = { peek };
            end
            table.insert(result, value);
            index = index + 1;
            goto continue;
        end

        -- list; flag accepts one or more parameters delimited by comma or spaces
        if (argOpts.type == 'list') then
            local nextNotFlag = true;
            value.values = {};

            while (index < #vargs) do
                local nnf = nextNotFlag;
                nextNotFlag = false;

                index = index + 1;

                ::again::

                local peek = vargs[index];

                if (trim(peek) == '') then
                    goto continue;
                end

                if (trim(peek) == ',') then
                    nextNotFlag = true;
                    goto continue;
                end

                -- split peek by comma and add items to vargs
                if (string.find(peek, ',')) then
                    local pvalues = {};
                    for str in string.gmatch(peek, "([^,]*)") do
                        str = trim(str);
                        if (str ~= '') then
                            table.insert(pvalues, str);
                            table.insert(pvalues, ',');
                        end
                    end
                    if (#pvalues) then
                        table.remove(pvalues, #pvalues);
                    end
                    if (#pvalues) then
                        for idx, pvalue in ipairs(pvalues) do
                            if (idx == 1) then
                                vargs[index] = pvalue;
                            else
                                table.insert(vargs, index - 1 + idx, pvalue);
                            end
                        end
                        goto again;
                    end
                end
                if (nnf == true or string.sub(peek,1,1) ~= '-') then
                    table.insert(value.values --[[@as table]], peek);
                else
                    index = index - 1;
                    break;
                end
                ::continue::
            end
            table.insert(result, value);
            goto continue;
        end

        error('Unknown flag type');
        ::continue::
    end
    return result;
end


return exports;