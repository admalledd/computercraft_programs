
--NB: should this be in a common swarm file? used whenever things are done?
local function inspectPos()
    local function mangleInspect(ok, res)
        if ok then
            return {{ok=ok,res=res}}
        else 
            return {{ok=ok,error=res}}
        end
    end
    if not turtle then
        error('cannot inspect when not a turtle')
        --if turtle is missing, for inspect we need a dummy:
        -- NB: this breaks global scope is only way, so meh, error instead I guess for now?
        -- local dummyFunc = function() return false,'not a turtle' end
        -- turtle = {
        --     -- normal return of inspect in err is false,"reason"
        --     inspect = dummyFunc, inspectUp = dummyFunc, inspectDown = dummyFunc
        -- }
    end
    local b_up = mangleInspect(turtle.inspectUp())
    local b_down = mangleInspect(turtle.inspectDown())
    local b_fwd = mangleInspect(turtle.inspect())
    local x,y,z,dir = GlobalPosAPI.getBlockPosition()
    local pos = {{x=x,y=y,z=z,dir=dir}}
    return {{up=b_up,down=b_down,forward=b_fwd,pos=pos}}
end

return inspectPos