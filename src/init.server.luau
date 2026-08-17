--!strict
--[[
	Keyframe Tools — Studio plugin entry point.

	Toolbar + dock widget for importing KeyframeSequences from .rbxm packs,
	refining locomotion clips, and previewing on a selected rig.

	Requires the global `plugin` (present when installed as a Studio plugin).
]]

local Config = require(script.Config)
local Preview = require(script.Preview)
local Ui = require(script.Ui)

if not plugin then
	warn("[Keyframe Tools] This script must run as a Studio plugin (global `plugin` missing).")
	return
end

local toolbar = plugin:CreateToolbar(Config.TOOLBAR_NAME)
local toggleButton = toolbar:CreateButton(
	"OpenKeyframeTools",
	"Open Keyframe Tools dock",
	-- Built-in icon id; replace with your own asset if desired
	"rbxasset://textures/AnimationEditor/icon_timeline_animation_clip.png",
	"Keyframe Tools"
)
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- initially enabled
	false, -- override restore
	360,
	520,
	300,
	400
)

local widget = plugin:CreateDockWidgetPluginGui(Config.WIDGET_ID, widgetInfo)
widget.Title = Config.WIDGET_TITLE
widget.Name = "KeyframeToolsWidget"

Ui.mount(plugin, widget)

local function setOpen(open: boolean)
	widget.Enabled = open
	toggleButton:SetActive(open)
end

toggleButton.Click:Connect(function()
	setOpen(not widget.Enabled)
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
	if not widget.Enabled then
		Preview.stop()
	end
end)

plugin.Unloading:Connect(function()
	Preview.stop()
end)
