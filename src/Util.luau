--!strict

local Util = {}

function Util.clamp(x: number, a: number, b: number): number
	return math.max(a, math.min(b, x))
end

--- Resolve a dotted path under game (e.g. "ReplicatedStorage.Animations")
function Util.resolvePath(path: string): Instance?
	local current: Instance = game
	for segment in string.gmatch(path, "[^%.]+") do
		local child = current:FindFirstChild(segment)
		if not child then
			return nil
		end
		current = child
	end
	return current
end

--- Ensure a dotted path exists under game; creates Folder segments as needed
function Util.ensurePath(path: string): Instance
	local current: Instance = game
	for segment in string.gmatch(path, "[^%.]+") do
		local child = current:FindFirstChild(segment)
		if not child then
			local folder = Instance.new("Folder")
			folder.Name = segment
			folder.Parent = current
			child = folder
		end
		current = child
	end
	return current
end

function Util.isKeyframeSequence(inst: Instance): boolean
	return inst:IsA("KeyframeSequence")
end

--- Collect all KeyframeSequences under root (including root itself)
function Util.collectKeyframeSequences(root: Instance): { KeyframeSequence }
	local out: { KeyframeSequence } = {}
	if root:IsA("KeyframeSequence") then
		table.insert(out, root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("KeyframeSequence") then
			table.insert(out, d)
		end
	end
	return out
end

--- Prefer AnimSaves children when present (Moon / Animation Editor layout)
function Util.findAnimSources(root: Instance): { KeyframeSequence }
	local animSaves = root:FindFirstChild("AnimSaves", true)
	if animSaves then
		local list = Util.collectKeyframeSequences(animSaves)
		if #list > 0 then
			return list
		end
	end
	return Util.collectKeyframeSequences(root)
end

function Util.replaceChild(parent: Instance, child: Instance)
	local existing = parent:FindFirstChild(child.Name)
	if existing then
		existing:Destroy()
	end
	child.Parent = parent
end

function Util.deepClone(inst: Instance): Instance
	return inst:Clone()
end

function Util.formatStats(stats: { [string]: any }): string
	local parts = {}
	for k, v in stats do
		if type(v) == "number" then
			table.insert(parts, string.format("%s=%.3g", k, v))
		else
			table.insert(parts, `{k}={tostring(v)}`)
		end
	end
	table.sort(parts)
	return table.concat(parts, "  ")
end

return Util
