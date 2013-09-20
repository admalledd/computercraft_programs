local function checkFuel()
  if turtle.getFuelLevel() < 20 then
    turtle.select(1)
    turtle.refuel(1)
  end
end

local function empty()
  turtle.turnLeft()
  turtle.turnLeft()
  for i=1,15 do
   turtle.select(i)
   turtle.drop()
  end
  turtle.turnRight()
  turtle.turnRight()

while true do
 if turtle.detect() then
  turtle.dig()
  checkFuel()
 end
 if turtle.getItemCount(15) > 32 then
  empty()
 end
end
