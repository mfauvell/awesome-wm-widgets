-------------------------------------------------
-- Volume Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

--local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"
local HOME = os.getenv("HOME")
local PATH_TO_ICONS = HOME.."/.config/awesome/icons/"

local GET_VOLUME_CMD = 'amixer sget Master'
local INC_VOLUME_CMD = 'amixer sset Master 5%+'
local DEC_VOLUME_CMD = 'amixer sset Master 5%-'
local TOG_VOLUME_CMD = 'amixer sset Master toggle'

local volume_widget = wibox.widget {
    {
        id = "icon",
        image = path_to_icons .. "vol-mute.png",
        resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(_, _, _, 3),
    set_image = function(self, path)
        self.icon.image = path
    end
}

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))
    local volume_icon_name
    if mute == "off" then volume_icon_name="vol-mute"
    elseif (volume == 0) then volume_icon_name="vol-mute"
    elseif (volume >= 0 and volume < 33) then volume_icon_name="vol-low"
    --elseif (volume < 50) then volume_icon_name="audio-volume-low-symbolic"
    elseif (volume < 66) then volume_icon_name="vol-med"
    elseif (volume <= 100) then volume_icon_name="vol-hi"
    end
    widget.image = PATH_TO_ICONS .. volume_icon_name .. ".png"
end

--[[ allows control volume level by:
- clicking on the widget to mute/unmute
- scrolling when cursor is over the widget
]]
volume_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then awful.spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then awful.spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then awful.spawn(TOG_VOLUME_CMD, false)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volume_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volume_widget)

return volume_widget

