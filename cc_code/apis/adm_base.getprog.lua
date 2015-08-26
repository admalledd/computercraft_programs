--fname:admapi
--version:1.25
--type:api
--name:adm_base API
--description: Base API for most programs here


-- base API for all admalledd's programs.
-- includes mostly just basic functions
-- again borrowed with permission from http://github.com/darkrising/darkprograms/


version=1.22

-- set functions to set API internals (debug stuff, settings, peripherals...)
peri={}
function setPeri(name,p)
  peri[name]=p
end
settings={}
function setSetting(name,val)
  settings[name]=val
end



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

function dump(tbl)
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
            return "@"..sType
            --pass to allow dumping of anything...
            --error( "Cannot serialize type "..sType )
            
        end
    end

    local function serialize( t )
        local tTracking = {}
        return serializeImpl( t, tTracking )
    end
    --debug helper. POST tbl to server to have it recursivly dumped and parsed, good for large tables
    http.post("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(tbl))
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

--http stuff
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

function getProgList()
  if settings.debug then
    if http.get("http://127.0.0.1:8082/loader.py?/programlist.ltable") then
      --check for local dev server, if not use phone-home dev server...
      proglist="http://127.0.0.1:8082/loader.py?/programlist.ltable"
    else
      proglist="http://home.admalledd.com:8082/loader.py?/programlist.ltable"
    end
  else
    proglist="https://raw.github.com/admalledd/computercraft_programs/master/programlist.ltable"
  end
  local cat = getUrlFile(proglist)
  cat=textutils.unserialize(cat)
  return cat
end

function loadAPI(api)
  -- tries to load a api, if it cant find it download it. if debugging, redownload and reload
  if fs.exists(api) == false or settings.debug then
    gitUpdate(api,api,0)--force download
    os.unloadAPI(api)--doesnt hurt ever, just nil's out if non-existant
  end
  os.loadAPI(api)
end


function getUrlFile(url)
  local mrHttpFile = http.get(url)
  --if its failing here, check that the .ltable points to the correct server for dev work...
  mrHttpFile = mrHttpFile.readAll()
  return mrHttpFile
end
function writeFile(filename, data)
  local file = fs.open(filename, "w")
  file.write(data)
  file.close()
end

function gitUpdate(ProgramName, Filename, ProgramVersion)
  if http then
    NVersion = getProgList()
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
        p1.getEUT=function ( meter )
          if p1.eut == nil then            
            local dtime = os.clock()-meter.startTime
            meter.startTime = os.clock()
            local deu = p1.total-meter.lastTotal
            meter.lastTotal=p1.total
            p1.eut=(deu/(dtime*40))
          end
          return p1.eut
        end
        --meter.startTime=os.clock()
        p1.type=event
        t=p1

    else
        print("unkown event type: "..event)
        admapi.printTable({p1,p2,p3,p4,p5})
    end
    return t
end
