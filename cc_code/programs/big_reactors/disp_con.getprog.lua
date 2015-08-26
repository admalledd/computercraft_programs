--fname:bg_basic
--version:1.01
--type:program
--name:ReactorCon Basic
--description:Basic BigReactor controller

--Shamelessly "borrowed" from http://pastebin.com/hkVB4B1a

print('ReactorControl Engaged. View Monitor.')

emptyflag=0
offlineflag=0
flashflag=0

reactor=peripheral.wrap('back')
--Expects monitor to be a advanced monitor array 4x3
monitor=peripheral.wrap('right')
 
monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
 
while true do
monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextColor(colors.white)
monitor.write('Fuel Level:')
monitor.setCursorPos(1,2)
monitor.setTextColor(colors.yellow)
monitor.write(math.floor(((reactor.getFuelAmount()/reactor.getFuelAmountMax())*100)+0.5)..'% Fuel')
monitor.setCursorPos(1,3)
monitor.setTextColor(colors.lightBlue)
monitor.write(math.floor(((reactor.getWasteAmount()/reactor.getFuelAmountMax())*100)+0.5)..'% Waste')
monitor.setCursorPos(1,5)
monitor.setTextColor(colors.white)
monitor.write('Control Rod Levels:')
monitor.setTextColor(colors.green)
monitor.setCursorPos(1,6)
monitor.write('Rod 1:  '..(100-(reactor.getControlRodLevel(0)))..'% Depth')
monitor.setCursorPos(1,7)
monitor.write('Rod 2:  '..(100-(reactor.getControlRodLevel(1)))..'% Depth')
monitor.setCursorPos(1,8)
monitor.write('Rod 3:  '..(100-(reactor.getControlRodLevel(2)))..'% Depth')
monitor.setCursorPos(1,9)
monitor.write('Rod 4:  '..(100-(reactor.getControlRodLevel(3)))..'% Depth')
monitor.setCursorPos(1,10)
monitor.write('Rod 5:  '..(100-(reactor.getControlRodLevel(4)))..'% Depth')
monitor.setCursorPos(1,12)
monitor.setTextColor(colors.white)
monitor.write('Temperature:')
monitor.setCursorPos(1,13)
monitor.setTextColor(colors.lightGray)
monitor.write('Casing: ')
if reactor.getCasingTemperature()>=650 then
    monitor.setTextColor(colors.purple)
    else if reactor.getCasingTemperature()>=950 then
        monitor.setTextColor(colors.red)
    else
    monitor.setTextColor(colors.green)
    end
end
monitor.write(reactor.getCasingTemperature()..'C')

monitor.setCursorPos(1,14)
monitor.setTextColor(colors.yellow)
monitor.write('Fuel: ')
if reactor.getFuelTemperature()>=650 then
  monitor.setTextColor(colors.purple)
  else if reactor.getFuelTemperature()>=950 then
    monitor.setTextColor(colors.red)
  else
 monitor.setTextColor(colors.green)
  end
end
monitor.write(reactor.getFuelTemperature()..'C')

monitor.setCursorPos(1,16)
monitor.setTextColor(colors.white)
monitor.write('Flux:')
monitor.setCursorPos(1,17)
monitor.setTextColor(colors.green)
monitor.write(reactor.getEnergyStored()..' RF Stored      ')

if reactor.getEnergyProducedLastTick()>=500 and reactor.getEnergyProducedLastTick()<2000 then
    monitor.setTextColor(colors.orange)
end

if reactor.getEnergyProducedLastTick()>=2000 then
    monitor.setTextColor(colors.red)
end
monitor.write((math.floor(reactor.getEnergyProducedLastTick()+0.5))..'RF/t')

monitor.setCursorPos(1,19)
monitor.setTextColor(colors.orange)
monitor.write('Warnings:')

if flashflag==0 then
  flashflag=1
  if offlineflag==1 then
    monitor.setCursorPos(1,20)
    monitor.setTextColor(colors.lightGray)
    monitor.write('OFFLINE - Manual Override')
  end
  if emptyflag==1 then
    monitor.setCursorPos(1,20)
    monitor.setTextColor(colors.pink)
    monitor.write('OFFLINE - Fuel Exhausted')
  end
  if emptyflag==0 and offlineflag==0 and reactor.getControlRodLevel(0)>75 then
    monitor.setCursorPos(1,20)
    monitor.setTextColor(colors.yellow)
    monitor.write('ONLINE - Low Power Mode')
  end
  if emptyflag==0 and offlineflag==0 and reactor.getControlRodLevel(0)<=75 then
    monitor.setCursorPos(1,20)
    monitor.setTextColor(colors.orange)
    monitor.write('ONLINE - High Power Mode')
  end
else
  flashflag=0
  monitor.setCursorPos(1,20)
  monitor.clearLine()
end

if reactor.getEnergyStored()<=10000000 and reactor.getEnergyStored()>100 then
    reactor.setAllControlRodLevels(0+(math.floor(reactor.getEnergyStored()/100000)))
else
    reactor.setAllControlRodLevels(0)
end
 
if reactor.getFuelAmount()<=100 and offlineflag==0 then
    reactor.setAllControlRodLevels(100)
    reactor.setActive(false)
    emptyflag=1
else
    emptyflag=0
end
      
if rs.getInput('bottom')==false and emptyflag==0 then
    reactor.setActive(true)
    offlineflag=0
end
  
if rs.getInput('bottom')==true and emptyflag==0 then
    reactor.setActive(false)
    reactor.setAllControlRodLevels(100)
    offlineflag=1
end    
sleep(1)
end