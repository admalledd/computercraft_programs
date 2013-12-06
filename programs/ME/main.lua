

--[[
setup:::
left: projectRed cable bundle
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



mECraftingTerminal=peripheral.wrap("right")

bridge=peripheral.wrap('bottom')
--p=peripheral.wrap('up')
if p == nil then
  --print()
  error("No glasses bridge attached")
end
for k,v in pairs(bridge.getUsers()) do
    print(k,":",v)
end
bridge.clear()


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
        error( "Cannot serialize type "..sType )
        
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
    d = http.post("http://home.admalledd.com:8082/puts.py?type=table&query=item&name="..item,s)
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



--print(mECraftingTerminal.listMethods())

--print(mECraftingTerminal.getTotalBytes())
--print(mECraftingTerminal.getFreeBytes())

--print(mECraftingTerminal.getRemainingItemTypes())


--tableInfo = mECraftingTerminal.getAvailableItems()
--[[
d= search_local("diamond")

for k,v in pairs(d[1]) do
    print(k," : ",v)
end
--]]

--for k,v in pairs(p) do print(tostring(k)..":"..tostring(v))end


txt = bridge.addText(5, 25, "TGI online", 0xFFFFFF)
box = bridge.addBox(0,20,180,75, 0x003366,0.75)

txt.setScale(2)
box.setZIndex(0)
txt.setZIndex(1)

status = bridge.addText(5,45,"Null status", 0xFFFFFF)
status.setZIndex(1)
status.setScale(0.5)

responses={}

table.insert(responses,bridge.addText(5,55,"Null response1", 0xFFFFFF))
table.insert(responses,bridge.addText(5,65,"Null response2", 0xFFFFFF))
table.insert(responses,bridge.addText(5,75,"Null response3", 0xFFFFFF))
for k,v in pairs(responses) do
    v.setScale(0.8)
    v.setZIndex(1)
end
--response.setZIndex(1)
function set_status(text)
  status.setText(text)
end

function set_response(text1,text2,text3)
    responses[1].setText(text1)
    responses[2].setText(text2)
    responses[3].setText(text3)
end

while true do 
 e,p1,p2,p3,p4,p5 = os.pullEvent()
 if e == "chat_command" then
    set_status(p2..' issued command: "'..p1..'"')
    if p1 == "quit" then
        bridge.clear()
        return
    elseif p1 == "reboot" then
        print("rebooting TGI")
        bridge.clear()
        shell.run("debug")
        error("exit called")
    else
        --assume we are  a multipart command
        t=BuildArray(string.gmatch(p1, "%S+"))
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

        elseif t[1] == "clear" then
            set_response("","","")

        elseif t[1] == "rs" then
            set_response("testing cable bundle...","","")
            redstone.setOutput("left",true)
            sleep(1)
            redstone.setOutput("left",false)

        else
            t = table.concat(t, "::")
            set_response('unknown command:"'..t..'"',"","")
        end
    end

 end
 for k,v in pairs({}) do
     print(k," : ",v)
 end
end