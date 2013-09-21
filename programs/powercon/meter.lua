--fname:meter
--version:1.01
--type:program
--name:EUmeter
--description:display EU usage

meter = peripheral.wrap("right")
meter.stop()
os.sleep(0.5)
meter.start()
mon = peripheral.wrap("top")
mon.clear()
mon.setCursorPos(1,1)
mon.setTextScale(1)
 
function timedGet()
 meter.stop()
 os.sleep(0.01)
 
 local starttime=os.clock()
 meter.start()
 e,msg = os.pullEvent("energy_measure")
 local dtime = os.clock() - starttime
 
 mon.setCursorPos(1,1)
 mon.clearLine()
 mon.write("mains status:")
 mon.setCursorPos(1,2)
 mon.clearLine()
 mon.write("delta-time: ".. dtime .. " s")
 mon.setCursorPos(1,3)
 mon.clearLine()
 mon.write("EU: " .. msg.total)
 mon.setCursorPos(1,4)
 mon.clearLine()
 local eut = msg.total/(dtime*40)
 mon.write("EU/t:" .. eut)
end
 
 
 
function loopy()
 while true do
  event,message = os.pullEvent()
  print("event:"..event)
  if event == "energy_measure" then
   --mon.clear()
   local curline = 1
   for k,v in pairs(message) do
    print(k..":"..tostring(v))
    mon.setCursorPos(1,curline)
    mon.clearLine()
    mon.write(k..":"..v)
    curline = curline + 1
   end
  end
 end
end
 
while true do
 timedGet()
 --loopy()
end

