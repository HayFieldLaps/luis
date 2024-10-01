local utils = require("luis.utils")

local flexContainer = {}

local luis  -- This stores the reference to the core library
function flexContainer.setluis(luisObj)
    luis = luisObj
end

-- FlexContainer
function flexContainer.new(width, height, row, col, customTheme)
    local containerTheme = customTheme or luis.theme.flexContainer

    local container = {
        type = "FlexContainer",
        width = width * luis.gridSize,
        height = height * luis.gridSize,
        position = luis.Vector2D.new((col - 1) * luis.gridSize, (row - 1) * luis.gridSize),
        children = {},
        padding = containerTheme.padding,
        isDragging = false,
        isResizing = false,
        dragOffset = luis.Vector2D.new(0, 0),
        focused = false,
        focusable = true,  -- Make the button focusable
        focusableChildren = {},
        currentFocusIndex = 0,
		internalFocusActive = false,
        
        addChild = function(self, child)
            table.insert(self.children, child)
            if child.focusable then
                table.insert(self.focusableChildren, child)
            end
            self:arrangeChildren()
            self:updateMinimumSize()
        end,
        
        removeChild = function(self, child)
            for i, c in ipairs(self.children) do
                if c == child then
                    table.remove(self.children, i)
                    break
                end
            end
            -- Remove from focusableChildren if present
            for i, focusableChild in ipairs(self.focusableChildren) do
                if focusableChild == child then
                    table.remove(self.focusableChildren, i)
                    break
                end
            end
            self:arrangeChildren()
            self:updateMinimumSize()
        end,

        arrangeChildren = function(self)
            local x = self.position.x + self.padding
            local y = self.position.y + self.padding
            local maxHeight = 0
            
            for _, child in ipairs(self.children) do
                if x + child.width > self.position.x + self.width - self.padding then
                    -- Move to next row
                    x = self.position.x + self.padding
                    y = y + maxHeight + self.padding
                    maxHeight = 0
                end
                
                child.position.x = x
                child.position.y = y
                
                x = x + child.width + self.padding
                maxHeight = math.max(maxHeight, child.height)
            end
        end,

        updateMinimumSize = function(self)
            local minWidth = 0
            local minHeight = self.padding * 2  -- Start with padding for top and bottom
            local currentRowWidth = self.padding
            local currentRowHeight = 0
            
            for _, child in ipairs(self.children) do
                if currentRowWidth + child.width + self.padding > self.width then
                    -- Move to next row
                    minWidth = math.max(minWidth, currentRowWidth)
                    minHeight = minHeight + currentRowHeight + self.padding
                    currentRowWidth = self.padding + child.width
                    currentRowHeight = child.height
                else
                    currentRowWidth = currentRowWidth + child.width + self.padding
                    currentRowHeight = math.max(currentRowHeight, child.height)
                end
            end
            -- Add the last row
            minWidth = math.max(minWidth, currentRowWidth)
            minHeight = minHeight + currentRowHeight
            
            -- Add padding for left and right sides
            minWidth = minWidth + self.padding
            
            self.minWidth = math.max(minWidth, containerTheme.handleSize * 2)
            self.minHeight = math.max(minHeight, containerTheme.handleSize * 2)
        end,

        resize = function(self, newWidth, newHeight)
            self.width = math.max(self.minWidth, newWidth)
            self.height = math.max(self.minHeight, newHeight)
            self:arrangeChildren()
            self:updateMinimumSize()  -- Recalculate minimum size after resizing
        end,

        moveFocus = function(self, direction)
            if #self.focusableChildren == 0 then return end

            if direction == "next" then
                self.currentChildFocusIndex = (self.currentChildFocusIndex % #self.focusableChildren) + 1
            elseif direction == "previous" then
                self.currentChildFocusIndex = ((self.currentChildFocusIndex - 2) % #self.focusableChildren) + 1
            end

            -- Update focus states
            for i, child in ipairs(self.focusableChildren) do
                child.focused = (i == self.currentChildFocusIndex)
            end
        end,

        activateInternalFocus = function(self)
            self.internalFocusActive = true
            if #self.focusableChildren > 0 then
                self.currentChildFocusIndex = 1
                self.focusableChildren[1].focused = true
            end
        end,

        deactivateInternalFocus = function(self)
            self.internalFocusActive = false
            for _, child in ipairs(self.focusableChildren) do
                child.focused = false
            end
        end,

        update = function(self, mx, my, dt)
            if self.focused and not self.internalFocusActive then
                self:activateInternalFocus()
            elseif not self.focused and self.internalFocusActive then
                self:deactivateInternalFocus()
            end

            if self.isDragging then
                self.position.x = mx - self.dragOffset.x
                self.position.y = my - self.dragOffset.y
                self:arrangeChildren()
            elseif self.isResizing then
                self.width = math.max(self.minWidth, mx - self.position.x)
                self.height = math.max(self.minHeight, my - self.position.y)
                self:arrangeChildren()
            end

            for _, child in ipairs(self.children) do
                if child.update then
                    child:update(mx, my, dt)
                end
            end
        end,
        
        draw = function(self)
            -- Draw container background
            love.graphics.setColor(containerTheme.backgroundColor)
            love.graphics.rectangle("fill", self.position.x, self.position.y, self.width, self.height)
            
            -- Draw container border
            love.graphics.setColor(containerTheme.borderColor)
            love.graphics.setLineWidth(containerTheme.borderWidth)
            love.graphics.rectangle("line", self.position.x, self.position.y, self.width, self.height)
            
            -- Draw resize handle
            love.graphics.setColor(containerTheme.handleColor)
            love.graphics.rectangle("fill", self.position.x + self.width - containerTheme.handleSize, self.position.y + self.height - containerTheme.handleSize, containerTheme.handleSize, containerTheme.handleSize)
            
            -- Draw children
            for _, child in ipairs(self.children) do
                child:draw()
            end

            -- Draw focus indicator
            if self.focused then
                love.graphics.setColor(1, 1, 1, 0.5) -- grey focus
                love.graphics.rectangle("line", self.position.x - 2, self.position.y - 2, self.width + 4, self.height + 4, containerTheme.cornerRadius)
            end

            -- Draw focus indicator for the currently focused child
            if self.internalFocusActive and self.currentChildFocusIndex > 0 then
                local focusedChild = self.focusableChildren[self.currentChildFocusIndex]
                love.graphics.setColor(0.7, 0.7, 0.7, 0.5)  -- darker hild focus
                love.graphics.rectangle("line", focusedChild.position.x - 2, focusedChild.position.y - 2, focusedChild.width + 4, focusedChild.height + 4, containerTheme.cornerRadius)
            end
        end,
        
        click = function(self, x, y, button, istouch)
            if self:isInResizeHandle(x, y) then
                self.isResizing = true
                return true
            elseif self:isInContainer(x, y) then
                for _, child in ipairs(self.children) do
                    if child.click and child:click(x, y, button, istouch) then
                        return true
                    end
                end
                self.isDragging = true
                self.dragOffset.x = x - self.position.x
                self.dragOffset.y = y - self.position.y
                return true
            end
            return false
        end,
        
        release = function(self, x, y, button, istouch)
            self.isDragging = false
            self.isResizing = false
            for _, child in ipairs(self.children) do
                if child.release then
                    child:release(x, y, button, istouch)
                end
            end
        end,

        textinput = function(self, text)
            self.isDragging = false
            self.isResizing = false
            for _, child in ipairs(self.children) do
                if child.textinput then
					child.active = true
                    child:textinput(text)
					child.active = false
                    return
                end
            end
        end,

        keypressed = function(self, key)
            self.isDragging = false
            self.isResizing = false
            for _, child in ipairs(self.children) do
                if child.keypressed then
                    child:keypressed(key)
                    return
                end
            end
        end,

        setText = function(self, newText)
           self.isDragging = false
            self.isResizing = false
            for _, child in ipairs(self.children) do
                if child.setText then
                    child:setText(newText)
                end
            end
        end,

        isInResizeHandle = function(self, x, y)
            return x >= self.position.x + self.width - containerTheme.handleSize and
                   x <= self.position.x + self.width and
                   y >= self.position.y + self.height - containerTheme.handleSize and
                   y <= self.position.y + self.height
        end,
        
        isInContainer = function(self, x, y)
            return x >= self.position.x and x <= self.position.x + self.width and
                   y >= self.position.y and y <= self.position.y + self.height
        end,

        gamepadpressed = function(self, button)
            if not self.internalFocusActive then return false end

            if button == "dpdown" or button == "dpright" then
                self:moveFocus("next")
                return true
            elseif button == "dpup" or button == "dpleft" then
                self:moveFocus("previous")
                return true
            elseif button == "a" or button == "b" then
                -- Activate the currently focused child
                local focusedChild = self.focusableChildren[self.currentChildFocusIndex]
                if focusedChild and focusedChild.gamepadpressed then
					local rtn = focusedChild:gamepadpressed(button)
                    return rtn
                end
            end
            return false
        end,

        gamepadreleased = function(self, button)
            -- Activate the currently focused child
			local focusedChild = self.focusableChildren[self.currentChildFocusIndex]
			if focusedChild and focusedChild.gamepadreleased then
					local rtn = focusedChild:gamepadreleased(button)
                    return rtn
			end
			return false
        end,
    }
    
    container:updateMinimumSize()
    return container
end

return flexContainer
