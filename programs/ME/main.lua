

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
        error( "Cannot serialize type "..sType )
        
    end
end

function serialize( t )
    local tTracking = {}
    return serializeImpl( t, tTracking )
end



function search_remote(tbl,item)
    local s = serialize(tbl)
    d = http.post("http://home.admalledd.com:8082/puts.py?type=table&query=item&name="..item,s)
    return d.readAll()
end
function search_local(tbl,name)
    local ret = {}
    for k,v in pairs(tbl) do
        local test = string.find(string.lower(v['name']),string.lower(name))
        if test ~= nil then
            table.insert(ret,v)
        end
    end
    return ret
end


mECraftingTerminal=peripheral.wrap("right")

print(mECraftingTerminal.listMethods())

print(mECraftingTerminal.getTotalBytes())
print(mECraftingTerminal.getFreeBytes())

print(mECraftingTerminal.getRemainingItemTypes())


tableInfo = mECraftingTerminal.getAvailableItems()
--[[
d= search_local(tableInfo, "diamond")

for k,v in pairs(d) do
    print(v['name'], " gcmd:\"$$ae get "..v["id"].." "..v["dmg"].. "\"")
end
--]]