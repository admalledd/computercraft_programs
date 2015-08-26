--fname:bundled
--version:1.01
--type:script
--name:bundle tester
--description:testing bundled cable code

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
        --error( "Cannot serialize type "..sType )
        
    end
end

function serialize( t )
    local tTracking = {}
    return serializeImpl( t, tTracking )
end

function BuildArray(...)
  local arr = {}
  for v in ... do
    arr[#arr + 1] = v
  end
  return arr
end

print("hello world!")

--[[sensor=peripheral.wrap("left")
print(sensor)



http.request("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(sensor))


for k,v in pairs(sensor.getPlayerNames()) do
    print(k,' : ',v)
end
]]

--



for k,peri in ipairs(peripheral.call("back","getNamesRemote")) do
    --print(peri," : ",peripheral.getType(peri))
    local type=peripheral.getType(peri)
    if type == "savedmultipart" then
        cable = peripheral.wrap(peri)
    else
        print("unkown peri: "..type..", at: "..peri)
    end
end
--cable = peripheral.wrap("right")
http.request("http://home.admalledd.com:8082/puts.py?type=table&query=dump&comment=getAdvancedMethodsData()",serialize(cable.getAdvancedMethodsData()))
http.request("http://home.admalledd.com:8082/puts.py?type=table&query=dump&comment=getParts()",serialize(cable.getParts()))
