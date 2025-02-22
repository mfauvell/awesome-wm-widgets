-------------------------------------------------
-- Battery Widget for Awesome Window Manager
-- Shows the battery status using the ACPI tool
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local naughty = require("naughty")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

--local PATH_TO_ICONS = "/usr/share/icons/Arc/status/symbolic/"
local HOME = os.getenv("HOME")
local PATH_TO_ICONS = HOME.."/.config/awesome/icons/battery/"

local battery_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
        resize = false
    },
    layout = wibox.container.margin(_, 0, 0, 3)
}

-- Popup with battery info
-- One way of creating a pop-up notification - naughty.notify
local notification
local function show_battery_status()
    awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            naughty.destroy(notification)
            notification = naughty.notify{
                text =  stdout,
                title = "Battery status",
                timeout = 5, hover_timeout = 0.5,
                width = 200,
            }
        end
    )
end

-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
--battery_popup = awful.tooltip({objects = {battery_widget}})

-- To use colors from beautiful theme put
-- following lines in rc.lua before require("battery"):
-- beautiful.tooltip_fg = beautiful.fg_normal
-- beautiful.tooltip_bg = beautiful.bg_normal

local function show_battery_warning()
    naughty.notify{
        icon = HOME .. "/.config/awesome/icons/battery/bat11.png",
        icon_size=100,
        text = "Huston, we have a problem",
        title = "Battery is dying",
        timeout = 5, hover_timeout = 0.5,
        position = "bottom_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end

local last_battery_check = os.time()

watch("acpi -i", 10,
    function(widget, stdout, stderr, exitreason, exitcode)
        local batteryType

        local battery_info = {}
        local capacities = {}
        for s in stdout:gmatch("[^\r\n]+") do
            local status, charge_str, time = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?.*')
            if string.match(s, 'rate information') then
                -- ignore such line
            elseif status ~= nil then
                table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
            else
                local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
                table.insert(capacities, tonumber(cap_str))
            end
        end

        local capacity = 0
        for i, cap in ipairs(capacities) do
            capacity = capacity + cap
        end

        local charge = 0
        local status
        for i, batt in ipairs(battery_info) do
            if batt.charge >= charge then
                status = batt.status -- use most charged battery status
                -- this is arbitrary, and maybe another metric should be used
            end

            charge = charge + batt.charge * capacities[i]
        end
        charge = charge / capacity

        if (charge > 0 and charge <= 5) then
            batteryType = "bat11%s"
            if status ~= 'Charging' and os.difftime(os.time(), last_battery_check) > 300 then
                -- if 5 minutes have elapsed since the last warning
                last_battery_check = time()

                show_battery_warning()
            end
        elseif (charge > 5 and charge <= 10) then batteryType = "bat10%s"
        elseif (charge > 10 and charge <= 20) then batteryType = "bat9%s"
        elseif (charge > 20 and charge <= 30) then batteryType = "bat8%s"
        elseif (charge > 30 and charge <= 40) then batteryType = "bat7%s"
        elseif (charge > 40 and charge <= 50) then batteryType = "bat6%s"
        elseif (charge > 50 and charge <= 60) then batteryType = "bat5%s"
        elseif (charge > 60 and charge <= 70) then batteryType = "bat4%s"
        elseif (charge > 70 and charge <= 80) then batteryType = "bat3%s"
        elseif (charge > 80 and charge <= 90) then batteryType = "bat2%s"
        elseif (charge > 90 and charge <= 100) then batteryType = "bat1%s"
        end

        if status == 'Charging' then
            batteryType = string.format(batteryType, '-char')
        elseif status == 'Discharging' then
            batteryType = string.format(batteryType, '')
        elseif status == 'Full' then
            batteryType = 'ac'
        else
            batteryType = 'ac'
        end

        widget.icon:set_image(PATH_TO_ICONS .. batteryType .. ".png")

        -- Update popup text
        -- battery_popup.text = string.gsub(stdout, "\n$", "")
    end,
    battery_widget)

battery_widget:connect_signal("mouse::enter", function() show_battery_status() end)
battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

return battery_widget
