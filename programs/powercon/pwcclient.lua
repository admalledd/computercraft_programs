--fname:pwcclient
--version:1.05
--type:installer
--name:powerCon Client
--description:Power control client

args = { ... } --list of what to listen for (in order)
--EG::: "Crafting:left" listens for the Crafting button, and sets the left side to it

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
    f=fs.open('startup','w')
    f.write('os.loadAPI("admapi")\n')
    print('choose what to listen to/side to output...')
    print('eg: "Crafting:right"')
    print('use qq to signify end of config')
    
    local arg=''
    local input = ''
    while input ~= 'qq' do
        arg=arg..' '..input
        input=read()
    end
    f.write('shell.run("pwcclient '..arg..'")')
    f.close()
    print('pwcclient installed and configured...')
    print('press enter to reboot')
    read()
    os.reboot()

end

--program start...

listeners={}
admapi.printTable(args)
for i=1,#args do
    local tmp = admapi.split(args[i],":")
    listeners[tmp[1]] = tmp[2]
end

modem = peripheral.wrap("top")
modem_channel=512
modem.open(modem_channel+1)

modem.transmit(modem_channel,modem_channel+1,'restarted')

while true do
    event = admapi.getEvent()
    if event.type == "modem_message" then
        local outputs = textutils.unserialize(event.msg)
        for k,v in pairs(listeners) do
            if outputs[k] ~= nil then
                print("setting "..k.." to "..tostring(outputs[k]))
                rs.setOutput(v,outputs[k])
            end
        end
    end
end
