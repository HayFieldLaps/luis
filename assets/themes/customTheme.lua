-- Convert hex to RGB (0-1 range)
local function hexToRGB(hex)
    return {
        tonumber(hex:sub(1,2), 16) / 255,
        tonumber(hex:sub(3,4), 16) / 255,
        tonumber(hex:sub(5,6), 16) / 255,
		1 -- Alpha is always 1 here
    }
end

-- Custom color palette
local colors3 = {
    purple = hexToRGB("995d81"),
    orange = hexToRGB("eb8258"),
    yellow = hexToRGB("f6f740"),
    lime = hexToRGB("d8dc6a"),
    blue = hexToRGB("6689a1")
}

local colors = {
    purple = hexToRGB("023047"),
    orange = hexToRGB("8ECAE6"),
    yellow = hexToRGB("FFB703"),
    lime = hexToRGB("FB8500"),
    blue = hexToRGB("219EBC")
}

-- Custom theme
local customTheme = {
    background = {
        color = colors.purple,
    },
    text = {
        color = colors.yellow,
        font = love.graphics.newFont("assets/fonts/DungeonFont.ttf", 46),
        align = "left",
    },
    button = {
        color = colors.blue,
        hoverColor = colors.orange,
        pressedColor = {colors.orange[1]*0.8, colors.orange[2]*0.8, colors.orange[3]*0.8, 1},
        textColor = colors.yellow,
        cornerRadius = 1,
        elevation = 0,
        elevationHover = 0,
        elevationPressed = 0,
        transitionDuration = 0.45,
    },
    slider = {
        trackColor = colors.lime,
        knobColor = colors.orange,
		grabColor = {colors.orange[1]*0.8, colors.orange[2]*0.8, colors.orange[3]*0.8, 1},
        knobRadius = 25,
    },
    switch = {
        offColor = colors.blue,
        onColor = colors.orange,
        knobColor = colors.yellow,
    },
    checkbox = {
        boxColor = colors.blue,
        checkColor = colors.orange,
    },
    radiobutton = {
        circleColor = colors.blue,
        dotColor = colors.orange,
    },
    grid = {
        color = {colors.lime[1], colors.lime[2], colors.lime[3], 0.3},
    },
    progressbar = {
        backgroundColor = colors.blue,
        fillColor = colors.orange,
        borderColor = colors.yellow,
    },
    icon = {
        color = colors.yellow,
    },
    dropdown = {
        backgroundColor = colors.blue,
        textColor = colors.yellow,
        hoverColor = colors.orange,
        borderColor = colors.lime,
        arrowColor = colors.yellow,
        scrollBarColor = {0.5, 0.5, 0.5},
        scrollBarWidth = 10
    },
	textinput = {
		backgroundColor = colors.blue,
		textColor = colors.yellow,
		cursorColor = colors.yellow,
		selectionColor = colors.orange,
		borderColor = colors.lime,
		borderWidth = 2,
		padding = 5
	},
	flexContainer = {
        backgroundColor = colors.blue,
        borderColor = colors.lime,
        borderWidth = 2,
        padding = 10,
        handleSize = 20,
        handleColor = colors.yellow,
	},
}

return customTheme
