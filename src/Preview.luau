--!strict
--[[
	Preview a KeyframeSequence on a selected R6/R15 model with an Animator.
]]

local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

export type PreviewHandle = {
	stop: (self: PreviewHandle) -> (),
	isPlaying: (self: PreviewHandle) -> boolean,
}

local Preview = {}

local activeTrack: AnimationTrack? = nil
local activeConn: RBXScriptConnection? = nil

local function findHumanoid(model: Model): Humanoid?
	return model:FindFirstChildOfClass("Humanoid")
end

local function ensureAnimator(humanoid: Humanoid): Animator
	local existing = humanoid:FindFirstChildOfClass("Animator")
	if existing then
		return existing
	end
	local animator = Instance.new("Animator")
	animator.Parent = humanoid
	return animator
end

function Preview.stop()
	if activeConn then
		activeConn:Disconnect()
		activeConn = nil
	end
	if activeTrack then
		activeTrack:Stop(0.1)
		activeTrack:Destroy()
		activeTrack = nil
	end
end

function Preview.isPlaying(): boolean
	return activeTrack ~= nil and activeTrack.IsPlaying
end

function Preview.playOnSelection(seq: KeyframeSequence, fadeTime: number?): (boolean, string?)
	Preview.stop()

	local selected = Selection:Get()
	local model: Model? = nil
	for _, inst in selected do
		if inst:IsA("Model") and findHumanoid(inst) then
			model = inst
			break
		end
		local m = inst:FindFirstAncestorOfClass("Model")
		if m and findHumanoid(m) then
			model = m
			break
		end
	end
	if not model then
		return false, "Select a character model with a Humanoid (R6 or R15)."
	end

	local humanoid = findHumanoid(model) :: Humanoid
	local animator = ensureAnimator(humanoid)

	local ok, clipId = pcall(function()
		local provider = game:GetService("AnimationClipProvider")
		return provider:RegisterAnimationClip(seq)
	end)
	if not ok or type(clipId) ~= "string" then
		return false, `RegisterAnimationClip failed: {tostring(clipId)}`
	end

	local animation = Instance.new("Animation")
	animation.Name = "KeyframeToolsPreview"
	animation.AnimationId = clipId

	local loadOk, trackOrErr = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not loadOk then
		animation:Destroy()
		return false, `LoadAnimation failed: {tostring(trackOrErr)}`
	end

	local track = trackOrErr :: AnimationTrack
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(fadeTime or 0.15, 1, 1)
	activeTrack = track

	-- Clean up if character removed
	activeConn = model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			Preview.stop()
		end
	end)

	return true, nil
end

return Preview
