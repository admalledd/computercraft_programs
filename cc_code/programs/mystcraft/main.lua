

--[[
main controller for the DHD turtle part of the mystcraft gate control network

API req: 
    admapi: for event helpers
    button: for the touch monitor
peripherals:
    top: monitor
    left: modem hooked up to diamond chests filled with linking books (peripheral proxies)
edit vars:
    CDIRECTION: direction chest is relative to book receptacle

NOTE:: V1 of MystGate only handles 12 books! (will ignore/crash with any more than that!)
]]




monitor=peripheral.wrap("top") --an advanced monitor, size 6x5

--modem for a network on the left of the computer
chests={}
receptacles={}
for k,peri in ipairs(peripheral.call("left","getNamesRemote")) do
    --print(peri," : ",peripheral.getType(peri))
    local type=peripheral.getType(peri)
    if type == "diamond" then
        print('found chest at: "',peri,'"')
        -- this is a chest with a nearby book receptacle
        table.insert(chests,peripheral.wrap(peri))
    elseif type == "book_receptacle" then
        print('found receptacle at: "',peri,'"')
        table.insert(receptacles,peripheral.wrap(peri))
    else
        print("unkown peri: "..type..", at: "..peri)
    end
end

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
        return "@:"..sType
        --error( "Cannot serialize type "..sType )
        
    end
end

function serialize( t )
    local tTracking = {}
    return serializeImpl( t, tTracking )
end

http.request("http://home.admalledd.com:8082/puts.py?type=table&query=dump",serialize(receptacles[1].getAllStacks()))

--CONSTANTS:::
--chest direction, direction to pull/push items into the book receptacle
CDIRECTION="west"
--receptacle direction, direction to push/pull items to chests
RDIRECTION="east"


--GLOBAL VARS:::
--the table that stores all our locations and which chest/slot they are in
bookdb={}


--GLOBAL FUNCTIONS:::


function find_book(loc)
    --find a book based on its destination string
    local ret = {}
    for index,book in pairs(bookdb) do
        local dest=book[3]
        --print("cmp:'"..loc.."' to '"..dest.."'")
        if dest ~= nil then
            --local test = string.find(string.lower(dest),string.lower(loc))
            --if test ~= nil then
            --    return slot
            --end
            if string.lower(dest) == string.lower(loc) then
                return book
            end
        end
    end
end

function reindex()
    -- re-index the bookdb
    close_portal() --close to make sure we have all ze books
    bookdb={}
    print('indexing...')
    for index,chest in pairs(chests) do
        --ONLY one of a set destination!
        for slot,itemstack in pairs(chest.getAllStacks()) do
            if itemstack['destination'] ~= nil then
                if bookdb[itemstack['destination']] ~= nil then
                    -- already exists in the DB, error out! abort abort! rename!
                    error("duplicated destination name found: "..slot.." dst:"..itemstack['destination'])
                end

                table.insert(bookdb,{chest,slot,itemstack['destination']})
            end
        end
    end
end
function setbooks()
    -- set the display'd books
    for index,btn in pairs(book_btns) do
        btn.text = ""
        btn:display()
    end
    for index,book in pairs(bookdb) do
        if index > #book_btns then break end --sanity check
        book_btns[index].text = book[3]
        book_btns[index]:display()
    end
end

function close_portal() 
    for index,chest in pairs(chests) do
        m=chest.pullItem(RDIRECTION,1)
        if m > 0 then
            print('moved item!')
        else
            print('moved ',m,' items')
        end
        --os.sleep(1)
    end
    print("portal closed")
end
function open_portal(dst)
    --dst is a entry from the bookdb, giving us chest object and slot number

    -- close the portal first, no matter what
    close_portal()
    dst[1].pushItem(CDIRECTION,dst[2],1)
    print("portal opened to '"..dst[3].."'")
    menu.cur.text=dst[3]
    menu.cur:enable()
end


--INIT
--index all available books
reindex()

--set up monitor

--callback for book clicks
function callback_book(btn) 

    print('btn "'..btn.text..'" clicked')
    local book = find_book(btn.text)
    if book ~= nil then
        open_portal(book)
    else
        print("wtf? book was lost!")
    end
end

--callbacks for menu stuff
function callback_close_portal(btn)
    reindex()--will close portal for us
    setbooks()
    menu.cur.text="OFFLINE"
    menu.cur:disable()

end
function callback_prev( ... )
    -- body
end
function callback_next( ... )
    -- body
end
function callback_nil( ... )
    -- body
end

monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextScale(1)
monitor.side="top"
button.setMonitor(monitor)
--b = button.new("Click me!", callback, xMin, xMax, yMin, yMax, color_table)

book_btns={
    -- first column
    button.new("", callback_book, 2, 17, 4,  6),
    button.new("", callback_book, 2, 17, 8,  10),
    button.new("", callback_book, 2, 17, 12, 14),
    button.new("", callback_book, 2, 17, 16, 18),

    -- second column
    button.new("", callback_book, 18, 33, 4,  6),
    button.new("", callback_book, 18, 33, 8,  10),
    button.new("", callback_book, 18, 33, 12, 14),
    button.new("", callback_book, 18, 33, 16, 18),

    -- third column
    button.new("",  callback_book, 34, 50, 4,  6),
    button.new("", callback_book, 34, 50, 8,  10),
    button.new("", callback_book, 34, 50, 12, 14),
    button.new("", callback_book, 34, 50, 16, 18),
}

menu={}
menu.prev  = button.new("prev", callback_prev        ,2 ,10,1,3,{ enabled = colors.blue })
menu.next  = button.new("next", callback_next        ,11,17,1,3,{ enabled = colors.blue })
menu.close = button.new("reset",callback_close_portal,18,25,1,3,{ enabled = colors.red })
--current book in portal, just used. store data about current book in here!
menu.cur   = button.new("OFFLINE",callback_nil       ,26,50,1,3,{ enabled = colors.purple,disabled=colors.gray })
--disable curbook, we have nothing in the gate remember?
menu.cur:disable()

--timers, FIXME unused?
timers = {fast = os.startTimer(1), quarter = os.startTimer(15),
          half = os.startTimer(15) ,minute=os.startTimer(60)}

setbooks()--populate the book listings

print("init of MystGate complete, going to mainloop...")

function main()
    while true do
        event=admapi.getEvent()
        if event.type == "monitor_touch" then
            button.doClick(event)
            --print(event.x,":",event.y)
        elseif event.type == 'timer' then
            if event.timer == timers.fast then
                timers.fast = os.startTimer(3)
            elseif event.timer == timers.quarter then
                timers.quarter = os.startTimer(15)
            elseif event.timer == timers.half then
                timers.half = os.startTimer(30)
            elseif event.timer == timers.minute then
                timers.minute = os.startTimer(60)
            else 
                --unknown timer?
                print("unknown TimerID: "..tostring(event.timer))
            end
        elseif event.type == 'char' then
            if event.char == 'q' then
                error("quit requested")
            elseif event.char == 'r' then
                callback_close_portal("asdf")
            end
        end
    end
end

main()