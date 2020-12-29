--we want the turtle's name, pos+dir to link it up to DB stuffs soo....

-- We should be exec under the context of "Main.lua", and thus have `settings`:
settings = require('settings')
local x,y,z,dir = GlobalPosAPI.getBlockPosition()
pos = {x=x,y=y,z=z,dir=dir}
print('hello from initCommand!')
return {computer_db_key=settings.computer_db_key, pos=pos}