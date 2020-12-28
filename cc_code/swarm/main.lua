
--First thing first: load our settings stuffs, since we will need those jazzyness

local settings = require("settings")

--print('url_base:'..tostring(settings.url_base))
--print('ws_base:'..tostring(settings.ws_base))

-- I am a lazy typing worm:
local je = textutils.serializeJSON
local jd = textutils.unserializeJSON

local function websocketLoop()

    --if we are connecting, assume "clean boot"
	local ws, err = http.websocket("ws://localhost:5000/ws")
	if err then
		print(err)
    elseif ws then
        --on init, send one "hello world" message to begin heartbeat/sanity checking connection group hub
		--ws.send('connecting') --this should be the only "non json" thing we ever send btw (maybe even remove?)
		local reply = function(src_cmd, data)
			--use orig cmd to get nonce (+other if ever needed?) to help sync things back up.
			ws.send(je({data=data, nonce=src_cmd.nonce}))
		end
		while true do
			term.clear()
			term.setCursorPos(1,1)
			print("ADM-Swarm Turtle OS. Do not read my code unless you are 5Head++Ultra.")
			local message = ws.receive()
			if settings.debug then print(message) end
            if message == nil then
                print('nil message, break')
				break
			end
			local cmd = jd(message)
			if cmd.type == 'eval' then
				local ok, res = pcall(function() 
					local func, err = loadstring(cmd['function'])
					if func == nil then error(err) end --allow reply() to capture our typo and tell us we were stupid
					local result = func()
					return result
				end)
				reply(cmd,{ok=ok,res=res})
			elseif cmd.type == 'getpos' then
				if GlobalPosAPI or true then --NB: for now, always assume we have this. if not, we need a LAMA helper on server+turtle which gets iffy.
					local x,y,z,dir = GlobalPosAPI.getBlockPosition()
					pos = {x=x,y=y,z=z,dir=dir}
					ws.send(textutils.serializeJSON(pos))
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
while true do
	--TODO: parallel/async/corutine this and a os.pullEventRaw() loop (since ws.receive() blocks)
	local function paranoid_pcall(closure)
		local ok, res = pcall(closure)
		if res == 'Terminated' then
			print("No u")
			os.reboot()
		end
	end
	paranoid_pcall(websocketLoop)
	print('Something unexpected happened :( having a short nap')
	os.sleep(5)
	os.reboot()
end
