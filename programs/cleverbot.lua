--fname:clever
--version:1.01
--type:program
--name:jarvis
--description: chatbot to entertain with

function sendMsg(data)
 -- send POST
 resp = http.post("http://home.admalledd.com:8082/clever.py",data)
 resp.readLine()
 return resp.readLine()
end
args = {...}
 
if true then
 -- Here you can customize the name and valid delimiters
 local myname = "Jarvis"
 local delimiters = {",", ":", " "}
 -- Chat Box radius
 local radius = 500
 
  -- get message from chat
 local getFromChat = function()
  while true do
   local event, player, message = os.pullEvent("chat")
   --if player == "SR2610" then
    if message:sub(1,6):lower():find(myname:lower()) then
     local min_index = #message
     for a,del in ipairs(delimiters) do
      local i = message:find(del)
      if i and i < min_index then min_index = i end
     end
     if min_index < #message then
      return message:sub(min_index+1)
     end
    end
   end
 
 end
 
 -- or from command line
 local getFromCLI = function()
  return read()
 end
 
 --local bot = Cleverbot.new()
 local sides = {"top","bottom","front","back","left","right"}
 local side = nil
 local get = nil -- function for getting a message from player
 local say = nil -- function for broadcasting the response
 
 -- check for Chat Box
 for i,s in ipairs(sides) do
  if peripheral.getType(s) == "chat" then
   side = s
   break
  end
 end
 
 if side then
  -- found a Chat Box
  print("Found a Chat Box. Switching to voice commands. Address me as "..myname..".")
  local chat = peripheral.wrap(side)
  get = getFromChat
  say = function(message)
   chat.say(myname.."> "..message, radius, true)
  end
 else
  -- default to command line
  print("No Chat Box detected. Using command line.")
  get = getFromCLI
  say = function(message)
   print(myname.."> "..message)
  end
 end
 
 -- main loop
 local m = ""
 while true do
  m = get()
  m = sendMsg(m)
  say(m)
  sleep(0.1)
  end
end

