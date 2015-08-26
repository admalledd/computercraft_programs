--fname:hvcalc
--version:1.01
--type:script
--name:HV solar calc
--description:calculate resources for HV solars

-- os.loadAPI("IdConvApi")
-- local converter = IdConvApi.IdConv.create("ItemDump.txt")
-- local meBridge=peripheral.wrap("left")
-- local items = meBridge.listItems()
-- --Prints out the current contents of ME system
-- for uuid, qty in pairs(items) do
--     if uuid~=nil then
--         local idData = converter:getFullID(uuid)
--         local id = idData.id
--         local meta = idData.meta

--         local itemData = converter:getDataFor(id,meta)
--         print(qty .."x  " .. itemData.name)

--     end
-- end

--exit()

print("how many HV solars do you want to make?")
num = tonumber(read())

mon=peripheral.wrap("right")
mon.clear()
mon.setTextScale(0.5)
mon.setCursorPos(1,1)
term.redirect(mon)
--iron multiplier: how much iron per solar?
--machineblocks: 512+8+1
--iron-->forceingots (1024 ingots needed) 1024
iron_mul = (512+8+1)*8+683
print("refined Iron:"..tostring(num*iron_mul))
print("machineblocks/furnaces/batteries:"..tostring(num*512))
print("cobble:"..tostring(num*512*8))
print("glass/coal dust:"..tostring(num*512*3))
print("circiuts:"..tostring(num*1024))


--wire: 6 per 2 circuits, 1 per battery, 2 per transformer
wire_mul=num*1024*3+num*512+(num/32)
print("wire/rubber:"..tostring(wire_mul))

--copper: wire+LV transformer
--3 per 6 wire
print("copper:"..tostring(wire_mul/2))


--tin: 4 per battery
print("tin:"..tostring(num*512*4))

--redstone: 1 per two circuits,2 per battery
print("redstone:"..tostring(num*512*3))

term.restore()


