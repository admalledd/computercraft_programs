
local positionData = {x=0,y=0,z=0,dir="NORTH"}
_G.GlobalPosAPI = {
    getBlockPosition = function()
        return positionData.x, positionData.y, positionData.z, positionData.dir
    end
}

local settings={}

_G.require = function(pth)
    --"require" is far more complicated than we can support, so we dummy/semi-code whatever instead:
    if pth == "settings" then
        return settings
    end
end

function getDirectionDelta(dir)
    if      dir == "NORTH" then return {0,-1}
    elseif dir == "EAST"  then return {1,0}
    elseif dir == "SOUTH" then return {0,1}
    elseif dir == "WEST"  then return {-1,0}
    end
    return {0,0}
end

_G.turtle = {
    inspectUp = function()
        local ok = true
        --[[
            {
                "state": {} ??,
                "name: "minecraft:stone"
                "tags": {Dictionary<string,object>}
            }
        ]]
        local res = '{"state":{},"name":"minecraft:stone",tags:{}}'
        return ok, res 
    end,
    inspectDown = function()
        local ok = true
        --[[
            {
                "state": {} ??,
                "name: "minecraft:stone"
                "tags": {Dictionary<string,object>}
            }
        ]]
        local res = '{"state":{},"name":"minecraft:stone",tags:{}}'
        return ok, res 
    end,
    inspect = function()
       local ok = true
       --[[
           {
               "state": {} ??,
               "name: "minecraft:stone"
               "tags": {Dictionary<string,object>}
           }
       ]]
       local res = '{"state":{},"name":"minecraft:stone",tags:{}}'
       return ok, res 
    end,
    forward = function()
        local deltas = getDirectionDelta(positionData.dir)
        positionData.x = positionData.x + deltas[0]
        positionData.z = positionData.z + deltas[1]
        return true, nil
    end,
    back = function()
        local deltas = getDirectionDelta(positionData.dir)
        positionData.x = positionData.x - deltas[0]
        positionData.z = positionData.z - deltas[1]
        return true, nil
    end,
    up = function()
        if positionData.y > 250 then
            return false, "too high!"
        end
        positionData.y = positionData.y + 1
        return true, nil
    end,
    down = function()
        if positionData.y == 2 then
            --0== void, 1 == bedrock for this example, close enough~~
            return false, "too low!"
        end
        positionData.y = positionData.y - 1
        return true, nil
    end,
    turnLeft = function()
        if positionData.dir == "NORTH" then
            positionData.dir = "WEST"
        elseif positionData.dir == "EAST" then
            positionData.dir = "NORTH"
        elseif positionData.dir == "SOUTH" then
            positionData.dir = "EAST"
        elseif positionData.dir == "WEST" then
            positionData.dir = "SOUTH"
        else
            local err = "wrong way!"..tostring(positionData.dir)
            print(err)
            return false, err
        end
        return true, nil
    end,
    turnRight = function()
        if positionData.dir == "NORTH" then
            positionData.dir = "EAST"
        elseif positionData.dir == "EAST" then
            positionData.dir = "SOUTH"
        elseif positionData.dir == "SOUTH" then
            positionData.dir = "WEST"
        elseif positionData.dir == "WEST" then
            positionData.dir = "NORTH"
        else
            local err = "wrong way!"..tostring(positionData.dir)
            print(err)
            return false, err
        end 
        return true, nil
    end
}

_G.execProxy = function(cmd)
    --wrap in similar usable manner as LuaCommandModel expects:
    --"{"ok":true,"res":{"pos":{"y":79,"x":120,"z":88}}}"
    local ok, res = pcall(function()
        local func, err = loadstring(cmd['function'])
        if func == nil then error(err) end
        local env = getfenv()
        setfenv(func)
        local result = func()
        return result
    end)
    if ok then return {ok=ok,res=res}
    else return {ok=ok, error=res}
    end
end

--[[

    local b_up = mangleInspect(turtle.inspectUp())
    local b_down = mangleInspect(turtle.inspectDown())
    local b_fwd = mangleInspect(turtle.inspect())
    local x,y,z,dir = GlobalPosAPI.getBlockPosition()
]]
