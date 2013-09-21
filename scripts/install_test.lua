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
    local cat = textutils.unserialize(getUrlFile(proglist))
    local programs = {}
    local pname = {}
    for name,data in pairs(cat) do
      table.insert(pname, data.Name .." ".. data.Version)
      table.insert(programs, name)
    end
    -- lets now say we need a startup file with certain args, also to load the APIs
    startup=fs.open('startup','w')
    local apis = {'admapi','button'}
    for i,api in pairs(apis) do
        print("downloading ".. cat[api].Name)
        local program = getUrlFile(cat[api].GitURL)
        writeFile(api,program)
        --all of these were APIs...
        --os.loadAPI(api)
        startup.write("os.loadAPI('"..api.."')\n")
    end
    startup.close()


    
end