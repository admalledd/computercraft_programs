--fname:pwcclient
--version:1.05
--type:program
--name:powerCon Client
--description:Power control client

args = { ... } --list of what to listen for (in order)
--EG::: "Crafting:left" listens for the Crafting button, and sets the left side to it
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


if admapi.split(event.msg,':')[1] == 'restarted' then
    local outputs={}
    for k,btn in pairs(buttons) do
        --print(btn.text ..":"..tostring(btn.enabled))
        outputs[btn.text] = btn.enabled
    end
    
    modem.transmit(event.replyFreq,modem_channel,textutils.serialize(outputs))
end