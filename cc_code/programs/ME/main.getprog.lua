--fname:ME_sys
--version:2.01
--type:installer
--name:AE master program
--description:master terminal for AE/ME


--[[
setup:::
left: cable bundle
right: crafting terminal
top: rednet wireless modem
bottom: Terminal glasses bridge
back: cable modem (wired)



commands available:

`me *`
    `lookup [name]|[id]` find item in ME system by name or id, returns top 3 results

    `get <id> <damagevalue> [amount]`  get item[s] from ME system by id AND dmg value.

    `eat <on|off>` enable/disable eating from enderchest



]]

--constants first so that we can use them for init stuff as well!
constants= {
    ["items"]={
        ["plasma"]   ={27356,131},
        ["deuterium"]={27356,1},
        ["tritium"]  ={27356,2},
        ["cobblestone"]    ={4,0}
    },
    ["channels"]={
        ["me_master"]=1024,
        ["fusion_control"]=2048
    }
}

mECraftingTerminal=peripheral.wrap("right")

bridge=peripheral.wrap('bottom')
--p=peripheral.wrap('up')
if bridge == nil then
  --print()
  error("No glasses bridge attached")
end
for k,v in pairs(bridge.getUsers()) do
    print(k,":",v)
end
bridge.clear()


modem = peripheral.wrap("back")
modem.open(1024) -- listening channel for main ME system

for k,peri in ipairs(peripheral.call("back","getNamesRemote")) do
    local type=peripheral.getType(peri)
    if type == "tile_block_fluid_terminal" then
        print('found fluid terminal at: "',peri,'"')
        -- this is a chest with a nearby book receptacle
        fluidTerminal=peripheral.wrap(peri)
    else
        print("unkown peri: "..type..", at: "..peri)
    end
end



-- we have a single table holding all the variables we "need", this is so that we can simply dump/restore it between sessions
variables= {
    ["fusion"]={
        ["counters"]={
            ["remote"]={
                ["plasma_master"]="NULL",
                ["deuterium"]="NULL",
                ["tritium"]="NULL",
            }
        }
    }

}




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
        return "@:"..sType
        --error( "Cannot serialize type "..sType )
        
    end
end

function serialize( t )
    local tTracking = {}
    return serializeImpl( t, tTracking )
end

