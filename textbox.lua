local textboxes = {}
local drawable = require("NtUI.drawable")
local eventlib = require("NtUI.BunnyEventLib")
local nineslice = require("NtUI.nineslice")
local label = require("NtUI.label")

local click = keybinds:newKeybind("Click", "key.mouse.left", true)

local texture = textures["NtUI.theme"]

---@class NtUI.Textbox : NtUI.Drawable
---@field _pos Vector2
---@field _size Vector2
---@field parentPos Vector2
---@field events {CLICK: Event}
---@field nineslice NtUI.Nineslice
---@field children NtUI.Drawable[]
---@field text string
---@field label NtUI.Label
local textbox = {}

local eventIter = 0
---Creates a new textbox
---@param pos Vector2
---@param width integer
---@param z_index integer
---@return NtUI.Textbox
function textbox.new(pos, width, z_index)
   local new = setmetatable({}, {
      __index = function(self, key)
         return textbox[key] or drawable[key]
      end,
      __type = "NtUI.Textbox"
   })

   textboxes[#textboxes + 1] = new

   new._pos = pos
   new._size = vec(width, 8)

   new.events = eventlib.newEvents()
   new.events.CLICK = eventlib.newEvent()
   new.label = label.new(vec(2, 2), z_index + 10, "")
   new.children = {new.label}
   new.parentPos = vec(0, 0)
   new.text = ""

   new.label:setWidth(width / 0.68):setWrap(false)

   new.nineslice = nineslice.new(texture, vec(0, 10), vec(5, 5), 2, 4, z_index):pos(pos):size(new._size)

   return new
end

function textbox:draw(parent, pos)
   self.parentPos = pos
   self.nineslice:pos(self._pos + pos)
   for _, v in pairs(self.children) do
      v:draw(self, self._pos + pos)
   end
   self.label:draw(self, self._pos + pos)
end

function textbox:addChild(child)
   self.children[#self.children + 1] = child
   self:draw(nil, self._pos / -client.getGuiScale())
end

function textbox:pos(pos)
   self._pos = pos
   self.nineslice:pos(pos)
end

function textbox:remove()
   textboxes[self.key or ""] = nil
   for _, w in pairs(self.nineslice.tasks) do
      w:remove()
   end

   for _, v in pairs(self.children) do
      v:remove()
   end
end

local mousePos = client.getMousePos() / client.getGuiScale()
local oldMousePos = client.getMousePos() / client.getGuiScale()
function events.RENDER()
   oldMousePos = mousePos
   mousePos = client.getMousePos() / client.getGuiScale()

   for k, v in pairs(textboxes) do
      local relativeMousePos = oldMousePos - v._pos - v.parentPos
      
      if relativeMousePos.x < 0 or relativeMousePos.x > v._size.x then
         if click:isPressed() then v.typing = false end
         goto continue
      elseif relativeMousePos.y < 0 or relativeMousePos.y > v._size.y then
         if click:isPressed() then v.typing = false end
         goto continue
      elseif not click:isPressed() then
         v.held = false
         goto continue
      end

      if not v.held then
         v.events.CLICK:fire()
         v.held = true
      end

      v.key = k
      v.typing = true

      v:draw(v, v.parentPos)

      ::continue::
   end
end

local ctrl = keybinds:of("Control", "key.keyboard.left.control", true)
keybinds:of("Enter", "key.keyboard.enter", true):onPress(function()
   for k, v in pairs(textboxes) do
      v.typing = false
   end
end)

local backspace = keybinds:of("Backspace", "key.keyboard.backspace", true):getID()

function events.KEY_PRESS(key, state)
   if key == backspace and state ~= 0 then
      for k, v in pairs(textboxes) do
         if v.typing then
            v.text = v.text:gsub(".$", "")

            local textToSet = v.text
            while client.getTextWidth(textToSet) * 0.68 > v._size.x do
               textToSet = textToSet:gsub("^.", "")
            end

            v.label:text(textToSet)
         end
      end
   end
end

function events.CHAR_TYPED(char)
   for _, v in pairs(textboxes) do
      if v.typing then
         if ctrl:isPressed() and char == "v" then
            v.text = v.text .. host:getClipboard():gsub("[\n\t]", "")
         else
            v.text = v.text .. char
         end

         local textToSet = v.text
         while client.getTextWidth(textToSet) * 0.68 > v._size.x do
            textToSet = textToSet:gsub("^.", "")
         end

         v.label:text(textToSet)
      end
   end
end

return textbox

