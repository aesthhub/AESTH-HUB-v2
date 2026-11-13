--[[
  AIM ASSIST + ESP 3D MENU (Roblox LocalScript) - para teste no SEU jogo / Studio
  Local: StarterGui > LocalScript   (ou StarterPlayerScripts)

  Recursos:
  - Menu arrastável pelo título; minimizar vira BOLINHA arrastável
  - Aimbot com FOV ajustável (círculo na tela), suavidade, parte da mira
  - Team Check, Friend Check e Wall Check
  - ESP 3D de verdade (objetos no mundo, não desenho 2D):
      Box 3D, Linha 3D (tracer), Esqueleto 3D, Highlight, Nome/Vida/Distância
  - Botões flutuantes na tela (arrastáveis) para Aimbot, Team Check e ESP
  - Trava para os botões flutuantes não saírem do lugar
  - Mobile friendly (toque, sliders grandes, botões grandes)

  OBS: o Rayfield depende de loadstring/HttpGet, que não funcionam em scripts
  do Studio. Por isso o menu aqui é próprio, sem dependências.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ================= CONFIGURAÇÕES =================
local Settings = {
	-- Aimbot
	Aimbot = false,
	TeamCheck = true,
	FriendCheck = true,
	WallCheck = false,
	AimPart = "Head", -- "Head" ou "Torso"
	FOV = 150,
	ShowFOV = true,
	AimSpeed = 0.3, -- 0.05 (suave) até 1 (instantâneo)

	-- ESP
	ESP = false,
	ESPBox = true,
	ESPTracer = true,
	ESPSkeleton = true,
	ESPInfo = true,
	ESPHighlight = true,
	ESPDistance = 1500,

	-- Botões flutuantes
	BtnAimbot = false,
	BtnTeam = false,
	BtnESP = false,
	Lock = false,
}

local DRAG_THRESHOLD = 6

-- ================= SISTEMA DE ESTADO (sincroniza menu e botões) =================
local listeners = {}

local function onChange(key, fn)
	listeners[key] = listeners[key] or {}
	table.insert(listeners[key], fn)
	fn(Settings[key])
end

local function setSetting(key, value)
	Settings[key] = value
	for _, fn in ipairs(listeners[key] or {}) do
		fn(value)
	end
end

-- ================= CORES =================
local BG = Color3.fromRGB(28, 28, 36)
local ROW = Color3.fromRGB(40, 40, 52)
local ACCENT = Color3.fromRGB(90, 140, 255)
local GREEN = Color3.fromRGB(40, 160, 90)
local RED = Color3.fromRGB(190, 60, 60)
local OFFC = Color3.fromRGB(80, 80, 95)
local GOLD = Color3.fromRGB(255, 200, 60)
local WHITE = Color3.new(1, 1, 1)

-- ================= GUI BASE =================
local gui = Instance.new("ScreenGui")
gui.Name = "AimEspMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0, 8)
	c.Parent = obj
	return c
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function clampToScreen(obj, x, y)
	local screen = gui.AbsoluteSize
	local size = obj.AbsoluteSize
	return math.clamp(x, 0, math.max(0, screen.X - size.X)),
		math.clamp(y, 0, math.max(0, screen.Y - size.Y))
end

-- Arrastar + clique (mouse e toque)
local function makeDraggable(target, handle, opts)
	opts = opts or {}
	local tracking, exceeded = false, false
	local dragInput, startPointer, startPos

	handle.InputBegan:Connect(function(input)
		if isPointer(input) then
			tracking = true
			exceeded = false
			dragInput = input
			startPointer = input.Position
			startPos = target.AbsolutePosition
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not tracking then
			return
		end
		local valid
		if dragInput.UserInputType == Enum.UserInputType.Touch then
			valid = (input == dragInput)
		else
			valid = (input.UserInputType == Enum.UserInputType.MouseMovement)
		end
		if not valid then
			return
		end

		local delta = input.Position - startPointer
		if delta.Magnitude > DRAG_THRESHOLD then
			exceeded = true
		end
		if exceeded and (not opts.canDrag or opts.canDrag()) then
			local x, y = clampToScreen(target, startPos.X + delta.X, startPos.Y + delta.Y)
			target.Position = UDim2.fromOffset(x, y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not tracking or not isPointer(input) then
			return
		end
		local sameTouch = (input == dragInput)
		local bothMouse = input.UserInputType == Enum.UserInputType.MouseButton1
			and dragInput.UserInputType == Enum.UserInputType.MouseButton1
		if sameTouch or bothMouse then
			tracking = false
			if not exceeded and opts.onClick then
				opts.onClick()
			end
		end
	end)
end

-- ================= JANELA DO MENU =================
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(280, 400)
main.Position = UDim2.new(0.5, -140, 0.5, -200)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
corner(main, UDim.new(0, 12))

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 34)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "🎯 Aim & ESP Menu"
title.TextColor3 = WHITE
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(32, 26)
minimize.Position = UDim2.new(1, -38, 0, 4)
minimize.BackgroundColor3 = OFFC
minimize.Text = "—"
minimize.TextColor3 = WHITE
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 14
minimize.Parent = main
corner(minimize, UDim.new(0, 6))

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -38)
scroll.Position = UDim2.fromOffset(0, 36)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = scroll

-- ================= BOLINHA (menu minimizado) =================
local ball = Instance.new("TextButton")
ball.Size = UDim2.fromOffset(54, 54)
ball.BackgroundColor3 = BG
ball.Text = "🎯"
ball.TextSize = 26
ball.AutoButtonColor = false
ball.Visible = false
ball.Parent = gui
corner(ball, UDim.new(1, 0))
local ballStroke = Instance.new("UIStroke")
ballStroke.Thickness = 3
ballStroke.Color = OFFC
ballStroke.Parent = ball

-- ================= CONSTRUTORES DE COMPONENTES =================
local orderCounter = 0
local function nextOrder()
	orderCounter += 1
	return orderCounter
end

local function newRow(height, class)
	local r = Instance.new(class or "Frame")
	r.Size = UDim2.new(1, 0, 0, height)
	r.BackgroundColor3 = ROW
	r.BorderSizePixel = 0
	r.LayoutOrder = nextOrder()
	r.Parent = scroll
	corner(r)
	return r
end

local function addSection(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = ACCENT
	l.Font = Enum.Font.GothamBold
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = nextOrder()
	l.Parent = scroll
end

local function addToggle(text, key)
	local r = newRow(36, "TextButton")
	r.Text = text
	r.TextColor3 = WHITE
	r.Font = Enum.Font.GothamMedium
	r.TextSize = 14
	r.TextXAlignment = Enum.TextXAlignment.Left
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 10)
	p.Parent = r

	local st = Instance.new("TextLabel")
	st.Size = UDim2.fromOffset(48, 24)
	st.AnchorPoint = Vector2.new(1, 0.5)
	st.Position = UDim2.new(1, -8, 0.5, 0)
	st.TextColor3 = WHITE
	st.Font = Enum.Font.GothamBold
	st.TextSize = 12
	st.Parent = r
	corner(st, UDim.new(0, 6))

	onChange(key, function(v)
		st.Text = v and "ON" or "OFF"
		st.BackgroundColor3 = v and GREEN or OFFC
	end)

	r.MouseButton1Click:Connect(function()
		setSetting(key, not Settings[key])
	end)
end

local function addCycle(text, key, options)
	local r = newRow(36, "TextButton")
	r.TextColor3 = WHITE
	r.Font = Enum.Font.GothamMedium
	r.TextSize = 14
	onChange(key, function(v)
		r.Text = text .. ": " .. tostring(v)
	end)
	r.MouseButton1Click:Connect(function()
		local idx = table.find(options, Settings[key]) or 0
		setSetting(key, options[(idx % #options) + 1])
	end)
end

local function addSlider(text, key, min, max, decimals)
	local r = newRow(52, "Frame")

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -70, 0, 22)
	lbl.Position = UDim2.fromOffset(10, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = WHITE
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = r

	local val = Instance.new("TextLabel")
	val.Size = UDim2.fromOffset(60, 22)
	val.Position = UDim2.new(1, -66, 0, 4)
	val.BackgroundTransparency = 1
	val.TextColor3 = ACCENT
	val.Font = Enum.Font.GothamBold
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = r

	-- área de toque grande (28px) com a barra fina dentro
	local hit = Instance.new("Frame")
	hit.Size = UDim2.new(1, -24, 0, 28)
	hit.Position = UDim2.fromOffset(12, 22)
	hit.BackgroundTransparency = 1
	hit.Parent = r

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 0, 0.5, 0)
	bar.BackgroundColor3 = Color3.fromRGB(65, 65, 82)
	bar.BorderSizePixel = 0
	bar.Parent = hit
	corner(bar, UDim.new(1, 0))

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ACCENT
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = bar
	corner(fill, UDim.new(1, 0))

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(20, 20)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = WHITE
	knob.BorderSizePixel = 0
	knob.Parent = bar
	corner(knob, UDim.new(1, 0))

	onChange(key, function(v)
		local rel = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		val.Text = string.format("%." .. decimals .. "f", v)
	end)

	local sliding = false
	local function setFromX(x)
		local rel = math.clamp((x - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
		local v = min + rel * (max - min)
		local m = 10 ^ decimals
		setSetting(key, math.floor(v * m + 0.5) / m)
	end

	hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			sliding = true
			scroll.ScrollingEnabled = false -- evita rolar o menu enquanto arrasta o slider
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if sliding and isPointer(input) then
			sliding = false
			scroll.ScrollingEnabled = true
		end
	end)
end

-- ================= CONTEÚDO DO MENU =================
addSection("🎯 AIMBOT")
addToggle("Aimbot", "Aimbot")
addToggle("Team Check", "TeamCheck")
addToggle("Friend Check", "FriendCheck")
addToggle("Wall Check", "WallCheck")
addCycle("Parte da mira", "AimPart", { "Head", "Torso" })
addSlider("FOV", "FOV", 20, 600, 0)
addToggle("Mostrar círculo do FOV", "ShowFOV")
addSlider("Velocidade da mira", "AimSpeed", 0.05, 1, 2)

addSection("👁 ESP 3D")
addToggle("ESP", "ESP")
addToggle("Box 3D", "ESPBox")
addToggle("Linha 3D (tracer)", "ESPTracer")
addToggle("Esqueleto 3D", "ESPSkeleton")
addToggle("Highlight", "ESPHighlight")
addToggle("Nome / Vida / Distância", "ESPInfo")
addSlider("Distância máxima", "ESPDistance", 100, 3000, 0)

addSection("🔘 BOTÕES NA TELA")
addToggle("Botão do Aimbot", "BtnAimbot")
addToggle("Botão do Team Check", "BtnTeam")
addToggle("Botão do ESP", "BtnESP")
addToggle("Travar botões na tela", "Lock")

-- ================= BOTÕES FLUTUANTES =================
local function createFloatingButton(label, stateKey, showKey, index)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(96, 40)
	b.Position = UDim2.fromOffset(16, 110 + index * 48)
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.AutoButtonColor = false
	b.Visible = false
	b.Parent = gui
	corner(b, UDim.new(0, 10))

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = b

	onChange(stateKey, function(v)
		b.Text = label .. ": " .. (v and "ON" or "OFF")
		b.BackgroundColor3 = v and GREEN or RED
	end)
	onChange("Lock", function(l)
		stroke.Color = l and GOLD or Color3.fromRGB(20, 20, 25)
		stroke.Thickness = l and 3 or 2
	end)
	onChange(showKey, function(v)
		b.Visible = v
	end)

	makeDraggable(b, b, {
		canDrag = function()
			return not Settings.Lock
		end,
		onClick = function()
			setSetting(stateKey, not Settings[stateKey])
		end,
	})
end

createFloatingButton("AIM", "Aimbot", "BtnAimbot", 0)
createFloatingButton("TEAM", "TeamCheck", "BtnTeam", 1)
createFloatingButton("ESP", "ESP", "BtnESP", 2)

-- ================= CÍRCULO DO FOV =================
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = gui
corner(fovCircle, UDim.new(1, 0))
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.5
fovStroke.Color = WHITE
fovStroke.Transparency = 0.2
fovStroke.Parent = fovCircle

local function refreshFOV()
	fovCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
	fovCircle.Visible = Settings.Aimbot and Settings.ShowFOV
	fovStroke.Color = Settings.Aimbot and Color3.fromRGB(90, 255, 140) or WHITE
	ballStroke.Color = (Settings.Aimbot or Settings.ESP) and Color3.fromRGB(40, 200, 110) or OFFC
end
onChange("FOV", refreshFOV)
onChange("ShowFOV", refreshFOV)
onChange("Aimbot", refreshFOV)
onChange("ESP", refreshFOV)

-- ================= MINIMIZAR / BOLINHA =================
makeDraggable(main, title)

minimize.MouseButton1Click:Connect(function()
	local pos = main.AbsolutePosition
	local x, y = clampToScreen(ball, pos.X, pos.Y)
	ball.Position = UDim2.fromOffset(x, y)
	main.Visible = false
	ball.Visible = true
end)

makeDraggable(ball, ball, {
	onClick = function()
		local pos = ball.AbsolutePosition
		local x, y = clampToScreen(main, pos.X, pos.Y)
		main.Position = UDim2.fromOffset(x, y)
		ball.Visible = false
		main.Visible = true
	end,
})

-- ================= LÓGICA: TIMES / AMIGOS =================
local friendCache = {}

local function checkFriend(plr)
	task.spawn(function()
		local ok, res = pcall(function()
			return LocalPlayer:IsFriendsWith(plr.UserId)
		end)
		friendCache[plr] = ok and res or false
	end)
end

local function isFriend(plr)
	return friendCache[plr] == true
end

local function isTeammate(plr)
	return LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team
end

local function isAlive(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

-- ================= LÓGICA: AIMBOT =================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getAimPart(char)
	if Settings.AimPart == "Head" then
		return char:FindFirstChild("Head")
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function isVisible(camera, part, char)
	rayParams.FilterDescendantsInstances = { LocalPlayer.Character, char }
	local origin = camera.CFrame.Position
	return Workspace:Raycast(origin, part.Position - origin, rayParams) == nil
end

local function getTarget(camera)
	local center = camera.ViewportSize / 2
	local bestPart, bestDist

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and isAlive(plr) then
			if not (Settings.TeamCheck and isTeammate(plr))
				and not (Settings.FriendCheck and isFriend(plr)) then
				local part = getAimPart(plr.Character)
				if part then
					local pos, onScreen = camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
						if d <= Settings.FOV and (not bestDist or d < bestDist) then
							if not Settings.WallCheck or isVisible(camera, part, plr.Character) then
								bestPart, bestDist = part, d
							end
						end
					end
				end
			end
		end
	end
	return bestPart
end

RunService:BindToRenderStep("AimAssistMenu", Enum.RenderPriority.Camera.Value + 1, function()
	if not Settings.Aimbot then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local part = getTarget(camera)
	if part then
		local goal = CFrame.lookAt(camera.CFrame.Position, part.Position)
		camera.CFrame = camera.CFrame:Lerp(goal, Settings.AimSpeed)
	end
end)

-- ================= LÓGICA: ESP 3D =================
-- Tudo aqui são objetos REAIS no mundo 3D (adornments/highlight/billboard),
-- por isso as linhas e caixas têm profundidade e perspectiva de verdade.

local R15_BONES = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}

local R6_BONES = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP3D"
espFolder.Parent = Workspace.CurrentCamera

local espObjects = {}

local function newLine(adornee, thickness)
	local l = Instance.new("LineHandleAdornment")
	l.Adornee = adornee
	l.AlwaysOnTop = true
	l.ZIndex = 5
	l.Thickness = thickness or 2
	l.Length = 1
	l.Visible = false
	l.Parent = espFolder
	return l
end

-- Liga o ponto de partida (parte) até uma posição do mundo
local function pointLine(line, fromPart, toPos)
	local localPt = fromPart.CFrame:PointToObjectSpace(toPos)
	if localPt.Magnitude < 0.05 then
		line.Visible = false
		return
	end
	line.CFrame = CFrame.lookAt(Vector3.zero, localPt)
	line.Length = localPt.Magnitude
	line.Visible = true
end

local function removeESP(plr)
	local o = espObjects[plr]
	if o then
		for _, inst in ipairs(o.items) do
			inst:Destroy()
		end
		espObjects[plr] = nil
	end
end

local function createESP(plr)
	removeESP(plr)
	if plr == LocalPlayer then
		return
	end
	local char = plr.Character
	if not char then
		return
	end
	local hum = char:WaitForChild("Humanoid", 5)
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if not hum or not root or plr.Character ~= char then
		return
	end

	local o = { char = char, hum = hum, root = root, items = {}, bones = {} }
	local function track(inst)
		table.insert(o.items, inst)
		return inst
	end

	-- Highlight (contorno através de paredes)
	o.highlight = track(Instance.new("Highlight"))
	o.highlight.Adornee = char
	o.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	o.highlight.FillTransparency = 0.8
	o.highlight.OutlineTransparency = 0
	o.highlight.Enabled = false
	o.highlight.Parent = espFolder

	-- Box 3D
	o.box = track(Instance.new("BoxHandleAdornment"))
	o.box.Adornee = root
	o.box.AlwaysOnTop = true
	o.box.ZIndex = 1
	o.box.Transparency = 0.75
	o.box.Visible = false
	o.box.Parent = espFolder

	-- Linha 3D (tracer)
	o.tracer = track(newLine(root, 1.5))

	-- Esqueleto 3D
	local bones = hum.RigType == Enum.HumanoidRigType.R15 and R15_BONES or R6_BONES
	for _, pair in ipairs(bones) do
		local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
		if a and b then
			table.insert(o.bones, { line =