function BuildArray(...)
  local arr = {}
  for v in ... do
    arr[#arr + 1] = v
  end
  return arr
end

function search_remote(tbl,item)
    local s = serialize(tbl)
    d = http_post("puts.py?type=table&query=item&name="..item,s)
    return d.readAll()
end
function search_local(name)
    local ret = {}
    for k,v in pairs(mECraftingTerminal.getAvailableItems()) do
        local test = string.find(string.lower(v['name']),string.lower(name))
        if test ~= nil then
            table.insert(ret,v)
        end
    end
    function comp(w1,w2)
        -- sort by amount, high to low
        return w1['qty'] > w2['qty']
    end
    table.sort(ret,comp)
    return ret
end


box = bridge.addBox(0,20,180,100, 0x003366,0.75)
txt = bridge.addText(5, 25, "minecraft GLASS", 0xFFFFFF)

--http.request("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(txt))

txt.setScale(2)
--box.setZIndex(0)
--txt.setZIndex(1)

status = bridge.addText(5,45,"Null status", 0xFFFFFF)
--status.setZIndex(1)
status.setScale(0.5)

responses={}

table.insert(responses,bridge.addText(5,55,"Null response1", 0xFFFFFF))
table.insert(responses,bridge.addText(5,65,"Null response2", 0xFFFFFF))
table.insert(responses,bridge.addText(5,75,"Null response3", 0xFFFFFF))
for k,v in pairs(responses) do
    v.setScale(0.8)
    --v.setZIndex(1)
end


power_meters={}
table.insert(power_meters,{bridge.addText(5,82,"Tritium", 0xFF2211),
                         bridge.addText(60,82,"#######", 0xFF2211)
                    })
table.insert(power_meters,{bridge.addText(5,90,"Deuterium", 0xFFFF00),
                         bridge.addText(60,90,"#######", 0xFFFF00)
                    })
table.insert(power_meters,{bridge.addText(5,98,"Plasma", 0xFF9900),
                         bridge.addText(60,98,"#######", 0xFF9900)
                    })
for k,v in pairs(power_meters) do
    --v[1].setZIndex(1)
    --v[2].setZIndex(1)
end

function set_status(text)
  status.setText(tostring(text))
end

function set_response(text1,text2,text3)
    responses[1].setText(text1)
    responses[2].setText(text2)
    responses[3].setText(text3)
end

function display_fusion_counters()
    --[[sends a modem message out to try and get the new numbers (best effort!) displays the current numbers immediately
    ]]
    --set_status(mECraftingTerminal.countOfItemType(constants.items.cobblestone[1],constants.items.cobblestone[2]))
    --[[ --unused, remote system now auto-updates instead
    modem.transmit(constants.channels.fusion_control,
                   constants.channels.me_master,
                   textutils.serialize({["type"]="query",["content"]=""})
                   )
    ]]
    power_meters[1][2].setText(tostring(variables.fusion.counters.remote.tritium))
    power_meters[2][2].setText(tostring(variables.fusion.counters.remote.deuterium))
    power_meters[3][2].setText(tostring(variables.fusion.counters.remote.plasma_master))
    --http_post("puts.py?type=table&query=dump",textutils.serialize({["type"]="query",["content"]=""}))
end



function getEvent()
    --to be moved to adm_base.lua
    local event,p1,p2,p3,p4,p5 = os.pullEvent()
    local t ={ }
    t.type=event
    --base events (no mods...)
    if event == 'char' then
        t.char=p1
    elseif event == 'key' then
        t.key =p1
    elseif event == 'timer' then
        t.timer=p1
    elseif event == 'alarm' then
        t.alarm=p1
    elseif event == 'peripheral' then
        t.side=p1
    elseif event == 'peripheral_detach' then
        t.side=p1
    elseif event == 'rednet_message' then
        t.sender=p1
        t.msg=p2
        t.dist=p3
    elseif event == 'modem_message' then
        t.side=p1
        t.freq=p2
        t.replyFreq=p3
        t.msg=p4
        t.dist=p5
    elseif event == 'chat_command' then
        t.msg = p1
        t.user = p2
    elseif event == 'http_failure' then
        t.url = p1
    elseif event == 'http_success' then
        t.url = p1 --requested URL
        t.res = p2 --response
    else
        print("unkown event type: "..event)
    end
    return t
end
function split(str, pattern) -- Splits string by pattern, returns table
  local t = { }
  local fpat = "(.-)" .. pattern
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

function http_post(url,data)
    --use custom async posting/requesting. the wait for the http to return means we dont get back to os.pullEvent soon enough and miss timers!
    http.request("http://home.admalledd.com:8082/"..url,data)
end

function http_get(url)
    http.request("http://home.admalledd.com:8082/"..url)
end

timers = {fast = os.startTimer(1), quarter = os.startTimer(15),
          half = os.startTimer(15) ,minute=os.startTimer(15)}

http.post("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(fluidTerminal.getAdvancedMethodsData()))
http.post("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(fluidTerminal.getAllStacks()))

while true do 
    event=getEvent()
    if event.type == "chat_command" then
        set_status(event.user..' issued command: "'..event.msg..'"')
        if event.msg == "quit" then
            bridge.clear()
            error("exit called")
        elseif event.msg == "reboot" then
            print("rebooting TGI")
            bridge.clear()
            shell.run("debug")
            error("exit called")
        else
            --assume we are  a multipart command
            t=BuildArray(string.gmatch(event.msg, "%S+"))
            if t[1] == "me" then
                set_response("AE system called","","")
                if t[2] == "lookup" then
                    d=search_local(t[3])
                    local out={}
                    for i = 1,3 do
                        if d[i] then 
                            table.insert(out,d[i]['name'].."=\"$$me get "..d[i]["id"].." "..d[i]["dmg"].. "\"")
                        else
                            table.insert(out,"")
                        end
                    end
                    set_response(out[1],out[2],out[3])
                end
            elseif t[1]== "fu" then
                set_response("Fusion system called!")


            elseif t[1] == "clear" then
                set_response("","","")
            else
                t = table.concat(t, "::")
                set_response('unknown command:"'..t..'"',"","")
            end
        end
    elseif event.type == 'modem_message' then
        --set_status("got modem message!")
        --http_post("puts.py?type=table&query=dump",event.msg)
        event.msg = textutils.unserialize(event.msg)
        if event.msg.type ~= nil then

            --we got a valid message over custom rednet!
            if event.msg.type == "fusion_status" then
                variables.fusion.counters.remote=event.msg.counters
            end
        else
            --unkown message! legacy message?
            print("unkown rednet message! '"..tostring(event.msg).."'")
        end
    elseif event.type == 'timer' then
        if event.timer == timers.fast then
            timers.fast = os.startTimer(0.1)
            --http_post("puts.py?type=table&query=dump",textutils.serialize({"Fusion timer redraw calculating!"}))
            --set_status(tostring(os.time()).."   fusion redraw!")
            display_fusion_counters()
        elseif event.timer == timers.quarter then
            timers.quarter = os.startTimer(15)
        elseif event.timer == timers.half then
            timers.half = os.startTimer(30)
        elseif event.timer == timers.minute then
            timers.minute = os.startTimer(60)
            --http_post("puts.py?type=table&query=dump",serialize(variables))
        else 
            --unknown timer?
            print("unknown TimerID: "..tostring(event.timer))
        end
    end


end