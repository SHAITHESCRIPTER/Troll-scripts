--[[
	SINGULARITY — orbit build (mobile/executor)
	Tap the floating orb to open, drag it wherever it's out of the way.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
while not player do
	task.wait(0.1)
	player = Players.LocalPlayer
end

if getgenv and getgenv().SingularityCleanup then
	pcall(getgenv().SingularityCleanup)
end

local CONFIG = {
	RADIUS           = 9.9999999999999999e16,
	MAX_PARTS        = 160,   -- hard cap, nearest-first. lower = smoother
	SKIP_BIG_ASSEMBLIES = true,
	MAX_ASSEMBLY_JOINTS = 60, -- assemblies with more joints than this are ignored
	MAX_SPEED        = 200,   -- tangential speed
	FULL_SPEED_RANGE = 150,
	ORBIT            = 1.2,   -- >1 = tangential outruns radial, so it circles
	MIN_ORBIT        = 45,    -- inner edge of the ring, well clear of you
	BAND_WIDTH       = 55,    -- how thick the orbit band is
	RADIAL_FACTOR    = 0.4,   -- how hard it still falls inward outside the band
	UNANCHOR         = true,
	DELETE_INSIDE    = false,
	DELETE_RADIUS    = 6,
	UPDATE_HZ        = 30,
	REFRESH_RATE     = 3,
	FLING_BRICKS     = 6,
	FLING_POWER      = 620,
	FLING_COOLDOWN   = 0.5,
}

local ACCENT = Color3.fromRGB(120, 220, 255)
local BG = Color3.fromRGB(16, 17, 21)
local PANEL = Color3.fromRGB(24, 26, 32)
local IDLE = Color3.fromRGB(38, 41, 50)
local MUTED = Color3.fromRGB(150, 155, 165)

local conns = {}
local function track(c)
	conns[#conns + 1] = c
	return c
end

local function notify(text: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "Singularity", Text = text, Duration = 2 })
	end)
end

--------------------------------------------------------------------------------
-- visuals
--------------------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "Singularity"

local core = Instance.new("Part")
core.Shape = Enum.PartType.Ball
core.Size = Vector3.new(10, 10, 10)
core.Color = Color3.new(0, 0, 0)
core.Material = Enum.Material.SmoothPlastic
core.Anchored = true
core.CanCollide = false
core.CanQuery = false
core.CanTouch = false
core.CastShadow = false
core.Parent = folder

local glow = Instance.new("Part")
glow.Shape = Enum.PartType.Ball
glow.Size = Vector3.new(34, 34, 34)
glow.Color = ACCENT
glow.Material = Enum.Material.Neon
glow.Transparency = 0.82
glow.Anchored = true
glow.CanCollide = false
glow.CanQuery = false
glow.CanTouch = false
glow.CastShadow = false
glow.Parent = folder

local light = Instance.new("PointLight")
light.Color = ACCENT
light.Brightness = 4
light.Range = 60
light.Parent = core

local swirl = Instance.new("ParticleEmitter")
swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
swirl.Color = ColorSequence.new(Color3.fromRGB(180, 235, 255))
swirl.Size = NumberSequence.new(1.2, 0.2)
swirl.Lifetime = NumberRange.new(0.5, 1.0)
swirl.Rate = 110
swirl.Speed = NumberRange.new(12, 18)
swirl.SpreadAngle = Vector2.new(180, 180)
swirl.LightEmission = 1
swirl.Parent = core

--------------------------------------------------------------------------------
-- tracking
--------------------------------------------------------------------------------
local running = false
local tracked: { [BasePart]: true } = {}

local function getCenter(): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position or nil
end

local function refresh()
	table.clear(tracked)
	local center = getCenter()
	if not center then return end

	local char = player.Character
	local candidates = {}
	local seen = {}

	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart")
			and not d:IsDescendantOf(folder)
			and not (CONFIG.UNANCHOR == false and d.Anchored)
			and not (char and d:IsDescendantOf(char))
			and not d:GetAttribute("BH_Fling")
		then
			local assembly = d.AssemblyRootPart or d
			if not seen[assembly] then
				seen[assembly] = true
				local big = CONFIG.SKIP_BIG_ASSEMBLIES
					and #assembly:GetJoints() > CONFIG.MAX_ASSEMBLY_JOINTS
				if not big then
					local dist = (center - assembly.Position).Magnitude
					if dist <= CONFIG.RADIUS then
						candidates[#candidates + 1] = { part = d, dist = dist }
					end
				end
			end
		end
	end

	table.sort(candidates, function(a, b) return a.dist < b.dist end)
	for i = 1, math.min(#candidates, CONFIG.MAX_PARTS) do
		tracked[candidates[i].part] = true
	end
end

track(task.spawn(function()
	while true do
		task.wait(CONFIG.REFRESH_RATE)
		if running then refresh() end
	end
end))

--------------------------------------------------------------------------------
-- fling
--------------------------------------------------------------------------------
local lastFling = 0

local function fling(char: Model)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	hrp:SetAttribute("BH_Fling", true)
	hum.PlatformStand = true

	for _ = 1, CONFIG.FLING_BRICKS do
		local p = Instance.new("Part")
		p.Size = Vector3.new(3, 3, 3)
		p.Color = ACCENT
		p.Material = Enum.Material.Neon
		p.CanCollide = false
		p.CanQuery = false
		p.CFrame = hrp.CFrame * CFrame.new(math.random(-4, 4), math.random(0, 4), math.random(-4, 4))
		p:SetAttribute("BH_Fling", true)
		p.Parent = Workspace

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = hrp
		weld.Parent = p
	end

	hrp.AssemblyLinearVelocity = Vector3.new(math.random(-220, 220), CONFIG.FLING_POWER, math.random(-220, 220))
	hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)

	task.delay(0.3, function()
		if hum.Parent then hum.PlatformStand = false end
	end)
	task.delay(2, function()
		if hrp.Parent then hrp:SetAttribute("BH_Fling", nil) end
	end)
	task.delay(3, function()
		for _, p in ipairs(Workspace:GetChildren()) do
			if p:GetAttribute("BH_Fling") and p:IsA("BasePart") then p:Destroy() end
		end
	end)
end

--------------------------------------------------------------------------------
-- physics (30Hz, orbit band)
--------------------------------------------------------------------------------
local accum = 0
local bandOuter = CONFIG.MIN_ORBIT + CONFIG.BAND_WIDTH
local stepDt = 1 / CONFIG.UPDATE_HZ

track(RunService.Heartbeat:Connect(function(dt)
	if not running then return end
	accum += dt
	if accum < stepDt then return end
	local frameDt = math.min(accum, 0.2)
	accum = 0

	local center = getCenter()
	if not center then return end

	core.CFrame = CFrame.new(center) * CFrame.Angles(0, tick() * 0.6, 0)
	glow.CFrame = core.CFrame

	local done: { [BasePart]: true } = {}

	for part in pairs(tracked) do
		if not part.Parent then
			tracked[part] = nil
			continue
		end
		if part:GetAttribute("BH_Fling") then continue end
		if part.Anchored then
			if CONFIG.UNANCHOR then part.Anchored = false else continue end
		end

		local assembly = part.AssemblyRootPart or part
		if done[assembly] then continue end
		done[assembly] = true

		local offset = center - assembly.Position
		local dist = offset.Magnitude
		if dist < 0.1 then continue end

		local dir = offset / dist
		local speed = CONFIG.MAX_SPEED
		if dist > CONFIG.FULL_SPEED_RANGE then
			speed = CONFIG.MAX_SPEED * math.sqrt(CONFIG.FULL_SPEED_RANGE / dist)
		end

		local tangent = dir:Cross(Vector3.yAxis)
		if tangent.Magnitude < 1e-3 then tangent = dir:Cross(Vector3.xAxis) end
		tangent = tangent.Unit

		-- radial: full approach outside the band, ~zero inside it
		local radial
		if dist > bandOuter then
			radial = speed * CONFIG.RADIAL_FACTOR
		elseif dist > CONFIG.MIN_ORBIT then
			radial = speed * CONFIG.RADIAL_FACTOR * ((dist - CONFIG.MIN_ORBIT) / CONFIG.BAND_WIDTH)
		else
			radial = -speed * 1.5 * (1 - dist / CONFIG.MIN_ORBIT)
		end

		local step = speed * frameDt
		local newPos = assembly.Position
			+ dir * (radial * frameDt)
			+ tangent * (step * CONFIG.ORBIT)

		local rot = assembly.CFrame - assembly.CFrame.Position
		assembly.CFrame = CFrame.new(newPos) * rot * CFrame.Angles(0, 0, frameDt * 1.5)
		assembly.AssemblyLinearVelocity = Vector3.zero
		assembly.AssemblyAngularVelocity = Vector3.zero

		if CONFIG.DELETE_INSIDE and dist < CONFIG.DELETE_RADIUS then
			part:Destroy()
			tracked[part] = nil
		end
	end
end))

--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SingularityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local fab = Instance.new("TextButton")
fab.Size = UDim2.fromOffset(54, 54)
fab.Position = UDim2.new(0, 14, 0, 160)
fab.AnchorPoint = Vector2.new(0, 0.5)
fab.BackgroundColor3 = Color3.new(0, 0, 0)
fab.BorderSizePixel = 0
fab.Text = ""
fab.AutoButtonColor = false
fab.Active = true
fab.Parent = gui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)
local fabStroke = Instance.new("UIStroke", fab)
fabStroke.Color = ACCENT
fabStroke.Thickness = 2

local fabDot = Instance.new("Frame")
fabDot.Size = UDim2.fromOffset(18, 18)
fabDot.AnchorPoint = Vector2.new(0.5, 0.5)
fabDot.Position = UDim2.fromScale(0.5, 0.5)
fabDot.BackgroundColor3 = ACCENT
fabDot.BorderSizePixel = 0
fabDot.Parent = fab
Instance.new("UICorner", fabDot).CornerRadius = UDim.new(1, 0)

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 380)
main.AnchorPoint = Vector2.new(1, 0)
main.Position = UDim2.new(1, -12, 0, 74)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(48, 52, 62)
stroke.Thickness = 1

