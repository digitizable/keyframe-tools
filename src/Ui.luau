--!strict
--[[
	Dock widget UI for Keyframe Tools.
]]

local Config = require(script.Parent.Config)
local Import = require(script.Parent.Import)
local Preview = require(script.Parent.Preview)
local Refine = require(script.Parent.Refine)
local Util = require(script.Parent.Util)

local Ui = {}

local function pad(parent: Instance, px: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
	return p
end

local function listLayout(parent: Instance, gap: number): UIListLayout
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, gap)
	l.Parent = parent
	return l
end

local function sectionLabel(parent: Instance, text: string, order: number): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = "Section"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 20)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.fromRGB(230, 230, 235)
	t.Text = text
	t.LayoutOrder = order
	t.Parent = parent
	return t
end

local function button(parent: Instance, text: string, order: number, primary: boolean?): TextButton
	local b = Instance.new("TextButton")
	b.Name = text:gsub("%s+", "")
	b.Size = UDim2.new(1, 0, 0, 30)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.Text = text
	b.AutoButtonColor = true
	b.LayoutOrder = order
	if primary then
		b.BackgroundColor3 = Color3.fromRGB(45, 120, 220)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		b.BackgroundColor3 = Color3.fromRGB(50, 52, 58)
		b.TextColor3 = Color3.fromRGB(235, 235, 240)
	end
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	b.Parent = parent
	return b
end

local function textBox(parent: Instance, placeholder: string, order: number): TextBox
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 28)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Code
	box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.PlaceholderText = placeholder
	box.Text = ""
	box.BackgroundColor3 = Color3.fromRGB(35, 36, 40)
	box.TextColor3 = Color3.fromRGB(230, 230, 235)
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
	box.LayoutOrder = order
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = box
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 8)
	p.PaddingRight = UDim.new(0, 8)
	p.Parent = box
	box.Parent = parent
	return box
end

local function check(parent: Instance, label: string, order: number, default: boolean): (Frame, BoolValue)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 24)
	row.LayoutOrder = order
	row.Parent = parent

	local value = Instance.new("BoolValue")
	value.Name = "Value"
	value.Value = default
	value.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(20, 20)
	btn.Position = UDim2.fromOffset(0, 2)
	btn.Text = default and "✓" or ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.BackgroundColor3 = default and Color3.fromRGB(45, 120, 220) or Color3.fromRGB(50, 52, 58)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = row
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(28, 0)
	t.Size = UDim2.new(1, -28, 1, 0)
	t.Font = Enum.Font.Gotham
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.fromRGB(210, 210, 220)
	t.Text = label
	t.Parent = row

	btn.MouseButton1Click:Connect(function()
		value.Value = not value.Value
		btn.Text = value.Value and "✓" or ""
		btn.BackgroundColor3 = value.Value and Color3.fromRGB(45, 120, 220) or Color3.fromRGB(50, 52, 58)
	end)

	return row, value
end

local function statusLabel(parent: Instance, order: number): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = "Status"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 48)
	t.Font = Enum.Font.Gotham
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.TextWrapped = true
	t.TextColor3 = Color3.fromRGB(160, 165, 175)
	t.Text = "Ready."
	t.LayoutOrder = order
	t.Parent = parent
	return t
end

