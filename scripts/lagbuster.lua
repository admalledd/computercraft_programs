--fname:lagbuster
--version:1.05
--type:script
--name:lagbuster tool
--description:reads a TickProfiler file and displays it





local monitorSide = "left"

if peripheral.isPresent(monitorSide) and peripheral.getType(monitorSide) == "monitor" then
  term.redirect(peripheral.wrap(monitorSide))
else
  print("No monitor found")
  return
end

function explode(inSplitPattern, str)
  str = str .. ""
  local outResults = { }
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
  while theSplitStart do
  local sub = string.sub( str, theStart, theSplitStart-1 )
    table.insert( outResults,  sub)
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( str, theStart ) )
  return outResults
end

function printColouredBars(str, first)
  parts = explode("|", str)
  local l = #parts
  for k = 1, l do
    if first then
      term.setTextColor(colors.blue)
    end
    io.write(parts[k])
    if first then
      term.setTextColor(colors.white)
    end
    if k ~= l then
      term.setTextColor(colors.red)
      io.write("|")
      term.setTextColor(colors.white)
    end
  end
end

function profile()
  term.setCursorPos(1, 1)
  local text = http.get("http://127.0.0.1:8082/loader.py?/profile.txt").readAll()
  local tables = explode("\n\n", string.gsub(text, "\r\n", "\n"))
  term.clear()
  local i, j
  for i = 1, #tables do
    lines = explode("\n", tables[i] .. "")
    if #lines == 1 then
      term.setTextColor(colors.green)
      print(lines[1])
      term.setTextColor(colors.white)
    else
      for j = 1, #lines do
        printColouredBars(lines[j] .. "\n", j == 1)
      end
      if i ~= #tables then
        io.write("\n")
      end
    end
  end
end

while true do
  profile()
  sleep(60)
end

term.restore()
