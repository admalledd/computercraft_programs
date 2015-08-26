--fname:button
--version:1.05
--type:api
--name:Button API
--description: Button API

--from https://raw.github.com/chuesler/computercraft-programs/master/api/button

local Button = {}
Button.__index = Button

setmetatable(Button, {
   __call = function(cls, ...)
      return cls.new(...)
   end
})

for i, side in pairs(rs.getSides()) do 
   if peripheral.getType(side) == "monitor" then
      local monitor = peripheral.wrap(side)
      if monitor.isColor() then
         Button.monitor = monitor
         break
      end
   end
end

if not Button.monitor then
   error("Button api requires an Advanced Monitor")
end

-- add a new button. colors are optional.
function Button.new(text, callback, xMin, xMax, yMin, yMax, color)
   local self = setmetatable({}, Button)

   self.text = text
   self.callback = callback
   self.x = { min = xMin, max = xMax }
   self.y = { min = yMin, max = yMax }

   self.enabled = true
   self.visible = true

   self.colors = { text = colors.white, background = colors.black, enabled = colors.lime, disabled = colors.red }
   if color ~= nil and type(color) == "table" then
      for k, v in pairs(color) do
         self.colors[k] = v
      end
   end

   -- store button in table for easier click handling
   if Button._buttons ~= nil then 
      table.insert(Button._buttons, self)
   else -- first button being added
      Button["_buttons"] = { self }
   end

   self:display()

   return self
end

function Button:display()
   local color = self.visible and (self.enabled and self.colors.enabled or self.colors.disabled) or self.colors.background

   self.monitor.setBackgroundColor(color)
   self.monitor.setTextColor(self.colors.text)

   local center = math.floor((self.y.min + self.y.max) / 2)

   for j = self.y.min, self.y.max do
      self.monitor.setCursorPos(self.x.min, j)

      if j == center and self.visible then
         local length = self.x.max - self.x.min
         local space = string.rep(" ", (length - string.len(self.text)) / 2)

         self.monitor.write(space)
         self.monitor.write(self.text)
         self.monitor.write(space)

         if string.len(space) * 2 + string.len(self.text) < length then
            self.monitor.write(" ")
         end
      else
         self.monitor.write(string.rep(" ", self.x.max - self.x.min))
      end
   end

   self.monitor.setBackgroundColor(self.colors.background)
end

function Button:enable()
   self.enabled = true
   self:display()
end

function Button:disable()
   self.enabled = false
   self:display()
end

function Button:flash(interval)
   self:disable()
   sleep(interval or 0.15)
   self:enable()
end

function Button:show()
   self.visible = true
   self:display()
end

function Button:hide()
   self.visible = false
   self:display()
end

function awaitClick()
   local event, side, x, y = os.pullEvent("monitor_touch")

   for i, button in pairs(Button._buttons) do
      if button.enabled and button.x.min <= x and button.x.max >= x and button.y.min <= y and button.y.max >= y then
         button.callback(button)
      end
   end
end
function doClick(event)
   --modified for adm_api event handling
   for i, button in pairs(Button._buttons) do
      if button.x.min <= event.x and button.x.max >= event.x and button.y.min <= event.y and button.y.max >= event.y then
         button.callback(button)
      end
   end
end

function setMonitor(monitor)
   if monitor == nil or not monitor.isColor() then
      error("Button api requires an Advanced Monitor")
   end

   Button.monitor = monitor
end

-- remove button from table and thus makes it unclickable. Probably not needed in most cases.
function remove(button)
   if Button._buttons then
      for i, b in pairs(Button._buttons) do
         if button == b then
            table.remove(Button._buttons, i)
            break
         end
      end
   end
end

new = Button.new

