local windows = {}
local drawable = require("NtUI.drawable")
local eventlib = require("NtUI.BunnyEventLib")
local nineslice = require("NtUI.nineslice")

local click = keybinds:newKeybind("Click", "key.mouse.left", true)

---@class NtUI.Window : NtUI.Drawable
---@field _pos Vector2
---@field _size Vector2
---@field events = {DELETE: Event}
---@field nineslice NtUI.Nineslice
---@field children NtUI.Drawable[]
local window = {}

local texture = textures["NtUI.theme"]

---Creates a new window
---@param pos Vector2
---@param size Vector2
---@return NtUI.Window
function window.new(pos, size)
   local new = setmetatable({}, {
      __index = function(self, key)
         return window[key] or drawable[key]
      end,
      __type = "NtUI.Window"
   })

   windows[#windows + 1] = new

   new._pos = pos
   new._size = size

   new.events = eventlib.newEvents()
   new.events.DELETE = eventlib.newEvent()
   new.children = {}

   new.nineslice = nineslice.new(texture, vec(5, 0), vec(18, 22), 9, 8, #windows * 3):pos(pos):size(size)

   return new
end

function window:draw(parent, pos)
   for _, v in pairs(self.children) do
      v:draw(self, self._pos + pos)
   end
end

function window:addChild(child)
   self.children[#self.children + 1] = child
   self:draw(nil, self._pos / -client.getGuiScale())
end

function window:pos(pos)
   self._pos = pos
   self.nineslice:pos(pos)
end

local mousePos = client.getMousePos() / client.getGuiScale()
local oldMousePos = client.getMousePos() / client.getGuiScale()
function events.RENDER()
   oldMousePos = mousePos
   mousePos = client.getMousePos() / client.getGuiScale()

   local mouseDelta = mousePos - oldMousePos

   for k, v in pairs(windows) do
      local relativeMousePos = oldMousePos - v._pos
      
      if relativeMousePos.x < 1 or relativeMousePos.x > v._size.x - 1 then
         goto continue
      elseif relativeMousePos.y < 1 or relativeMousePos.y > 8 then
         goto continue
      elseif not click:isPressed() then
         goto continue
      end

      if relativeMousePos.x > v._size.x - 9 and relativeMousePos.x < v._size.x - 2 then
         windows[k] = nil
         v:remove()
         v.events.DELETE:fire()

         for _, w in pairs(v.nineslice.tasks) do
            w:remove()
         end

         goto continue
      end

      v:pos(v._pos + mouseDelta)
      v:draw(v, vec(0, 0))

      ::continue::
   end
end

return window

