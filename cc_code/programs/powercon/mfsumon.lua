--fname:mfsumon
--version:1.01
--type:script
--name:MFSU-mon
--description:display info on connected MFSUs



mon = peripheral.wrap("left")
mon.clear()
mon.setCursorPos(1,1)
mon.setTextScale(0.5)


modem = peripheral.wrap("back")

mfsus={}

for k,peri in ipairs(modem.getNamesRemote()) do
    local type=peripheral.getType(peri)
    if type == 'batbox' then
        --an MFSU...
        print("found batbox peri:"..peri)
        table.insert(mfsus,peripheral.wrap(peri))
    else
        print("unkown peri: "..type..", at: "..peri)
    end
end

function writePercent()
    --write per line the % of the MFSUs attached (no wrapping calculations are done, may overflow monitor)
    for i,v in ipairs(mfsus) do
        local max = v.getCapacity()
        local cur = v.getStored()
        local per = ((math.floor((cur/max)*10000))/100)
        mon.setCursorPos(1,i)
        mon.write("mfsu"..tostring(i)..":"..tostring(per).."%")
    end
    mon.setCursorPos(1,#mfsus+1)
    mon.write("total mfsu power:"..tostring(getStored()))
    mon.setCursorPos(1,#mfsus+2)
    mon.write("total percent:"..tostring(((math.floor((getStored()/getCapacity())*10000))/100)).."%")

end

function getStored()
    --get total stored EU in bank
    local total_cur =0
    for i,v in ipairs(mfsus) do
        total_cur=total_cur+v.getStored()
    end
    return total_cur
end
function getCapacity()
   --get total EU capacity in bank
    local total_max =0
    for i,v in ipairs(mfsus) do
        total_max=total_max+v.getCapacity()
    end
    return total_max
end

while true do
    writePercent()
    local p = getStored()
    sleep(1)
    mon.clear()
    local n = getStored()
    mon.setCursorPos(1,#mfsus+3)
    mon.write(n-p) 
end