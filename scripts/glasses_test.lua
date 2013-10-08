--fname:glasses_test
--version:1.01
--type:script
--name:glasses tester
--description: check out those terminal glasses!


sides = rs.getSides()
local p
--[[for i, side in pairs(sides) do
  if peripheral.isPresent(side) and peripheral.getType(side) == "terminal_glasses_bridge" then
     p = peripheral.wrap(side)
  end
end]]
p=peripheral.wrap('terminal_glasses_bridge_1')
--p=peripheral.wrap('up')
if p == nil then
  print("No glasses bridge attached")
  error()
end
for k,v in pairs(p.getUsers()) do
    print(k,":",v)
end
p.clear()
--for k,v in pairs(p) do print(tostring(k)..":"..tostring(v))end


txt = p.addText(5, 25, "TGI online", 0xFFFFFF)
box = p.addBox(0,20,180,75, 0x003366,0.75)

txt.setScale(2)
box.setZIndex(0)
txt.setZIndex(1)

status = p.addText(5,45,"Null status", 0xFFFFFF)
status.setZIndex(1)
status.setScale(0.5)

response=p.addText(5,55,"Null response", 0xFFFFFF)
response.setZIndex(1)
function set_status(text)
  status.setText(text)
end

function set_response(text)
  response.setText(text)
end

while true do 
 e,p1,p2,p3,p4,p5 = os.pullEvent()
 if e == "chat_command" then
    set_status(p2..' issued command: "'..p1..'"')
    if p1 == "quit" then
        p.clear()
        return
    elseif p1 == "reboot" then
        print("rebooting TGI")
        p.clear()
        shell.run("debug")
    else
        set_response('unknown command:"'..p1..'"')
    end

 end
 for k,v in pairs({}) do
     print(k," : ",v)
 end
end