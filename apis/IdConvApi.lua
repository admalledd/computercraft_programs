--fname:IdConvApi
--version:1.01
--type:api
--name:ME IDconvAPI
--description:ME bridge uuid mapper

--from:http://www.computercraft.info/forums2/index.php?/topic/15164-miscperipherals-finding-me-bridge-uuid-from-item-name-and-the-reverse/


ItemData = {}
ItemData.mt = {}
ItemData.mt.__tostring = function(data)
        return data.id .. ":" .. data.meta .. "  =>  " .. data.name
end
 
ItemData.create = function (arg)
        local itemdata = {      name = arg.name,
                                tooltip = arg.tooltip,
                                id = arg.id,
                                meta = arg.meta}
        setmetatable(itemdata,ItemData.mt)
        return itemdata
end
 
ItemData.ErrorItemNotFound = function (id,meta)
        local err = "!!Data Not Found for " .. id .. ":" .. meta .. "!!"
        local itemdata = {      name = err,
                                tooltip = err,
                                id = id,
                                meta = meta}
        setmetatable(itemdata,ItemData.mt)
        return itemdata
end
 
 
 
 
IdConv = {}
IdConv.__index = IdConv
 
function IdConv.create(filename)
        local conv = {}             -- our new object
        setmetatable(conv,IdConv)  
        conv.filename=filename
       
        local loaddata = function (filename)
                 -- Load the File
                local fh = fs.open(filename,"r")
                local datafor = {}
                for line in fh.readLine do
                        for idstr, metastr, name, tooltip in string.gmatch(string.lower(line), "(%d-):(%d-) = (.+) = (.+)" ) do
                                local id = tonumber(idstr)
                                local meta = tonumber(metastr)
                               
                                datafor[id] = datafor[id] or {} -- initalise it if it hasn't already been initalised
                                datafor[id][meta] = ItemData.create{ id=id,
                                                                    meta = meta,
                                                                    name = name,
                                                                    tooltip = tooltip,
                                                                    }
                        end
                end
                fh.close()
                return datafor
        end
       
        conv.datafor = loaddata(filename)
       
        return conv
end
 
 
function IdConv:getDataFor(id, meta)
        local idData = self.datafor[id]
        if (idData) then
               
                --Got info about this item,
                local exactItemData = idData[meta]
                if exactItemData then
                        return exactItemData
                else
                        -- Exact meta not matched, pick first on record that has am id
                        -- This is the case for a damaged sword etc
                        local _, firstValue = next(idData)
                        return firstValue
                end
        else
                return ItemData.ErrorItemNotFound(id,meta)
        end
end
 
 ------------- UUID related -----------------
 
function IdConv:getUuid(id,meta)
        return id + meta * 32768
end
 
function IdConv:getFullID(uuid)
        local ret = {}
        if uuid > 32768 then
                ret.id = uuid%32768
                ret.meta = (uuid - ret.id)/32768
        else
                ret.id = uuid
                ret.meta = 0
        end
        return ret
end

