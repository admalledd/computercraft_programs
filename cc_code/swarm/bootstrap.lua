--This should be "minimal" code to:
-- 1. load minimal settings of settings file to find URL_BASE
-- 2. re-download ourself and re-execute (for in-place updates)
-- 3. now assuming <THIS> up to date, get install manifest, download/build files
-- 4. call/begin "swarm.lua"

--wget run http://localhost:5000/api/GetFile/GetBootstrapFile

args = { ... }
local DEFAULT_URL_BASE = "http://localhost:5000/api/"
local URL_BASE = DEFAULT_URL_BASE

--HACKY: while settings.lua is WIP... just ignore settings to keep bootstrapper happy
if fs.exists('/settings.json') and false then
    --use pcall as wrapper of try/catchy. if settings parse fails, assume defaults though
    local ok, res = pcall(function()
        local s_file = fs.open("/settings.json","r")
        local s_data = s_file.readAll()
        s_file.close()
        local s_parsed = textutils.unserializeJSON(s_data)
        if s_parsed ~= nil and s_parsed.url_base ~= nil and type(s_parsed.url_base) == 'string' then
            return s_parsed.url_base
        end
        error("unable to load even basic url_base from settings.json, does file even exist?")
    end)
    if not ok then
        print('settings file corrupt? assuming default bootstrap URL')
        print('err was: '..tostring(res))
    else
        URL_BASE = res
    end
end

if args[1] == nil then
    --first run, re-get and re-run bootstrap?
    local ok, res = pcall(function()
        local h_req = http.get(URL_BASE.."GetFile/GetBootstrapFile")
        local h_txt = h_req.readAll()
        local b_fil = fs.open("/bootstrap.lua", "w")
        b_fil.write(h_txt)
        b_fil.close()
        shell.run("/bootstrap.lua", 'update')
    end)
    if not ok then
        print('error getting new bootstrap, running as-is instead')
        print('err was: '..tostring(res))
    else
        return
    end
end

--PREAMBLE DONE

function update()
    --[[
        1. get manifest
        2. get each file from manifest
        3. (not here) run main func per manifest
    ]]
    --NB: some of these helper funcs to wrap around settings/file-get etc are duplicated here
    -- normal code should rely/use the `require("swarm_http")` or such
    local get_text = function(file)
        local h_req = http.get(URL_BASE.."GetFile/GetFile?fname=swarm/"..file)
        local h_txt = h_req.readAll()
        return h_txt
    end
    local save_file = function(webPath, fileName)
        if fileName == nil then fileName = webPath end
        print('bootstrap: fetching '..webPath)
        local f_text = get_text(webPath)
        local f_file = fs.open(fileName, 'w')
        f_file.write(f_text)
        f_file.close()
        return f_text --in case we want text in-place too, can be handy
    end
    local manifest_txt = save_file("manifest.json", '/manifest.json')
    local manifest = textutils.unserializeJSON(manifest_txt)
    for key, value in pairs(manifest.files) do
        save_file(key, value)
    end
end

if args[1] == 'update' or not fs.exists('/manifest.json') then
    print('running update...')
    update()
end

local manifest = {}
do
    local manifest_f = fs.open('/manifest.json', 'r')
    local manifest_txt = manifest_f.readAll()
    manifest_f.close()
    manifest = textutils.unserializeJSON(manifest_txt) 
end
print('running entry file:`'..manifest.entry..'`')
return shell.run(manifest.entry)