
--Settings should be mostly read-only, and basically static (MC-Side at least! Server-Side can do whatever) after first init

--Default values that aren't parsed from server, eg "where is server" is sort of needed before we can load from there :)
local DEFAULT_URL_BASE = "http://localhost:5000/api/"
local DEFAULT_WS_BASE = "ws://localhost:5000/ws"

--TODO: support nested/complex value types (currently values can only be str/num/bool, no array/objects)

--local raw_settings = {}
local module = nil
function readSettings()
    local raw_settings = nil
    if not fs.exists('/settings.json') then
        raw_settings = {}
    else
        local f = fs.open('/settings.json','r')
        raw_settings = textutils.unserializeJSON(f.readAll())
        f.close()
    end
    module = createSettingsNode(raw_settings, 'root')
end
function writeSettings()
    --print('SETTINGS: saving changes to disk...')
    local f = fs.open('/settings.json','w')
    if next(module) == nil then 
        error('next() thinks settings are empty! hrm, this probably means a bugged createSettingsNode or child table?')
    end
    if module.reloadSettings ~= nil then module.reloadSettings = nil end
    local txt = textutils.serializeJSON(module)
    --print(txt)
    f.write(txt)
    rawset(module, 'reloadSettings',readSettings)
    f.close()
end

function createSettingsNode(source, parent)
    -- if newTbl._backing ~= nil then
    --     error('new settings nodes cannot have a field called `_backing`')
    --     return
    -- end
    --NB: we curry the `source` tbl, so no key polution :)
    --However the "psudo" table *has* to have something, else it won't handle next(t) correctly for JSON or anything.
    local newTbl = { 1 }
    --print('creating new settings node. parent:'..tostring(parent)..', child:'..tostring(source))
    local mt = {
        __index = function(tbl, key)
            local value = nil
            if source[key] ~= nil then
                --if we have the setting grab it and make sure it is wrapped:
                value = source[key]
                --assume people are playing along: if they have a metatable, trust it has the on-save hooking
                if type(value) == "table" and getmetatable(value) == nil then
                    value = createSettingsNode(value, source)
                    source[key] = value
                end
                return value
            else 
                --print('missing setting val for tbl:'..tostring(source)..' key:'..key)
                --if we don't have the setting, nil as is
                return nil
            end
        end,
        __newindex = function(tbl, key, value)
            local t_key = type(key)
            if t_key ~= "number" and t_key ~= "string" and t_key ~= "boolean" then
                error("only JSON compat types allowed as keys, got:"..t_key)
            end
            local t_value = type(value)
            if t_value ~= "number" and t_value ~= "string" and t_value ~= "boolean" and t_value ~= "table" then
                error("only simple types for values so far (no array/list/obj/maps), got:"..t_value)
            end
            if t_value == 'table' and getmetatable(value) == nil then
                --again, check table is wrapped, and assume if it has metatable people know what they are doing:
                value = createSettingsNode(value, source)
            end
            source[key] = value
            --and now, persist this new value to disk here-now
            --NB: this is why "write-none/near-static" comes from, don't want to spam-rewrite this all the time uselessly
            --print('writing setting from key='..key)
            writeSettings()
        end,
        --have to define a __pairs/__ipairs such that finding key/vals from source can work:
        __pairs = function(tbl)
            local function stateless_iter(tbl, k)
                local v
                k, v = next(tbl, k)
                if nil~=v then return k,v end
            end
            return stateless_iter, source, nil
            -- print('pairs?')
            -- return pairs(source)
        end,
        __ipairs = function(tbl)
            local function stateless_iter(tbl,i)
                i = i + 1
                local v = tbl[i]
                if nil~=v then return i, v end
            end
            return stateless_iter, source, 0
            -- print('ipairs?')
            -- return ipairs(source)
        end
    }
    return setmetatable(newTbl, mt)
end

readSettings()
--rawset(module, 'reloadSettings', readSettings)

--for easy search/help remembering what are in "settings":
--[[
    settings.url_base<string>
    settings.ws_base<string>
    settings.computer_db_key<string>: set by server on init/connect
    settings.debug<bool>: enable certain useful debug messages
]]
if module.url_base == nil then 
    module.url_base = DEFAULT_URL_BASE
end
if module.ws_base == nil then 
    module.ws_base = DEFAULT_WS_BASE
end

return module