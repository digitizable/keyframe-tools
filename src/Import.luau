--!strict
--[[
	Import KeyframeSequences from:
	- PromptImportFile (.rbxm / .rbxmx)
	- Selection (models/folders containing AnimSaves or sequences)
]]

local Selection = game:GetService("Selection")

local Util = require(script.Parent.Util)

export type ImportResult = {
	imported: { KeyframeSequence },
	destination: Instance,
	mirror: Instance?,
	errors: { string },
}

local Import = {}

function Import.promptAndLoad(plugin: Plugin): { Instance }
	local ok, result = pcall(function()
		return plugin:PromptImportFile({ "rbxm", "rbxmx" }) :: Instance?
	end)
	if not ok then
		warn("[KeyframeTools] PromptImportFile failed:", result)
		return {}
	end
	if result == nil then
		return {}
	end
	-- PromptImportFile returns a single Instance (often a Model/Folder)
	return { result }
end

function Import.sequencesFromInstances(roots: { Instance }): { KeyframeSequence }
	local seen: { [KeyframeSequence]: boolean } = {}
	local list: { KeyframeSequence } = {}
	for _, root in roots do
		for _, seq in Util.findAnimSources(root) do
			if not seen[seq] then
				seen[seq] = true
				table.insert(list, seq)
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

function Import.sequencesFromSelection(): { KeyframeSequence }
	return Import.sequencesFromInstances(Selection:Get())
end

function Import.copySequences(
	sequences: { KeyframeSequence },
	destinationPath: string,
	mirrorPath: string?,
	overwrite: boolean
): ImportResult
	local errors: { string } = {}
	local imported: { KeyframeSequence } = {}

	local dest = Util.ensurePath(destinationPath)
	local mirror: Instance? = nil
	if mirrorPath and mirrorPath ~= "" then
		mirror = Util.ensurePath(mirrorPath)
	end

	for _, seq in sequences do
		local name = seq.Name
		if not overwrite and dest:FindFirstChild(name) then
			table.insert(errors, `Skipped existing {destinationPath}.{name}`)
			continue
		end
		local clone = seq:Clone() :: KeyframeSequence
		clone.Name = name
		Util.replaceChild(dest, clone)
		table.insert(imported, clone)

		if mirror then
			local mclone = seq:Clone()
			mclone.Name = name
			Util.replaceChild(mirror, mclone)
		end
	end

	return {
		imported = imported,
		destination = dest,
		mirror = mirror,
		errors = errors,
	}
end

--- Temporary insert for inspection; caller should destroy when done if unwanted
function Import.importFileToWorkspace(plugin: Plugin): (Instance?, { KeyframeSequence })
	local loaded = Import.promptAndLoad(plugin)
	if #loaded == 0 then
		return nil, {}
	end
	local root = loaded[1]
	root.Name = root.Name ~= "" and root.Name or "ImportedAnimPack"
	root.Parent = workspace
	local seqs = Import.sequencesFromInstances({ root })
	return root, seqs
end

return Import
