--fname:mg_install
--version:1.01
--type:installer
--name:mystGate
--description:installes mystcraft portal controller


--installation script example, use installers if you need an API or post-dl config

--arguments for "installer" type programs: args[1] is "install", 
-- args[2] is the proglist URL that was used to get this file. This is so that
-- we can get the same/correct version of files needed in case some one changes 
-- getprog.lua (i hate changing that BTW...)


args={...}


term.setCursorPos(1,1) --clear things
term.clear()

--basic helper functions:

function getUrlFile(url)
  local mrHttpFile = http.get(url)
  --if its failing here, check that the .ltable points to the correct server for dev work...
  mrHttpFile = mrHttpFile.readAll()
  return mrHttpFile
end
function writeFile(filename, data)
  local file = fs.open(filename, "w")
  file.write(data)
  file.close()
end


function dump(tbl)
    local function serializeImpl( t, tTracking )    
        local sType = type(t)
        if sType == "table" then
            if tTracking[t] ~= nil then
                --removed thanks to AE dup'ing tables and names when same items with different NBT are side by side
                --error( "Cannot serialize table with recursive entries" )
            end
            tTracking[t] = true
            local result = "{"
            for k,v in pairs(t) do
                result = result..("["..serializeImpl(k, tTracking).."]="..serializeImpl(v, tTracking)..",")
            end
            result = result.."}\n"
            return result
            
        elseif sType == "string" then
            return string.format( "%q", t )
        
        elseif sType == "number" or sType == "boolean" or sType == "nil" then
            return tostring(t)
            
        else
            return "@"..sType
            --pass to allow dumping of anything...
            --error( "Cannot serialize type "..sType )
            
        end
    end

    function serialize( t )
        local tTracking = {}
        return serializeImpl( t, tTracking )
    end
    --debug helper. POST tbl to server to have it recursivly dumped and parsed, good for large tables
    http.post("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(tbl))
end


if args[1] == 'install' then
    -- we need to install this program (example file does nothing interesting...)

    -- get list of programs/apis/ectect 
    local cat = textutils.unserialize(getUrlFile(args[2]))
    local urlbase = string.sub(args[2],1,-19)
    local apis = {'button','admapi'}
    for i,api in pairs(apis) do
        print("downloading api ".. cat[api].Name)
        local program = getUrlFile(cat[api].GitURL)
        writeFile(api,program)
    end
    local files = {'startup','main.lua'}
    for i,f in pairs(files) do
      print("downloading file "..f)
      local fi = getUrlFile(urlbase.."programs/mystcraft/"..f)
      writeFile(f,fi)
    end
end


shell.run('startup')