local uiScale = Instance.new("UIScale", main)
local function fit()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(720, 1280)
	uiScale.Scale = math.clamp(math.min(vp.X, vp.Y) / 720, 0.7, 1)
end
fit()
track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fit))

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 40)
bar.BackgroundColor3 = PANEL
bar.BorderSizePixel = 0
bar.Active = true
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -92, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "SINGULARITY"
title.TextSize = 14
title.TextColor3 = ACCENT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local function barBtn(txt: string, x: number, cb: () -> ())
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(34, 34)
	b.Position = UDim2.new(1, x, 0, 3)
	b.BackgroundColor3 = IDLE
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.Text = txt
	b.TextSize = 16
	b.TextColor3 = MUTED
	b.AutoButtonColor = false
	b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(cb)
end

barBtn("—", -42, function()
	main.Visible = false
	fab.Visible = true
end)

local pDrag, pStart, pPos
track(bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch
		or i.UserInputType == Enum.UserInputType.MouseButton1 then
		pDrag = true
		pStart = i.Position
		pPos = main.Position
	end
end))
track(UserInputService.InputChanged:Connect(function(i)
	if pDrag and (i.UserInputType == Enum.UserInputType.Touch
		or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - pStart
		main.Position = UDim2.new(pPos.X.Scale, pPos.X.Offset + d.X,
			pPos.Y.Scale, pPos.Y.Offset + d.Y)
	end
end))

local fDrag, fMoved, fStart, fPos
fab.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch
		or i.UserInputType == Enum.UserInputType.MouseButton1 then
		fDrag = true
		fMoved = false
		fStart = i.Position
		fPos = fab.Position
	end
end)
track(UserInputService.InputChanged:Connect(function(i)
	if fDrag and (i.UserInputType == Enum.UserInputType.Touch
		or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - fStart
		if d.Magnitude > 10 then fMoved = true end
		if fMoved then
			fab.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X,
				fPos.Y.Scale, fPos.Y.Offset + d.Y)
		end
	end
end))
track(UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
		pDrag = false
		if fDrag and not fMoved then
			fab.Visible = false
			main.Visible = true
		end
		fDrag = false
	end
end))

