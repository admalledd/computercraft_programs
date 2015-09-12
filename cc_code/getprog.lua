
-- based on http://pastebin.com/N22T449A# edited with permission for my own uses

--curver @ http://pastebin.com/7aT0cNxZ

Version = 2.01
args = { ... }

--NOTE: hack-patched to support CLINK api for now (until getprog2 is complete...)

if not http then
  print("Herp derp, forget to enable http?")
  return exit
end

proglist="http://localhost:8082/clinker.py?user=admalledd&req=get_file&file=/programlist.ltable"

x,y = term.getSize()
index = 1

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
function printC(text, line, nextline)
  if term.isColor() then
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.yellow)
  end  
  term.setCursorPos((x/2) - (#text/2), line)
  term.write(text)
  if term.isColor() then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
  end
  if nextline then
    term.setCursorPos(1, nextline)
  end
end
function printLine(text, line, nextline)
  if term.isColor() then
    term.setBackgroundColor(colors.blue)
    text = " "
  end  
  term.setCursorPos(1, line)
  term.write(string.rep(text, x))
  if term.isColor() then
    term.setBackgroundColor(colors.black)
  end
  if nextline then
    term.setCursorPos(1, nextline)
  end
end
function printOnce(text, line, nextline)
  if term.isColor() then
    term.setBackgroundColor(colors.cyan)
  end  
  term.setCursorPos(1, line)
  term.clearLine()
  term.write(text)
  if term.isColor() then
    term.setBackgroundColor(colors.black)
  end
  if nextline then
    term.setCursorPos(1, nextline)
  end
end
function print_proglist(pnames)
  --[[
  print a list  of programs (7 in all), rewriting those lines as needed
  this is to allow selection scrolling and such
  ]]
  for i=0,6  do
    if pname[i+index] then
      if i == 0 then
        printOnce("* ["..i+index.."]".." "..pname[i+index],i+5)
      else  
        printOnce("  ["..i+index.."]".." "..pname[i+index],i+5)
      end
    else
      printOnce("",i+5)
    end
  end
  printOnce("Desc: "..cat[programs[index]].Description,13)

end

x,y = term.getSize()
 
term.clear()
printLine("-", 1)
printC(" admalledd Retriever "..tostring(Version).." ", 1, 3)
 
write("-> Grabbing file...")
cat = getUrlFile(proglist)
cat = textutils.unserialize(cat)
write(" Done.")
 
term.setCursorPos(1,5)
 
programs = {}
pname = {}
for name,data in pairs(cat) do
  table.insert(pname, data.Name .." ".. data.Version)
  table.insert(programs, name)
end

print_proglist(pname)

print("\n\nPress Enter on the keyboard to download the selected program. Or press 'Q' to exit.")

while true do

  event, p1 = os.pullEvent()
  if event == 'char' then
    print("\n\n\n\n\nExiting...")
    return
    
  elseif event == 'key' then
    if p1 == 200 then
      index = index-1
      if index < 1 then index = 1 end
    elseif p1 == 208 then
      index = index + 1
      if index > #pname then index = #pname end
    elseif p1 == keys.enter or p1 == keys.numPadEnter then
      if programs[index] then
        term.setCursorPos(1,17)
        print("Selected: "..programs[index])
        program = getUrlFile(cat[programs[index]].GitURL)
        writeFile(programs[index], program)
        print("\nDownloaded "..programs[index])
        if cat[programs[index]].Type == "program" then
          print("You can run it by typing: "..programs[index])
        elseif cat[programs[index]].Type == "installer" then
          print("this program needs installing, running installer...")
          shell.run(programs[index].." install "..proglist)
        end
        print("Thanks for using admalledd Retriever!")
        print("\nExiting...")
        return
      end
      
    end
    -- assume change in display, redraw...
    print_proglist(pname)
  end

end
