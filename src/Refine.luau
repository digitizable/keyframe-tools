--!strict
--[[
	In-place refine for KeyframeSequence locomotion clips.

	- Loop-aware channel smoothing (pos + euler)
	- Limb position clamps (stops “detached arm” look from huge Pose translations)
	- Optional root identity (reduces tip-toe / float)
	- Soft loop blend + perfect first/last seam
	- Cubic InOut pose easing between keys
]]

local Config = require(script.Parent.Config)
local Util = require(script.Parent.Util)

export type RefineStats = {
	name: string,
	keys: number,
	maxArmPos: number,
	maxLegPos: number,
	maxJump: number,
	version: string?,
}

local LIMB_NAMES = {
	"HumanoidRootPart",
	"Torso",
	"Head",
	"Left Leg",
	"Right Leg",
	"Left Arm",
	"Right Arm",
}

local Refine = {}

local function getEulerPos(cf: CFrame): { number }
	local rx, ry, rz = cf:ToEulerAnglesYXZ()
	return { cf.X, cf.Y, cf.Z, rx, ry, rz }
end

local function fromEulerPos(e: { number }): CFrame
	return CFrame.new(e[1], e[2], e[3]) * CFrame.fromEulerAnglesYXZ(e[4], e[5], e[6])
end

local function clampPos(e: { number }, maxMag: number)
	local mag = math.sqrt(e[1] * e[1] + e[2] * e[2] + e[3] * e[3])
	if mag > maxMag and mag > 1e-8 then
		local s = maxMag / mag
		e[1], e[2], e[3] = e[1] * s, e[2] * s, e[3] * s
	end
end

local function unwrap(series: { number })
	for i = 2, #series do
		local d = series[i] - series[i - 1]
		while d > math.pi do
			series[i] -= 2 * math.pi
			d = series[i] - series[i - 1]
		end
		while d < -math.pi do
			series[i] += 2 * math.pi
			d = series[i] - series[i - 1]
		end
	end
end

local function smoothLoop(values: { number }, radius: number): { number }
	local n = #values
	local out = table.create(n)
	for i = 1, n do
		local sum, wsum = 0, 0
		for k = -radius, radius do
			local j = ((i - 1 + k) % n) + 1
			if j < 1 then
				j += n
			end
			local w = 1 + (radius - math.abs(k))
			sum += values[j] * w
			wsum += w
		end
		out[i] = sum / wsum
	end
	return out
end