function Ui.mount(plugin: Plugin, widget: DockWidgetPluginGui)
	local root = Instance.new("ScrollingFrame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(28, 29, 33)
	root.BorderSizePixel = 0
	root.ScrollBarThickness = 6
	root.CanvasSize = UDim2.new(0, 0, 0, 0)
	root.AutomaticCanvasSize = Enum.AutomaticSize.Y
	root.Parent = widget
	pad(root, 12)
	listLayout(root, 8)

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	sectionLabel(root, "Import", nextOrder())
	local destBox = textBox(root, "Destination path", nextOrder())
	destBox.Text = Config.DEFAULT_DESTINATION
	local mirrorBox = textBox(root, "Mirror path (optional)", nextOrder())
	mirrorBox.Text = Config.DEFAULT_MIRROR
	local _, overwrite = check(root, "Overwrite existing names", nextOrder(), true)
	local _, doMirror = check(root, "Also copy to mirror path", nextOrder(), true)

	local importFileBtn = button(root, "Import .rbxm / .rbxmx…", nextOrder(), true)
	local importSelBtn = button(root, "Import from selection", nextOrder(), false)

	sectionLabel(root, "Refine (selected KeyframeSequence)", nextOrder())
	local _, useWalkPreset = check(root, "Walk preset (milder clamps)", nextOrder(), false)
	local _, useRunPreset = check(root, "Run preset (stronger arm clamps)", nextOrder(), false)
	local refineBtn = button(root, "Refine selection", nextOrder(), true)
	local analyzeBtn = button(root, "Analyze selection", nextOrder(), false)

	sectionLabel(root, "Preview", nextOrder())
	local previewBtn = button(root, "Preview sequence on selected rig", nextOrder(), true)
	local stopBtn = button(root, "Stop preview", nextOrder(), false)

	sectionLabel(root, "Status", nextOrder())
	local status = statusLabel(root, nextOrder())

	local function setStatus(msg: string, isError: boolean?)
		status.Text = msg
		status.TextColor3 = isError and Color3.fromRGB(255, 140, 140) or Color3.fromRGB(160, 165, 175)
	end

	local function selectedSequences(): { KeyframeSequence }
		local Selection = game:GetService("Selection")
		local list: { KeyframeSequence } = {}
		for _, inst in Selection:Get() do
			if inst:IsA("KeyframeSequence") then
				table.insert(list, inst)
			else
				for _, seq in Util.collectKeyframeSequences(inst) do
					table.insert(list, seq)
				end
			end
		end
		return list
	end

	local function refineOptions()
		if useRunPreset.Value then
			return Config.runRefineOptions()
		end
		if useWalkPreset.Value then
			return Config.walkRefineOptions()
		end
		return Config.defaultRefineOptions()
	end

	importFileBtn.MouseButton1Click:Connect(function()
		setStatus("Choose a file…")
		local roots = Import.promptAndLoad(plugin)
		if #roots == 0 then
			setStatus("Import cancelled.")
			return
		end
		local seqs = Import.sequencesFromInstances(roots)
		if #seqs == 0 then
			setStatus("No KeyframeSequences found in file.", true)
			for _, r in roots do
				r:Destroy()
			end
			return
		end
		local mirrorPath = if doMirror.Value then mirrorBox.Text else nil
		local result = Import.copySequences(seqs, destBox.Text, mirrorPath, overwrite.Value)
		-- Cleanup temporary import roots
		for _, r in roots do
			if r.Parent == nil or r:IsDescendantOf(workspace) or r.Parent == nil then
				-- PromptImportFile instances are usually unparented; destroy leftovers
			end
			pcall(function()
				r:Destroy()
			end)
		end
		local names = {}
		for _, s in result.imported do
			table.insert(names, s.Name)
		end
		local msg = `Imported {#result.imported} → {destBox.Text}: {table.concat(names, ", ")}`
		if #result.errors > 0 then
			msg ..= "\n" .. table.concat(result.errors, "\n")
		end
		setStatus(msg, #result.imported == 0)
	end)

	importSelBtn.MouseButton1Click:Connect(function()
		local seqs = Import.sequencesFromSelection()
		if #seqs == 0 then
			setStatus("Select a model/folder containing KeyframeSequences (e.g. AnimSaves).", true)
			return
		end
		local mirrorPath = if doMirror.Value then mirrorBox.Text else nil
		local result = Import.copySequences(seqs, destBox.Text, mirrorPath, overwrite.Value)
		local names = {}
		for _, s in result.imported do
			table.insert(names, s.Name)
		end
		setStatus(`Imported {#result.imported}: {table.concat(names, ", ")}`)
	end)

	refineBtn.MouseButton1Click:Connect(function()
		local seqs = selectedSequences()
		if #seqs == 0 then
			setStatus("Select one or more KeyframeSequences in the Explorer.", true)
			return
		end
		local opts = refineOptions()
		local lines = {}
		for _, seq in seqs do
			local stats = Refine.apply(seq, opts)
			table.insert(
				lines,
				string.format(
					"%s: keys=%d armPos≤%.2f legPos≤%.2f jump≤%.2f",
					stats.name,
					stats.keys,
					stats.maxArmPos,
					stats.maxLegPos,
					stats.maxJump
				)
			)
		end
		setStatus("Refined:\n" .. table.concat(lines, "\n"))
	end)

	analyzeBtn.MouseButton1Click:Connect(function()
		local seqs = selectedSequences()
		if #seqs == 0 then
			setStatus("Select one or more KeyframeSequences.", true)
			return
		end
		local lines = {}
		for _, seq in seqs do
			local stats = Refine.analyze(seq)
			table.insert(
				lines,
				string.format(
					"%s: keys=%d maxArmPos=%.2f maxLegPos=%.2f maxJump=%.2f",
					stats.name,
					stats.keys,
					stats.maxArmPos,
					stats.maxLegPos,
					stats.maxJump
				)
			)
		end
		setStatus("Analyze:\n" .. table.concat(lines, "\n"))
	end)

	previewBtn.MouseButton1Click:Connect(function()
		local seqs = selectedSequences()
		if #seqs == 0 then
			setStatus("Select a KeyframeSequence to preview.", true)
			return
		end
		local ok, err = Preview.playOnSelection(seqs[1], 0.15)
		if ok then
			setStatus(`Previewing “{seqs[1].Name}” on selected rig (looped).`)
		else
			setStatus(err or "Preview failed.", true)
		end
	end)

	stopBtn.MouseButton1Click:Connect(function()
		Preview.stop()
		setStatus("Preview stopped.")
	end)
end

return Ui
