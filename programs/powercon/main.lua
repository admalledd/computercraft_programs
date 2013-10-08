--fname:powercon
--version:1.16
--type:program
--name:IC2 Power control
--description:control/monitor multiple MFSUs

os.loadAPI("admapi")
os.loadAPI("button")

stat_mon = peripheral.wrap("right")
stat_mon.clear()
stat_mon.setCursorPos(1,1)
stat_mon.setTextScale(0.5)
stat_mon.side="right"

menu_mon = peripheral.wrap("left")
menu_mon.clear()
menu_mon.setCursorPos(1,1)
menu_mon.setTextScale(0.5)
menu_mon.side="left"

mfsus =  {}


modem = peripheral.wrap('top')
modem_channel=512
modem.open(modem_channel)


--set up remote peripherals connected via cable modem
rem = admapi.listRemotePeripheralNames("back")
for k,peri in ipairs(rem) do
    local type=peripheral.getType(peri)
    if type == 'batbox' then
        --an MFSU...
        table.insert(mfsus,peripheral.wrap(peri))
    elseif type == 'energyMeter' then
        
        print(peri)
    elseif type == 'terminal_glasses_bridge' then
        glasses=peripheral.wrap(peri)
    else
        print("unkown peri: "..type..", at: "..peri)
    end
end

--set up the multiple EU meters, manual due to reasons
--EDIT: mutliple meters a pain, use independant CPU's per, using rednet... numbers still work though

--energyMeter_1: to massfab
--energyMeter_2: to batbank
--energyMeter_3: to gamma/output


--admapi.printTable(glasses)
--print(glasses)
--for k,v in pairs(modem) do print(tostring(k)..":"..tostring(v))end


--set up button list
function callback(btn) 
    if btn.enabled == true then
        btn:disable()
    else
        btn:enable()
    end
    broadcastOutputs()
end
button.setMonitor(menu_mon)
--b = button.new("Click me!", callback, xMin, xMax, yMin, yMax)
buttons={
    button.new("massfab", callback, 5, 17, 4, 7),
    button.new("quarries", callback, 5, 17, 9, 12)
}


timers = {fast = os.startTimer(1), quarter = os.startTimer(15),
          half = os.startTimer(15) ,minute=os.startTimer(60)}

function writeLine(lnum,text)
    --write text to line on monitor
    stat_mon.setCursorPos(1,lnum)
    stat_mon.clearLine()
    stat_mon.write(text)
end
 
function getEU()
    --get stored EU in batbank
    local totalEU=0
    for k,v in ipairs(mfsus) do
        totalEU=totalEU+v.getStored()
        --writeLine(k+2,"mfsu " .. k .. " at " .. v.getStored() .. " EU")
    end
    --max measured EU::: 2759995528, 
    --minus the buffer delta?
    if totalEU < 2759995528-10000000 then
        redstone.setOutput("bottom",true)
    else
        redstone.setOutput("bottom",false)
    end

    return totalEU
    --writeLine(1,"total EU stored: " .. totalEU .. " EU")
end

function broadcastOutputs()
    local outputs={}
    for k,btn in pairs(buttons) do
        --print(btn.text ..":"..tostring(btn.enabled))
        outputs[btn.text] = btn.enabled
    end
    modem.transmit(modem_channel+1,modem_channel,textutils.serialize(outputs))
end


function main()
    while true do
        event=admapi.getEvent()
        if event.type == "monitor_touch" then
            button.doClick(event)
        elseif event.type == 'energy_measure' then
            admapi.printTable(event)
            --writeLine(2,"EU/t : "..tostring(event.getEUT(meter)))
        elseif event.type == 'timer' then
            if event.timer == timers.fast then
                timers.fast = os.startTimer(3)
                writeLine(1,"Total EU storage: ".. tostring(getEU()))
            elseif event.timer == timers.quarter then
                timers.quarter = os.startTimer(15)
                
            elseif event.timer == timers.half then
                timers.half = os.startTimer(30)
            elseif event.timer == timers.minute then
                timers.minute = os.startTimer(60)
            else 
                --unknown timer?
                print("unknown TimerID: "..tostring(event.timer))
            end
        elseif event.type == 'modem_message' then
            if admapi.split(event.msg,':')[1] == 'restarted' then
                local outputs={}
                for k,btn in pairs(buttons) do
                    --print(btn.text ..":"..tostring(btn.enabled))
                    outputs[btn.text] = btn.enabled
                end
                modem.transmit(event.replyFreq,modem_channel,textutils.serialize(outputs))
            elseif admapi.split(event.msg,':')[1] == 'EUT' then
                local eudata = admapi.split(event.msg,':')
                --"EUT:$Meter:eu/t"
                writeLine(tonumber(eudata[2])+1,eudata[3])
            end
        elseif event.type == 'char' then
            if event.char == 'q' then
                exit()
            elseif event.char == 'r' then
                for k,btn in pairs(buttons) do
                    print(btn.text ..":"..tostring(btn.enabled))
                end
            elseif event.char == 'b' then
                broadcastOutputs()
                print('sent outputs on broadcast...')
            end
        end
    end
end

main()