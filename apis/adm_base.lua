--fname:admapi
--version:1.21
--type:api
--name:adm_base API
--description: Base API for most programs here


-- base API for all admalledd's programs.
-- includes mostly just basic functions
-- again borrowed with permission from http://github.com/darkrising/darkprograms/


--Generalised functions
function findPeripheral(Perihp) -- returns side of first peripheral matching passed string
  for _,s in ipairs(rs.getSides()) do
    if peripheral.isPresent(s) and peripheral.getType(s) == Perihp then
      return s
    end
  end
  return false
end
function listPeripheral() -- returns a table of peripherals names, false if nothing found
  local typers = {}
  for _,s in ipairs(rs.getSides()) do
    if peripheral.isPresent(s) then 
      table.insert(typers,peripheral.getType(s))
    end
  end
  if #typers > 0 then
    return typers
  else
    return false
  end
end
function listRemotePeripheral(side)-- returns a table of REMOTE peripherals attached via modem
  -- side is side of modem
  local typers = {}
  for _,s in ipairs(peripheral.call(side,"getNamesRemote")) do
    if peripheral.isPresent(s) then 
      table.insert(typers,peripheral.getType(s))
    end
  end
  if #typers > 0 then
    return typers
  else
    return false
  end
end
function listRemotePeripheralNames(side)-- returns a table of REMOTE peripheral names attached via modem
  -- side is side of modem
  local names = peripheral.call(side,"getNamesRemote")
  if #names > 0 then
    return names
  else
    return false
  end
end
function printTable(t)
  for k,v in pairs(t) do
    print(k," : ",v)
  end
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
function getPBFile(PBCode, uPath) -- pastebin code of the file, and path to save /turkey
  local PBfile = http.get("http://pastebin.com/raw.php?i="..textutils.urlEncode(PBCode))
  if PBfile then
    local PBfileToWrite = PBfile.readAll()
      PBfile.close()
          
      local file = fs.open( uPath, "w" )
    file.write(PBfileToWrite)
      file.close()
    return true
  else
    return false
  end
end
function gitUpdate(ProgramName, Filename, ProgramVersion)
  if http then
    local getGit = http.get("https://raw.github.com/admalledd/computercraft_programs/master/programlist")
    local getGit = getGit.readAll()
    NVersion = textutils.unserialize(getGit)
    if NVersion[ProgramName].Version > ProgramVersion then
      getGit = http.get(NVersion[ProgramName].GitURL)
      getGit = getGit.readAll()
      local file = fs.open(Filename, "w")
      file.write(getGit)
      file.close()
      return true
    end
  else
    return false
  end
end

--Common Draw functions I use
function cs() -- lazy man's screen clear
  term.clear()
  term.setCursorPos(1,1)
  return
end
function setCol(Color, BkgColor)
  if ((term.isColor) and (term.isColor() == true)) then
    if Color then term.setTextColor(colors[Color]) end
    if BkgColor then term.setBackgroundColor(colors[BkgColor]) end
  else
    return
  end
end
function resetCol(Color, BkgColor)
  if ((term.isColor) and (term.isColor() == true)) then
    if Color then term.setTextColor(colors.white) end
    if BkgColor then term.setBackgroundColor(colors.black) end
    return
  else
    return
  end
end
function printC(Text, Line, NextLine, Color, BkgColor) -- print centered
  local x, y = term.getSize()
  x = x/2 - #Text/2
  term.setCursorPos(x, Line)
  if Color then setCol(Color, BkgColor) end
  term.write(Text) 
  if NextLine then
    term.setCursorPos(1, NextLine) 
  end
  if Color then resetCol(Color, BkgColor) end
  return true  
end
function printL(Text, Line, NextLine, Color, BkgColor) -- print line
  local x, y = term.getSize()
  if ((term.isColor) and (term.isColor() == false) and (Text == " ")) then Text = "-" end
  for i = 1, x do
    term.setCursorPos(i, Line)
    if Color then setCol(Color, BkgColor) end
    term.write(Text)
  end
  if NextLine then  
    term.setCursorPos(1, NextLine) 
  end
  if Color then resetCol(Color, BkgColor) end
  return true  
end
function printA(Text, xx, yy, NextLine, Color, BkgColor) -- print anywhere
  term.setCursorPos(xx,yy)
  if Color then setCol(Color, BkgColor) end
  term.write(Text)
  if NextLine then  
    term.setCursorPos(1, NextLine) 
  end
  if Color then resetCol(Color, BkgColor) end
  return true  
end
function clearLine(Line, NextLine) -- May seem a bit odd, but it may be usefull sometimes
  local x, y = term.getSize()
  for i = 1, x do
    term.setCursorPos(i, Line)
    term.write(" ")
  end  
  if not NextLine then  
    x, y = term.getCursorPos()
    term.setCursorPos(1, y+1) 
  end
  return true  
end
function drawBox(StartX, lengthX, StartY, lengthY, Text, Color, BkgColor) -- does what is says on the tin.
  local x, y = term.getSize()
  if Color then setCol(Color, BkgColor) end
  if not Text then Text = "*" end
  lengthX = lengthX - 1 
  lengthY = lengthY - 1
  EndX = StartX + lengthX  
  EndY = StartY + lengthY
  term.setCursorPos(StartX, StartY)
  term.write(string.rep(Text, lengthX))
  term.setCursorPos(StartX, EndY)
  term.write(string.rep(Text, lengthX)) 
  for i = StartY, EndY do
    term.setCursorPos(StartX, i)
    term.write(Text)
    term.setCursorPos(EndX, i)    
    term.write(Text)
  end
  resetCol(Color, BkgColor)
  return true  
end

peri={}
function setPeri(name,p)
  peri[name]=p
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
    elseif event == 'redstone' then
        --no parms
    elseif event == 'disk' then
        t.side=p1
    elseif event == 'disk_eject' then
        t.side=p1
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
    elseif event == 'http_success' then
        t.url = p1
        t.reply = p2
    elseif event == 'http_failure' then
        t.url = p1
    elseif event == 'mouse_click' then
        t.button=p1
        t.x=p2
        t.y=p3
    elseif event == 'mouse_scroll' then
        t.direction=p1
        t.x=p2
        t.y=p3
    elseif event == 'mouse_drag' then
        t.button=p1
        t.x=p2
        t.y=p3
    elseif event == 'monitor_touch' then
        t.side=p1
        t.x=p2
        t.y=p3
    elseif event == 'monitor_resize' then
        t.side=p1
    elseif event == 'turtle_inventory' then
        t.side=p1


    --unofficial / non standard events
    elseif event == 'energy_measure' then
        --admapi.printTable(p1)
        local dtime = os.clock()-peri.meter.startTime
        peri.meter.startTime = os.clock()
        local deu = p1.total-peri.meter.lastTotal
        peri.meter.lastTotal=p1.total
        --meter.startTime=os.clock()
        p1.type=event
        p1.eut=(deu/(dtime*40))
        t=p1

    else
        print("unkown event type: "..event)
        admapi.printTable({p1,p2,p3,p4,p5})
    end
    return t
end