local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -24, 0, 36)
tabRow.Position = UDim2.fromOffset(12, 46)
tabRow.BackgroundTransparency = 1
tabRow.Parent = main
local tl = Instance.new("UIListLayout", tabRow)
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 8)

local pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -24, 1, -132)
pages.Position = UDim2.fromOffset(12, 88)
pages.BackgroundTransparency = 1
pages.Parent = main

local footer = Instance.new("TextButton")
footer.Size = UDim2.new(1, -24, 0, 32)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 12, 1, -10)
footer.BackgroundColor3 = IDLE
footer.BorderSizePixel = 0
footer.Font = Enum.Font.GothamBold
footer.Text = "UNLOAD"
footer.TextSize = 11
footer.TextColor3 = Color3.fromRGB(170, 175, 185)
footer.AutoButtonColor = false
footer.Parent = main
Instance.new("UICorner", footer).CornerRadius = UDim.new(0, 8)

local function makeTab(text: string): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -4, 1, 0)
	b.BackgroundColor3 = IDLE
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextSize = 12
	b.TextColor3 = MUTED
	b.AutoButtonColor = false
	b.Parent = tabRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local function makePage(): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.Parent = pages
	return f
end

local function makeButton(text: string, parent: InstanceType, color: Color3, h: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, h)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextSize = 13
	b.TextColor3 = Color3.fromRGB(240, 245, 250)
	b.AutoButtonColor = false
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local function makeLabel(text: string, parent: InstanceType, h: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, h)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.Text = text
	l.TextSize = 11
	l.TextWrapped = true
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color
	l.Parent = parent
	return l
