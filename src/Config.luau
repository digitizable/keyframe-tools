--!strict
--[[
	Default options for refine / import. All user-facing; not project-specific.
]]

export type RefineOptions = {
	smoothRadius: number,
	armPosMax: number,
	legPosMax: number,
	armXMax: number, -- radians
	armZMax: number, -- radians
	armRotScale: number,
	torsoXMax: number,
	torsoYMax: number,
	torsoZMax: number,
	torsoBobScale: number,
	headMax: number,
	loopBlendFrames: number,
	rootIdentity: boolean,
	cubicEasing: boolean,
	versionTag: string?,
}

local Config = {}

Config.PLUGIN_NAME = "Keyframe Tools"
Config.TOOLBAR_NAME = "Keyframe Tools"
Config.WIDGET_ID = "KeyframeTools_Dock_v1"
Config.WIDGET_TITLE = "Keyframe Tools"

--- Destination path segments under game (editable in UI)
Config.DEFAULT_DESTINATION = "ReplicatedStorage.Animations"

--- Also mirror imports here when enabled
Config.DEFAULT_MIRROR = "ServerStorage.Animations"

function Config.defaultRefineOptions(): RefineOptions
	return {
		smoothRadius = 2,
		armPosMax = 0.30,
		legPosMax = 1.05,
		armXMax = math.rad(35),
		armZMax = math.rad(70),
		armRotScale = 1,
		torsoXMax = math.rad(16),
		torsoYMax = math.rad(8),
		torsoZMax = math.rad(16),
		torsoBobScale = 0.75,
		headMax = math.rad(16),
		loopBlendFrames = 4,
		rootIdentity = true,
		cubicEasing = true,
		versionTag = "keyframe-tools-refine",
	}
end

--- Milder pass for walk-like locomotion
function Config.walkRefineOptions(): RefineOptions
	local o = Config.defaultRefineOptions()
	o.armPosMax = 0.30
	o.legPosMax = 0.95
	o.armXMax = math.rad(22)
	o.armZMax = math.rad(34)
	o.torsoXMax = math.rad(8)
	o.torsoYMax = math.rad(5)
	o.torsoZMax = math.rad(7)
	o.torsoBobScale = 0.7
	o.headMax = math.rad(8)
	o.loopBlendFrames = 5
	o.versionTag = "keyframe-tools-walk"
	return o
end

--- Stronger clamps for run/sprint-style clips (prevents “detached” arms)
function Config.runRefineOptions(): RefineOptions
	local o = Config.defaultRefineOptions()
	o.armPosMax = 0.26
	o.legPosMax = 1.05
	o.armXMax = math.rad(40)
	o.armZMax = math.rad(68)
	o.armRotScale = 0.92
	o.torsoXMax = math.rad(16)
	o.torsoBobScale = 0.65
	o.loopBlendFrames = 4
	o.versionTag = "keyframe-tools-run"
	return o
end

return Config
