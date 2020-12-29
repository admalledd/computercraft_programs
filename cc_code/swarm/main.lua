
--First thing first: load our settings stuffs, since we will need those jazzyness

local settings = require("settings")

--print('url_base:'..tostring(settings.url_base))
--print('ws_base:'..tostring(settings.ws_base))

-- I am a lazy typing worm:
local je = textutils.serializeJSON
local jd = textutils.unserializeJSON

--dbg helping
local do_mainloop = true
local debug_mainloop = true
-- settings['{key}']='{value}';
-- print(je(settings))

local function websocketLoop()

    --if we are connecting, assume "clean boot"
	local ws, err = http.websocket("ws://localhost:5000/ws")
	if err then
		print(err)
    elseif ws then
		--on init, send one "hello world" message to begin heartbeat/sanity checking connection group hub
		--  this should be the only "non json" thing we ever send btw
		--  (maybe even remove? requires fixing TOFU bug in WebSocketManagerMiddleware.Invoke(), since the OnConnected is before Revieve on that end)
		ws.send(je({type='connecting',computer_db_key=settings.computer_db_key}))
		local reply = function(src_cmd, data)
			--use orig cmd to get nonce (+other if ever needed?) to help sync things back up.
			ws.send(je({data=data, nonce=src_cmd.nonce}))
		end
		term.clear()
		term.setCursorPos(1,1)
		print("ADM-Swarm Turtle OS. Do not read my code unless you are 5Head++Ultra.")
		while true do
			local message = ws.receive()
			if settings.debug then print(message) end
            if message == nil then
                print('nil message, break')
				break
			end
			local cmd = jd(message)
			if cmd.type == 'eval' then
				--{"type":"eval","function":"return 1+1"}
				print(cmd['nonce'])
				local ok, res = pcall(function() 
					local func, err = loadstring(cmd['function'])
					if func == nil then error(err) end --allow reply() to capture our typo and tell us we were stupid
					--inject our environment, to allow API accesses, else things get messy I think real quick
					local env = getfenv()
					setfenv(func, env)
					local result = func()
					return result
				end)
				--make life 500% easier server (strongly-typed) side:
				if ok then reply(cmd,{ok=ok,res=res})
				else reply(cmd,{ok=ok,error=res})
				end
				
			elseif cmd.type == 'getpos' then
				if GlobalPosAPI or true then --NB: for now, always assume we have this. if not, we need a LAMA helper on server+turtle which gets iffy.
					local x,y,z,dir = GlobalPosAPI.getBlockPosition()
					pos = {x=x,y=y,z=z,dir=dir}
					reply(cmd, pos)
				else
					reply(cmd, {x=nil,y=nil,z=nil,dir=nil})
				end
			elseif cmd.type == 'mitosis' then
				--TODO: understand the 5Head of Ottomated
			elseif cmd.type == 'mine' then
				--TODO: understand the 3Head of Ottomated
			else
			end
		end
	end
	if ws then
		ws.close()
    end
end


--try to be basically resilient on keeping a connection, but eventually reboot for clean-slate...
while do_mainloop do
	--TODO: parallel/async/corutine this and a os.pullEventRaw() loop (since ws.receive() blocks)
	local function paranoid_pcall(closure)
		local ok, res = pcall(closure)
		if res == 'Terminated' and not debug_mainloop then
			print("No u")
			os.sleep(0.2) --juuust long enough really
			os.reboot()
		end
		return ok,res
	end
	local ok,res = paranoid_pcall(websocketLoop)
	if debug_mainloop and not ok then
		error(res)
		break
	else
		print('Something unexpected happened :( having a short nap')
		os.sleep(10)
		os.reboot()
	end
end
