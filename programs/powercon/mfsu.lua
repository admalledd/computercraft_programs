--fname:mfsu
--version:1.01
--type:program
--name:mfsuMON
--description:monitor and broadcast MFSU status


args = { ... }
print("running as MFSU #"..args[1])
 
rednet.open("back")
mfsu = peripheral.wrap("bottom")
 
function getSendPower()
 msg="mfsu:"..args[1]..":" .. mfsu.getStored()
 rednet.broadcast(msg)
 if mfsu.getStored() > 9000000 then
  redstone.setOutput("top",true)
 else
  redstone.setOutput("top",false)
 end
end
while true do
 getSendPower()
 os.sleep(2)
end

