local utils = require("luis.utils")

local pointInRect = utils.pointInRect

local dropDown = {}

local luis  -- This will store the reference to the core library
function dropDown.setluis(luisObj)
    luis = luisObj
end

-- dropDown
function dropDown.new(items, value, width, height, onChange, row, col, maxVisibleItems, customTheme)
    local dropdownTheme = customTheme or luis.theme.dropdown
    
    local maxVisibleItems = maxVisibleItems or 5  -- Maximum number of visible items when dropDown is open
    
    return {
        type = "DropDown",
        items = items,
        value = value or 1,
        width = width * luis.gridSize,
        height = height * luis.gridSize,
        onChange = onChange,
        position = luis.Vector2D.new((col - 1) * luis.gridSize, (row - 1) * luis.gridSize),
        isOpen = false,
        hoverIndex = nil,
        scrollOffset = 0,
        maxScrollOffset = math.max(0, #items - maxVisibleItems),
        focusable = true,  -- Make the dropdown focusable
        focused = false,   -- Track focus state

        update = function(self, mx, my)
            -- Update focus state
            self.focused = (luis.currentFocus == self)

            -- Check for joystick/gamepad input when focused
            if self.focused then
                if luis.joystickJustPressed('a') or luis.joystickJustPressed('dpright') then
                    self:joystickpress('a')
                end
            end

            if self.isOpen then
                local listHeight = math.min(#self.items, maxVisibleItems) * self.height
                self.hoverIndex = nil
                for i = 1, math.min(#self.items, maxVisibleItems) do
                    local itemY = self.position.y + self.height * i
                    if pointInRect(mx, my, self.position.x, itemY, self.width - dropdownTheme.scrollBarWidth, self.height) then
                        self.hoverIndex = i + math.floor(self.scrollOffset)
                        break
                    end
                end
            end
        end,

        draw = function(self)
            -- Draw main button
            love.graphics.setColor(dropdownTheme.backgroundColor)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.width, self.height)
            love.graphics.setColor(dropdownTheme.borderColor)
            love.graphics.rectangle("line", self.position.x, self.position.y, self.width, self.height)
            
            -- Draw selected text
            love.graphics.setColor(dropdownTheme.textColor)
            love.graphics.printf(self.items[self.value], self.position.x + luis.gridSize, self.position.y + (self.height - luis.theme.text.font:getHeight()) / 2, self.width - self.height, dropdownTheme.align)
            
            -- Draw arrow
            love.graphics.setColor(dropdownTheme.arrowColor)
            local arrowSize = self.height * 0.3
            local arrowX = self.position.x + self.width - self.height / 2
            local arrowY = self.position.y + self.height / 2
            love.graphics.polygon("fill", 
                arrowX - arrowSize / 2, arrowY - arrowSize / 2,
                arrowX + arrowSize / 2, arrowY - arrowSize / 2,
                arrowX, arrowY + arrowSize / 2
            )
            
            -- Draw focus indicator
            if self.focused then
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("line", self.position.x - 2, self.position.y - 2, self.width + 4, self.height + 4)
            end
            
            -- Draw dropDown list if open
            if self.isOpen then
                local listHeight = math.min(#self.items, maxVisibleItems) * self.height
                love.graphics.setScissor(self.position.x*luis.scale, self.position.y*luis.scale + self.height*luis.scale, self.width*luis.scale, listHeight*luis.scale)

                for i = 1, #self.items do
                    local itemY = self.position.y + self.height * i - self.scrollOffset * self.height
                    if itemY >= self.position.y + self.height and itemY <= self.position.y + self.height + listHeight then
                        love.graphics.setColor(i == self.hoverIndex and dropdownTheme.hoverColor or dropdownTheme.backgroundColor)
                        love.graphics.rectangle("fill", self.position.x, itemY, self.width - dropdownTheme.scrollBarWidth, self.height)
                        love.graphics.setColor(dropdownTheme.borderColor)
                        love.graphics.rectangle("line", self.position.x, itemY, self.width - dropdownTheme.scrollBarWidth, self.height)
                        love.graphics.setColor(dropdownTheme.textColor)
                        love.graphics.printf(self.items[i], self.position.x + luis.gridSize, itemY + (self.height - luis.theme.text.font:getHeight()) / 2, self.width - dropdownTheme.scrollBarWidth, dropdownTheme.align)
                    end
                end
                
                -- Draw scrollbar
                if #self.items > maxVisibleItems then
                    local scrollBarHeight = (maxVisibleItems / #self.items) * listHeight
                    local scrollBarY = self.position.y + self.height + (self.scrollOffset / self.maxScrollOffset) * (listHeight - scrollBarHeight)
                    love.graphics.setColor(dropdownTheme.scrollBarColor)
                    love.graphics.rectangle("fill", self.position.x + self.width - dropdownTheme.scrollBarWidth, scrollBarY, dropdownTheme.scrollBarWidth, scrollBarHeight)
                end
                
                love.graphics.setScissor()
            end
        end,
        
        click = function(self, x, y, button, istouch)
            if pointInRect(x, y, self.position.x, self.position.y, self.width, self.height) then
                self.isOpen = not self.isOpen
                return true
            elseif self.isOpen then
                local listHeight = math.min(#self.items, maxVisibleItems) * self.height
                for i = 1, math.min(#self.items, maxVisibleItems) do
                    local itemY = self.position.y + self.height * i
                    if pointInRect(x, y, self.position.x, itemY, self.width - dropdownTheme.scrollBarWidth, self.height) then
                        self.value = i + math.floor(self.scrollOffset)
                        self.isOpen = false
                        if self.onChange then
                            self.onChange(self.items[self.value], self.value)
                        end
                        return true
                    end
                end
                self.isOpen = false
            end
            return false
        end,
        
        wheelmoved = function(self, x, y)
            if self.isOpen then
                local mx, my = love.mouse.getPosition()
                mx, my = mx / luis.scale, my / luis.scale
                if pointInRect(mx, my, self.position.x, self.position.y + self.height, self.width, math.min(#self.items, maxVisibleItems) * self.height) then
                    self.scrollOffset = math.max(0, math.min(self.maxScrollOffset, self.scrollOffset - y))
                    return true
                end
            end
            return false
        end,

        setItems = function(self, newItems)
            self.items = newItems
            self.maxScrollOffset = math.max(0, #newItems - maxVisibleItems)
            self.value = math.min(self.value, #newItems)
        end,
        
        setValue = function(self, newIndex)
            if newIndex >= 1 and newIndex <= #self.items then
                self.value = newIndex
                if self.onChange then
                    self.onChange(self.items[self.value], self.value)
                end
            end
        end,

        -- Function for handling gamepad input
        updateFocus = function(self, jx, jy)
            if not self.isOpen then
                if jy > luis.deadzone then
                    self.isOpen = true
                    self.hoverIndex = self.value
                end
            else
                if jy > luis.deadzone then
                    self.hoverIndex = math.min(#self.items, (self.hoverIndex or self.value) + 1)
                    self.scrollOffset = math.max(0, math.min(self.maxScrollOffset, self.hoverIndex - maxVisibleItems))
                elseif jy < -luis.deadzone then
                    self.hoverIndex = math.max(1, (self.hoverIndex or self.value) - 1)
                    self.scrollOffset = math.max(0, math.min(self.maxScrollOffset, self.hoverIndex - 1))
                end
            end
        end,

        -- Function for handling gamepad button press
        joystickpress = function(self, button)
			print("dropdown.joystickpress = function", button)
            if button == "a" or button == "start" then
                if not self.isOpen then
                    self.isOpen = true
                    self.hoverIndex = self.value
                else
                    if self.hoverIndex then
                        self.value = self.hoverIndex
                        self.isOpen = false
                        if self.onChange then
                            self.onChange(self.items[self.value], self.value)
                        end
                    end
                end
                return true
            elseif button == "b" and self.isOpen then
                self.isOpen = false
                return true
            end
            return false
        end
    }
end

return dropDown
