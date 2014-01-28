--fname:powercon
--version:1.16
--type:program
--name:IC2 Power control
--description:control/monitor multiple MFSUs

--load APIs, (error out soon if not installed)
os.loadAPI('admapi')

constants= {
    ["items"]={
        ["plasma"]   ={27356,131},
        ["deuterium"]={27356,1},
        ["tritium"]  ={27356,2}
    },
    ["sentinal_values"]={
        --if things are below this value, start up their processing
        ["tritium"]      = 2048,
        ["deuterium"]    = 2048,
        ["plasma_master"]= 768,
        ["plasma_fusion"]= 128
    },
    ["reactors"]={
        --[[the reactors are a little more complicated more data...
        1. Name of the reactor
        2. color used to activate the reactor (minefactory reloaded rednet cable)
        3. shutdown level, when tritium is below this turn off (must be more than 75 less than startup!)
            export fills the injector with a stack of cells, then there is the 10 internal storage, then the one that starts the reaction.
            totaling 75 cells of tritium used. recommended to actually be 128 less than startup. note that multiple reactors can be spread between
            at intervals of 16 therefore. (eg, assume all differences are 128: r1:512,r2:528,r3:544)
        4. startup level, when above this level start up the reactor. see note 3...
        
        reactors are 
        ]]


    },
    ["channels"]={
        --channels are globally unique, see programs/ME/main.getprog.lua for master list
        ["me_master"]=1024,
        ["fusion_control"]=2048
    }


}

term.setCursorPos(1,1) --clear things
term.clear()

modem  =peripheral.wrap("back")
modem.open(constants.channels.fusion_control)
monitor=peripheral.wrap("left")

--set up remote peripherals connected via cable modem

rem = admapi.listRemotePeripheralNames("back")
for k,peri in ipairs(rem) do
    local type=peripheral.getType(peri)
    if type == 'appeng_me_tilecraftingterminal' then
        print("")
    elseif type == 'appeng_me_tileoutputcable' then
        print("export bus found!")
        admapi.dump(peripheral.wrap(peri))
    else
        print("unkown peri: "..type..", at: "..peri)
        --admapi.dump(peripheral.wrap(peri))
    end
end

AE_fusion = peripheral.wrap("appeng_me_tilecraftingterminal_0")
AE_master = peripheral.wrap("appeng_me_tilecraftingterminal_1")



--admapi.dump(peripheral.wrap("top"))


function getcount(AE,item)
    -- get count of item from given AE, helper function to keep things clean.
    return AE.countOfItemType(item[1],item[2])
end

--for k,v in pairs(modem) do print(tostring(k)..":"..tostring(v))end


timers = {fast = os.startTimer(1), quarter = os.startTimer(15),
          half = os.startTimer(15) ,minute=os.startTimer(60)}

function set_fusion_outs()
    redstone.setBundledOutput("right",0)--clear bundle out
    redstone.setBundledOutput("right",colors.combine(colors.black,colors.red,colors.green))
    sleep(25)
    redstone.setBundledOutput("right",0)--clear 
end
--setfution_outs()

function transmit_counters()
    local response = {
        ["type"] = "fusion_status",
        ["counters"]={
            ["plasma_fusion"] = getcount(AE_fusion,constants.items.plasma),
            ["deuterium"] = getcount(AE_fusion,constants.items.deuterium),
            ["tritium"] = getcount(AE_fusion,constants.items.tritium),
            ["plasma_master"] = getcount(AE_master,constants.items.plasma),
        }
    }
    print(os.time(),"  got query, returned!")
    modem.transmit(constants.channels.me_master,constants.channels.fusion_control,textutils.serialize(response))
end
--print(getcount(AE_master,constants.items.plasma))

--print("quitting before i get to mainloop...")
--error()--crash here to quit!


function main()
    while true do
        event=admapi.getEvent()
        if event.type == "monitor_touch" then
            --unused!
        elseif event.type == 'modem_message' then
            event.msg = textutils.unserialize(event.msg)
            if event.msg.type ~= nil then
                --we got a valid message over custom rednet!
                if event.msg.type == "query" then
                    --transmit_counters()
                end
            else
                --unkown message! legacy message?
                print("unkown rednet message! '"..tostring(event.msg).."'")
            end
        elseif event.type == 'timer' then
            if event.timer == timers.fast then
                timers.fast = os.startTimer(1)
                transmit_counters()
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
        elseif event.type == 'char' then
            if event.char == 'q' then
                error()
            end
        end
    end
end

main()