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
p=peripheral.wrap('terminal_glasses_bridge_0')
if p == nil then
  print("No glasses bridge attached")
  error()
end

p.clear()
for k,v in pairs(p) do print(tostring(k)..":"..tostring(v))end

txt = p.addText(10, 10, "Hello Slowpoke!", 0xFF0000)
txt.setScale(2)
for i=1, 30 do
 txt.setColor(0xFFFFFF * math.random())
 sleep(0.1)
end