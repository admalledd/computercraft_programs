--fname:install
--version:1.01
--type:installer
--name:Installer Test
--description:Tests getprog if installation works


--installation script example, use installers if you need an API or post-dl config

--arguments for "installer" type programs: args[1] is "install", 
-- args[2] is the proglist URL that was used to get this file. This is so that
-- we can get the same/correct version of files needed in case some one changes 
-- getprog.lua (i hate changing that BTW...)


args={...}


term.setCursorPos(1,1)
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

if args[1] == 'install' then
    -- we need to install this program (example file does nothing interesting...)

    -- get list of programs/apis/ectect 
    local cat = textutils.unserialize(getUrlFile(args[2]))

    local apis = {'admapi'}
    for i,api in pairs(apis) do
        print("downloading ".. cat[api].Name)
        local program = getUrlFile(cat[api].GitURL)
        writeFile(api,program)
    end    
end