function Refine.apply(seq: KeyframeSequence, options: Config.RefineOptions?): RefineStats
	local opts = options or Config.defaultRefineOptions()
	local kfs = seq:GetKeyframes()
	table.sort(kfs, function(a, b)
		return a.Time < b.Time
	end)
	local n = #kfs
	if n < 3 then
		return {
			name = seq.Name,
			keys = n,
			maxArmPos = 0,
			maxLegPos = 0,
			maxJump = 0,
			version = opts.versionTag,
		}
	end

	-- data[limb][frame] = euler-pos
	local data: { [string]: { { number } } } = {}
	for _, limb in LIMB_NAMES do
		data[limb] = table.create(n)
	end

	for i, kf in kfs do
		local poseMap: { [string]: Pose } = {}
		for _, d in kf:GetDescendants() do
			if d:IsA("Pose") then
				poseMap[d.Name] = d
			end
		end
		for _, limb in LIMB_NAMES do
			local p = poseMap[limb]
			if p then
				data[limb][i] = getEulerPos(p.CFrame)
			else
				data[limb][i] = { 0, 0, 0, 0, 0, 0 }
			end
		end
	end

	-- Smooth channels
	local radius = math.max(0, math.floor(opts.smoothRadius))
	if radius > 0 then
		for _, limb in LIMB_NAMES do
			for ch = 1, 6 do
				local series = table.create(n)
				for i = 1, n do
					series[i] = data[limb][i][ch]
				end
				if ch >= 4 then
					unwrap(series)
				end
				local sm = smoothLoop(series, radius)
				for i = 1, n do
					data[limb][i][ch] = sm[i]
				end
			end
		end
	end

	-- Clamp
	for i = 1, n do
		if opts.rootIdentity then
			data.HumanoidRootPart[i] = { 0, 0, 0, 0, 0, 0 }
		end
		for _, limb in { "Left Arm", "Right Arm" } do
			local e = data[limb][i]
			clampPos(e, opts.armPosMax)
			e[4] = Util.clamp(e[4], -opts.armXMax, opts.armXMax)
			e[6] = Util.clamp(e[6], -opts.armZMax, opts.armZMax)
			e[4] *= opts.armRotScale
			e[5] *= opts.armRotScale
			e[6] *= opts.armRotScale
		end
		for _, limb in { "Left Leg", "Right Leg" } do
			clampPos(data[limb][i], opts.legPosMax)
		end
		local t = data.Torso[i]
		t[2] *= opts.torsoBobScale
		t[4] = Util.clamp(t[4], -opts.torsoXMax, opts.torsoXMax)
		t[5] = Util.clamp(t[5], -opts.torsoYMax, opts.torsoYMax)
		t[6] = Util.clamp(t[6], -opts.torsoZMax, opts.torsoZMax)
		local h = data.Head[i]
		h[4] = Util.clamp(h[4], -opts.headMax, opts.headMax)
		h[5] = Util.clamp(h[5], -opts.headMax, opts.headMax)
		h[6] = Util.clamp(h[6], -opts.headMax, opts.headMax)
	end

	-- Soft loop blend into frame 1
	local blendN = math.min(opts.loopBlendFrames, n - 1)
	for k = 1, blendN do
		local i = n - k
		local w = (1 - k / (blendN + 1)) * 0.4
		for _, limb in LIMB_NAMES do
			for ch = 1, 6 do
				data[limb][i][ch] = data[limb][i][ch] * (1 - w) + data[limb][1][ch] * w
			end
		end
	end
	-- Perfect seam
	for _, limb in LIMB_NAMES do
		for ch = 1, 6 do
			data[limb][n][ch] = data[limb][1][ch]
		end
	end

	-- Write back
	local maxArmPos, maxLegPos, maxJump = 0, 0, 0
	for i, kf in kfs do
		local poseMap: { [string]: Pose } = {}
		for _, d in kf:GetDescendants() do
			if d:IsA("Pose") then
				poseMap[d.Name] = d
			end
		end
		for _, limb in LIMB_NAMES do
			local p = poseMap[limb]
			if p then
				local e = data[limb][i]
				p.CFrame = fromEulerPos(e)
				if opts.cubicEasing then
					p.EasingStyle = Enum.PoseEasingStyle.Cubic
					p.EasingDirection = Enum.PoseEasingDirection.InOut
				end
				local mag = math.sqrt(e[1] * e[1] + e[2] * e[2] + e[3] * e[3])
				if string.find(limb, "Arm", 1, true) then
					maxArmPos = math.max(maxArmPos, mag)
				elseif string.find(limb, "Leg", 1, true) then
					maxLegPos = math.max(maxLegPos, mag)
				end
			end
		end
		if i > 1 then
			for _, limb in LIMB_NAMES do
				local a, b = data[limb][i - 1], data[limb][i]
				local d = 0
				for ch = 1, 6 do
					d += math.abs(a[ch] - b[ch])
				end
				maxJump = math.max(maxJump, d)
			end
		end
	end

	if opts.versionTag then
		seq:SetAttribute("KeyframeToolsVersion", opts.versionTag)
	end
	seq:SetAttribute("KeyframeToolsRefined", true)

	return {
		name = seq.Name,
		keys = n,
		maxArmPos = maxArmPos,
		maxLegPos = maxLegPos,
		maxJump = maxJump,
		version = opts.versionTag,
	}
end

function Refine.analyze(seq: KeyframeSequence): RefineStats
	local kfs = seq:GetKeyframes()
	table.sort(kfs, function(a, b)
		return a.Time < b.Time
	end)
	local maxArmPos, maxLegPos, maxJump = 0, 0, 0
	local prev: { [string]: CFrame }? = nil
	for _, kf in kfs do
		local current: { [string]: CFrame } = {}
		for _, d in kf:GetDescendants() do
			if d:IsA("Pose") then
				current[d.Name] = d.CFrame
				local p = d.CFrame.Position
				local mag = p.Magnitude
				if string.find(d.Name, "Arm", 1, true) then
					maxArmPos = math.max(maxArmPos, mag)
				elseif string.find(d.Name, "Leg", 1, true) then
					maxLegPos = math.max(maxLegPos, mag)
				end
			end
		end
		if prev then
			for name, cf in current do
				local prevCf = prev[name]
				if prevCf then
					local a = getEulerPos(prevCf)
					local b = getEulerPos(cf)
					local d = 0
					for ch = 1, 6 do
						d += math.abs(a[ch] - b[ch])
					end
					maxJump = math.max(maxJump, d)
				end
			end
		end
		prev = current
	end
	return {
		name = seq.Name,
		keys = #kfs,
		maxArmPos = maxArmPos,
		maxLegPos = maxLegPos,
		maxJump = maxJump,
		version = seq:GetAttribute("KeyframeToolsVersion") :: string?,
	}
end

return Refine
