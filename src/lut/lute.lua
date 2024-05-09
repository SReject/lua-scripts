local pp = require('cc.pretty').pretty_print;

local lut = require('lut');

package.path = package.path .. ";/?.lua;/?/init.lua";

local largs = require('largs.largs').largs({
    options = {
        path = { type = 'list' },
        match = { type = 'list', default = '*.spec.lua' },
        recurse = { type = 'boolean' },
        reporter = { type = 'string' }
    },
    aliases = {
        p = 'path',
        m = 'match',
        r = 'recurse',
        o = 'reporter'
    }
}, { ... });

local reporter = 'default';
local defMatch;
local defRecurse = true;
local suites = {};
local currentSuite;
local aidx = 0;
while (aidx < #largs) do
    aidx = aidx + 1;
    local arg = largs[aidx];
    if (arg.name == 'reporter') then
        reporter = arg.values[1];
    elseif (arg.type == 'value' or arg.name == 'path') then
        if (suites == nil) then
            suites = {};
        end
        if (currentSuite) then
            table.insert(suites, currentSuite);
        end
        currentSuite = {
            path = arg.values
        };
    elseif (arg.name == 'match') then
        local target;
        if (currentSuite) then
            if (currentSuite.match == nil) then
                currentSuite.match = {};
            end
            target = currentSuite.match;
        else
            if (defMatch == nil) then
                defMatch = {};
            end
            target = defMatch;
        end
        for i,match in ipairs(arg.values) do
            table.insert(target, match);
        end
    elseif (arg.name == 'recurse') then
        if (currentSuite) then
            currentSuite.recurse = arg.values[1];
        else
            defRecurse = arg.values[1];
        end
    end
end
if (defMatch == nil) then
    defMatch = { '*.spec.lua' };
end
if (suites == nil) then
    suites = {};
end
if (currentSuite ~= nil) then
    table.insert(suites, currentSuite);
    currentSuite = nil;
end


local function resolve(path)
    local function normalize(subject)

        -- normalize slashes
        subject = string.gsub(subject, '\\', '/');

        -- ignore instances of /./
        local changed = 0;
        repeat
            subject, changed = string.gsub(subject, '/./', '/');
        until (changed == 0);

        -- remove repeats of /'s
        subject = string.gsub(subject, '//+', '/');

        -- remove leading and trailing /'s
        if (string.sub(subject, 1, 1) == '/') then
            subject = string.sub(subject, 2);
        end
        if (string.sub(subject, -1, 1) == '/') then
            subject = string.sub(subject, 1, -1);
        end
        return subject;
    end
    local cwdPaths = {};
    local cwd = normalize(shell.dir());
    for str in string.gmatch(cwd, '([^/]+)') do
        table.insert(cwdPaths, str);
    end
    path = normalize(path);
    local paths = {};
    if (path ~= '') then
        for str in string.gmatch(path, '([^/]+)') do
            table.insert(paths, str);
        end
        local index = #paths;
        while (index > 0) do
            local entry = paths[index];
            if (entry == '..') then
                if (index == 1) then
                    error('cannot traverse beyond current working directory');
                end
                table.remove(paths, index);
                table.remove(paths, index -1);
                index = index - 2;
            else
                index = index - 1;
            end
        end
        if (paths[1] == '.') then
            table.remove(paths, 1);
        end
    end
    local res = '';
    for i,k in ipairs(cwdPaths) do
        res = res .. '/' .. k;
    end
    for i,k in pairs(paths) do
        res = res .. '/' .. k;
    end
    return res;
end

if (#suites == 0) then
    local dir = resolve('');
    table.insert(suites, { path = { dir } });
end

local function wcToPattern(subject)
    return subject
        :gsub('%%', '%%')
        :gsub('%.', '%%.')
        :gsub('%(', '%%(')
        :gsub('%)', '%%)')
        :gsub('%+', '%%+')
        :gsub('%[', '%%[')
        :gsub('%]', '%%]')
        :gsub('%*', '.*')
        :gsub('%?', '.')
end

for i,suite in ipairs(suites) do
    if (suite.recurse == nil) then
        suite.recurse = defRecurse;
    end
    if (suite.match == nil) then
        suite.match = defMatch;
    end
    local matches = {};
    for idx,match in ipairs(suite.match) do
        local pattern = wcToPattern(match);
        table.insert(matches, pattern);
    end
    suite.match = matches;

    for idx,path in ipairs(suite.path) do
        path = resolve(path);
        if (fs.exists(path) == false) then
            error('path does not exist');
        end
        suite.path[idx] = path;
    end
end

if (reporter == nil) then
    reporter = 'default';
elseif (string.find(reporter, ':') ~= nil) then
    if(string.sub(reporter, 1, 7) ~= 'script:') then
        error('invalid reporter');
    else
        local spath = resolve(string.sub(reporter, 8));
        local success, result = pcall(require, spath);
        if (success) then
            reporter = result.reporter;
        else
            error('failed to find cooresponding reporter');
        end
    end
end

local function listFiles(dir, recurse)
    if (fs.isDir(dir) == false) then
        return nil;
    end
    local files = {};
    local entries = fs.list(dir)
    local index = 0;
    while (index < #entries) do
        index = index + 1;

        local entry = entries[index];
        if (fs.isDir(fs.combine(dir, './' .. entry)) == false) then
            table.insert(files, entry);

        elseif (recurse) then
            local cd = entry;
            local cdEntries = fs.list(fs.combine(dir, './' .. entry));
            for i,cdEntry in ipairs(cdEntries) do
                table.insert(entries, './' .. cd .. '/' .. cdEntry);
            end
        end
    end
    return files;
end

-- Computer craft leverages .loaders instead of searchers
---@diagnostic disable-next-line deprecated
package.loaders[#package.loaders + 1] = function (name)
    if (string.sub(name, 1, 9) == 'absolute:') then
        name = string.sub(name, 10);
        if (fs.exists(name)) then
            local fn, err = loadfile(name, nil, _ENV);
            if (fn) then
                return fn, name
            else
                return err
            end
        end
        return 'file not found'
    end
end

for i,suite in ipairs(suites) do
    local recurse = suite.recurse;
    local match = suite.match;

    pp(suite.path);

    for idx,path in ipairs(suite.path) do
        if (fs.isDir(path) == true) then
            local files = listFiles(path, recurse) --[[@as {[number]: string} ]];
            for i,file in ipairs(files) do
                local filepath = fs.combine(path, file);
                local filename = fs.getName(filepath);
                local matched = false;
                for _,match in ipairs(match) do
                    if (string.find(filename, match) == 1) then
                        matched = true;
                        break;
                    end
                end
                if (matched) then
                    _G.describe, _G.it, _G.test = lut.lut(filepath, reporter);
                    require('absolute:' .. filepath);
                    test();
                end
            end
        else
            _G.describe, _G.it, _G.test = lut.lut(path, reporter);
            require('absolute:' .. path);
            test();
        end
    end
end