end

local pageHole = makePage()
local hl = Instance.new("UIListLayout", pageHole)
hl.Padding = UDim.new(0, 8)

local status = makeLabel("STOPPED", pageHole, 18, MUTED)
status.Font = Enum.Font.GothamBold
status.TextSize = 12

local startBtn = makeButton("START", pageHole, Color3.fromRGB(30, 110, 70), 46)
local stopBtn = makeButton("STOP", pageHole, Color3.fromRGB(110, 40, 45), 46)
makeLabel("Parts settle into a ring around you instead of falling in.",
	pageHole, 40, Color3.fromRGB(120, 125, 135))

local pageFling = makePage()
local fl = Instance.new("UIListLayout", pageFling)
fl.Padding = UDim.new(0, 6)

local flingAll = makeButton("FLING EVERYONE", pageFling, Color3.fromRGB(40, 70, 130), 40)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -80)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = pageFling
local sl = Instance.new("UIListLayout", scroll)
sl.Padding = UDim.new(0, 5)

local flingInfo = makeLabel("0 players", pageFling, 18, Color3.fromRGB(120, 125, 135))

local tabs = { { btn = makeTab("BLACK HOLE"), page = pageHole }, { btn = makeTab("FLING"), page = pageFling } }

local function selectTab(n: number)
	for i, t in ipairs(tabs) do
		local on = i == n
		t.page.Visible = on
		TweenService:Create(t.btn, TweenInfo.new(0.12), {
			BackgroundColor3 = on and ACCENT or IDLE,
			TextColor3 = on and Color3.fromRGB(12, 14, 18) or MUTED,
		}):Play()
	end
end

for i, t in ipairs(tabs) do
	t.btn.MouseButton1Click:Connect(function() selectTab(i) end)
end
selectTab(1)

local function rebuildList()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then others[#others + 1] = p end
	end
	flingInfo.Text = #others .. " player" .. (#others == 1 and "" or "s")
	for _, p in ipairs(others) do
		local b = makeButton(p.DisplayName, scroll, IDLE, 34)
		b.TextSize = 12
		b.TextColor3 = ACCENT
		b.MouseButton1Click:Connect(function()
			if os.clock() - lastFling < CONFIG.FLING_COOLDOWN then return end
			lastFling = os.clock()
			if p.Character then
				fling(p.Character)
				b.Text = "FLUNG"
				task.delay(0.6, function()
					if b.Parent then b.Text = p.DisplayName end
				end)
			end
		end)
	end
end

rebuildList()
track(Players.PlayerAdded:Connect(rebuildList))
track(Players.PlayerRemoving:Connect(rebuildList))

startBtn.MouseButton1Click:Connect(function()
	running = true
	folder.Parent = Workspace
	refresh()
	status.Text = "ACTIVE - " .. #tracked .. " parts"
	status.TextColor3 = ACCENT
	notify("Black hole active")
end)

stopBtn.MouseButton1Click:Connect(function()
	running = false
	folder.Parent = nil
	table.clear(tracked)
	status.Text = "STOPPED"
	status.TextColor3 = MUTED
	notify("Black hole stopped")
end)

flingAll.MouseButton1Click:Connect(function()
	if os.clock() - lastFling < CONFIG.FLING_COOLDOWN then return end
	lastFling = os.clock()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			task.spawn(fling, p.Character)
			n += 1
		end
	end
	notify("Flung " .. n .. " player" .. (n == 1 and "" or "s"))
end)

footer.MouseButton1Click:Connect(function()
	cleanupRef()
end)

track(UserInputService.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.RightShift then
		if main.Visible then
			main.Visible = false
			fab.Visible = true
		else
			main.Visible = true
			fab.Visible = false
		end
	end
end))

function cleanupRef()
	running = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	table.clear(tracked)
	pcall(function() gui:Destroy() end)
	pcall(function() folder:Destroy() end)
	if getgenv then getgenv().SingularityCleanup = nil end
end

if getgenv then getgenv().SingularityCleanup = cleanupRef end

notify("Tap the orb to open")
