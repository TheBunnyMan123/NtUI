---@class NtUI.Drawable
---@field children NtUI.Drawable[]
---@field _pos Vector2
---@field z_index integer
local drawable = {}

---Draws the drawable, updating whatever it needs to update
---@param parent NtUI.Drawable
---@param pos Vector2
function drawable:draw(parent, pos)
   for _, v in pairs(self.children) do
      v:draw(self, self._pos + pos)
   end
end

---Removes the drawable
function drawable:remove()
   for _, v in pairs(self.children) do
      v:remove()
   end
end

---Adds a child to the drawable
---@param child NtUI.Drawable
function drawable:addChild(child)
   self.children[#self.children + 1] = child
   self:draw(nil, self._pos)
end

---Updates the drawable's position
---@param pos Vector2
function drawable:pos(pos)
   self._pos = pos
   self:draw(nil, pos)
end

---Creates a new drawable
---@param pos Vector2
---@return NtUI.Drawable
function drawable.new(pos)
   return setmetatable({
      children = {},
      _pos = pos,
      z_index = 0
   }, {
      __index = drawable,
      __type = "NtUI.Drawable"
   })
end

return drawable.new(vec(0, 0))

