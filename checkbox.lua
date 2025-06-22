local checkboxes = {}
local drawable = require("NtUI.drawable")
local eventlib = require("NtUI.BunnyEventLib")
local nineslice = require("NtUI.nineslice")
local label = require("NtUI.label")

local click = keybinds:newKeybind("Click", "key.mouse.left", true)

local texture = textures["NtUI.theme"]

---@class NtUI.Checkbox : NtUI.Drawable
---@field _pos Vector2
---@field _size Vector2
---@field parentPos Vector2
---@field events {PRESSED: Event}
---@field nineslice NtUI.Nineslice
---@field children NtUI.Drawable[]
---@field check SpriteTask
---@field checked boolean
---@field z_index integer
local checkbox = {}

local texture = textures["NtUI.theme"]

local spriteIter = 0
local model = models:newPart("NtUI.Checks", "HUD")

---Creates a new checkbox
---@param pos Vector2
---@param z_index integer
---@param checked boolean
---@return NtUI.Checkbox
function checkbox.new(pos, z_index, checked)
   local new = setmetatable({}, {
      __index = function(self, key)
         return checkbox[key] or drawable[key]
      end,
      __type = "NtUI.Checkbox"
   })

   checkboxes[#checkboxes + 1] = new

   new._pos = pos
   new._size = vec(9, 9)

   new.events = eventlib.newEvents()
   new.events.PRESSED = eventlib.newEvent()
   new.check = model:newSprite(tostring(spriteIter)):setTexture(texture, texture:getDimensions():unpack()):uvPixels(0, 16):region(5, 5):size(5, 5):setVisible(checked)
   new.children = {new.label}
   new.parentPos = vec(0, 0)
   new.checked = checked
   new.z_index = z_index
   new.nineslice = nineslice.new(texture, vec(0, 10), vec(5, 5), 2, 2, z_index):pos(pos):size(new._size)

   spriteIter = spriteIter + 1

   return new
end

function checkbox:draw(parent, pos)
   self.parentPos = pos
   self.nineslice:pos(self._pos + pos)
   self.check:pos(-self._pos.xy_ - pos.xy_ - vec(2, 1.5, self.z_index + 10)):setVisible(self.checked)
   for _, v in pairs(self.children) do
      v:draw(self, self._pos + pos)
   end
end

function checkbox:addChild(child)
   self.children[#self.children + 1] = child
   self:draw(nil, self._pos / -client.getGuiScale())
end

function checkbox:pos(pos)
   self._pos = pos
   self.nineslice:pos(pos)
end

function checkbox:remove()
   checkboxes[self.key or ""] = nil
   for _, w in pairs(self.nineslice.tasks) do
      w:remove()
   end
   self.check:remove()

   for _, v in pairs(self.children) do
      v:remove()
   end
end

local mousePos = client.getMousePos() / client.getGuiScale()
local oldMousePos = client.getMousePos() / client.getGuiScale()
function events.RENDER()
   oldMousePos = mousePos
   mousePos = client.getMousePos() / client.getGuiScale()

   for k, v in pairs(checkboxes) do
      local relativeMousePos = oldMousePos - v._pos - v.parentPos
      
      if relativeMousePos.x < 0 or relativeMousePos.x > v._size.x then
         goto continue
      elseif relativeMousePos.y < 0 or relativeMousePos.y > v._size.y then
         goto continue
      elseif not click:isPressed() then
         v.held = false
         goto continue
      end
      if not v.held then
         v.checked = not v.checked
         v.events.PRESSED:fire()
         v.held = true
      end
      v.key = k

      v:draw(v, v.parentPos)

      ::continue::
   end
end

return checkbox

