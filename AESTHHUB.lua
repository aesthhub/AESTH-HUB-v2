
--==================================================
-- AESTH HUB ELITE
-- LocalScript em StarterPlayer > StarterPlayerScripts
-- Roblox Studio | R6 / R15
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    Accent = Color3.fromRGB(255, 40, 65),
    Background = Color3.fromRGB(14, 14, 18),
    Panel = Color3.fromRGB(25, 25, 31),
    Text = Color3.fromRGB(245, 245, 248),
    Muted = Color3.fromRGB(160, 160, 170),
    MaxDistance = 2000,
    FOVRadius = 120,
}

local settings = {
    ESP = false,
    Box = true,
    Names = true,
    Distance = true,
    Tracers = false,
    Skeleton = false,
    Highlight = false,
    Health = true,
    RigInfo = false,
    FOV = false,
}

local connections = {}
local overlays = {}
local alive = true

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function new(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    new("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function outline(object, color, thickness)
    return new("UIStroke", {
        Color = color or CONFIG.Accent,
        Thickness = thickness or 1,
    }, object)
end

local function getCamera()
    return Workspace.CurrentCamera
end

local function getInfo(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoid or not root or not head then return end
    if humanoid.Health <= 0 then return end

    return character, humanoid, root, head
end

local function project(position)
    local camera = getCamera()
    if not camera then return nil, false end

    local point, visible = camera:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), visible and point.Z > 0
end

-- GUI principal
local oldGui = playerGui:FindFirstChild("AESTH_HUB_ELITE")
if oldGui then oldGui:Destroy() end

local gui = new("ScreenGui", {
    Name = "AESTH_HUB_ELITE",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50,
}, playerGui)

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(330, 440),
    Position = UDim2.new(0.5, -165, 0.5, -220),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    Active = true,
}, gui)
corner(main, 12)
outline(main, CONFIG.Accent, 1.5)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, main)
corner(header, 12)

new("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, header)

local title = new("TextLabel", {
    Position = UDim2.fromOffset(14, 5),
    Size = UDim2.new(1, -75, 0, 28),
    BackgroundTransparency = 1,
    Text = "AESTH HUB",
    TextColor3 = CONFIG.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true,
}, header)

new("TextLabel", {
    Position = UDim2.fromOffset(15, 31),
    Size = UDim2.new(1, -80, 0, 16),
    BackgroundTransparency = 1,
    Text = "ELITE  •  VISUAL SYSTEM",
    TextColor3 = CONFIG.Accent,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minimize = new("TextButton", {
    Position = UDim2.new(1, -43, 0, 12),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(50, 25, 32),
    Text = "—",
    TextColor3 = CONFIG.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
}, header)
corner(minimize, 7)

local orb = new("TextButton", {
    Name = "AESTH_FloatingButton",
    Size = UDim2.fromOffset(56, 56),
    Position = UDim2.new(1, -75, 0.5, -28),
    BackgroundColor3 = CONFIG.Background,
    Text = "A",
    TextColor3 = CONFIG.Accent,
    Font = Enum.Font.GothamBlack,
    TextSize = 26,
    Visible = false,
    AutoButtonColor = false,
}, gui)
corner(orb, 28)
outline(orb, CONFIG.Accent, 2)

local options = new("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 66),
    Size = UDim2.new(1, -24, 1, -78),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = CONFIG.Accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
}, main)

new("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, options)

new("UIPadding", {
    PaddingBottom = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 4),
}, options)

-- Arrastar o menu ou botão
local function draggable(target, handle, onClick)
    local dragging = false
    local moved = false
    local startPos
    local startInput
    local activeTouch

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        moved = false
        activeTouch = input.UserInputType == Enum.UserInputType.Touch
            and input or nil
        startInput = input.Position
        startPos = target.Position
    end)

    connect(UIS.InputChanged, function(input)
        if not dragging then return end
        if activeTouch and input ~= activeTouch
            and input.UserInputType == Enum.UserInputType.Touch then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - startInput
        if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
            moved = true
        end

        if moved then
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    connect(UIS.InputEnded, function(input)
        local release = input.UserInputType == Enum.UserInputType.MouseButton1
            or (activeTouch and input == activeTouch)

        if dragging and release then
            dragging = false
            activeTouch = nil
            if onClick then onClick(not moved) end
        end
    end)
end

draggable(main, title)

draggable(orb, orb, function(clicked)
    if clicked then
        main.Visible = true
        orb.Visible = false
    end
end)

connect(minimize.Activated, function()
    main.Visible = false
    orb.Visible = true
end)

-- Opções do menu
local function section(text)
    new("TextLabel", {
        Size = UDim2.new(1, -2, 0, 23),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = CONFIG.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, options)
end

local function toggle(key, labelText)
    local button = new("TextButton", {
        Size = UDim2.new(1, -2, 0, 38),
        BackgroundColor3 = CONFIG.Panel,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, options)
    corner(button, 8)

    new("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = CONFIG.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    local indicator = new("TextLabel", {
        Position = UDim2.new(1, -48, 0.5, -10),
        Size = UDim2.fromOffset(36, 20),
        BackgroundColor3 = Color3.fromRGB(65, 65, 73),
        Text = "OFF",
        TextColor3 = CONFIG.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
    }, button)
    corner(indicator, 6)

    local function refresh()
        indicator.Text = settings[key] and "ON" or "OFF"
        indicator.BackgroundColor3 = settings[key]
            and CONFIG.Accent or Color3.fromRGB(65, 65, 73)
        button.BackgroundColor3 = settings[key]
            and Color3.fromRGB(39, 22, 29) or CONFIG.Panel
    end

    connect(button.Activated, function()
        settings[key] = not settings[key]
        refresh()
    end)

    refresh()
end

section("Visuals")
toggle("ESP", "Ativar ESP")
toggle("Box", "Caixa do personagem")
toggle("Names", "Nome do jogador")
toggle("Distance", "Distância")
toggle("Tracers", "Linhas até jogadores")
toggle("Skeleton", "Esqueleto R6 / R15")
toggle("Highlight", "Highlight")

section("Humanoid")
toggle("Health", "Barra de vida")
toggle("RigInfo", "Tipo de rig R6 / R15")

section("Extras")
toggle("FOV", "Círculo visual FOV")

new("TextLabel", {
    Size = UDim2.new(1, -2, 0, 25),
    BackgroundTransparency = 1,
    Text = "AESTH • CLIENT VISUALS",
    TextColor3 = CONFIG.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
}, options)

-- Círculo de FOV
local fov = new("Frame", {
    Name = "FOVCircle",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(CONFIG.FOVRadius * 2, CONFIG.FOVRadius * 2),
    BackgroundTransparency = 1,
    Visible = false,
}, gui)
corner(fov, 999)
outline(fov, CONFIG.Accent, 1.5)

-- ESP
local highlightFolder = new("Folder", {
    Name = "AESTH_Highlights"
}, Workspace)

local R6_PAIRS = {
    {"Head", "Torso"},
    {"Torso", "HumanoidRootPart"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local R15_PAIRS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function createOverlay(player)
    local folder = new("Folder", {
        Name = "ESP_" .. player.UserId
    }, gui)

    local box = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, folder)
    outline(box, CONFIG.Accent, 1.5)

    local tracer = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, folder)

    local name = new("TextLabel", {
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.Text,
        TextStrokeTransparency = 0.3,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Visible = false,
    }, folder)

    local info = new("TextLabel", {
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.Muted,
        TextStrokeTransparency = 0.3,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Visible = false,
    }, folder)

    local healthBack = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderSizePixel = 0,
        Visible = false,
    }, folder)

    local healthFill = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(80, 220, 120),
        BorderSizePixel = 0,
    }, healthBack)

    local bones = {}
    for i = 1, 15 do
        bones[i] = new("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = CONFIG.Accent,
            BorderSizePixel = 0,
            Visible = false,
        }, folder)
    end

    local highlight = new("Highlight", {
        Enabled = false,
        FillColor = CONFIG.Accent,
        OutlineColor = CONFIG.Accent,
        FillTransparency = 0.82,
        OutlineTransparency = 0.1,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    }, highlightFolder)

    local data = {
        Folder = folder,
        Box = box,
        Tracer = tracer,
        Name = name,
        Info = info,
        HealthBack = healthBack,
        HealthFill = healthFill,
        Bones = bones,
        Highlight = highlight,
    }

    overlays[player] = data
    return data
end

local function hide(data)
    if not data then return end

    data.Box.Visible = false
    data.Tracer.Visible = false
    data.Name.Visible = false
    data.Info.Visible = false
    data.HealthBack.Visible = false
    data.HealthFill.Visible = false

    for _, bone in ipairs(data.Bones) do
        bone.Visible = false
    end

    data.Highlight.Enabled = false
    data.Highlight.Adornee = nil
end

local function removePlayer(player)
    local data = overlays[player]
    if not data then return end

    pcall(function() data.Folder:Destroy() end)
    pcall(function() data.Highlight:Destroy() end)
    overlays[player] = nil
end

local function segment(frame, a, b)
    local delta = b - a
    local length = delta.Magnitude
    if length < 1 then
        frame.Visible = false
        return
    end

    frame.Position = UDim2.fromOffset(a.X, a.Y)
    frame.Size = UDim2.fromOffset(length, 1.5)
    frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    frame.Visible = true
end

local function drawBones(data, character, humanoid)
    for _, bone in ipairs(data.Bones) do
        bone.Visible = false
    end

    if not settings.ESP or not settings.Skeleton then return end

    local pairsList = humanoid.RigType == Enum.HumanoidRigType.R6
        and R6_PAIRS or R15_PAIRS

    for index, pair in ipairs(pairsList) do
        local aPart = character:FindFirstChild(pair[1])
        local bPart = character:FindFirstChild(pair[2])

        if aPart and bPart
            and aPart:IsA("BasePart")
            and bPart:IsA("BasePart") then

            local a, av = project(aPart.Position)
            local b, bv = project(bPart.Position)

            if a and b and av and bv then
                segment(data.Bones[index], a, b)
            end
        end
    end
end

local function updatePlayer(player)
    local data = overlays[player] or createOverlay(player)

    if not settings.ESP and not settings.Highlight then
        hide(data)
        return
    end

    local character, humanoid, root, head = getInfo(player)
    local camera = getCamera()

    if not character or not camera then
        hide(data)
        return
    end

    local localCharacter = localPlayer.Character
    local localRoot = localCharacter
        and localCharacter:FindFirstChild("HumanoidRootPart")

    local distance = localRoot
        and (root.Position - localRoot.Position).Magnitude or 0

    local rootPoint, rootVisible = project(root.Position)
    local headPoint, headVisible = project(head.Position + Vector3.new(0, 0.5, 0))

    local visible = settings.ESP
        and distance <= CONFIG.MaxDistance
        and rootVisible and headVisible
        and rootPoint ~= nil and headPoint ~= nil

    if visible then
        local height = math.max(12, math.abs(rootPoint.Y - headPoint.Y) * 2.1)
        local width = math.max(8, height * 0.48)
        local x = rootPoint.X - width / 2
        local y = headPoint.Y

        data.Box.Visible = settings.Box
        if settings.Box then
            data.Box.Position = UDim2.fromOffset(x, y)
            data.Box.Size = UDim2.fromOffset(width, height)
        end

        data.Name.Visible = settings.Names
        if settings.Names then
            data.Name.Position = UDim2.fromOffset(x - 50, y - 20)
            data.Name.Size = UDim2.fromOffset(width + 100, 18)
            data.Name.Text = player.DisplayName
        end

        data.Tracer.Visible = settings.Tracers
        if settings.Tracers then
            local viewport = camera.ViewportSize
            segment(
                data.Tracer,
                Vector2.new(viewport.X / 2, viewport.Y),
                rootPoint
            )
        end

        local textParts = {}

        if settings.Distance then
            table.insert(textParts, tostring(math.floor(distance)) .. " studs")
        end

        if settings.RigInfo then
            table.insert(textParts, humanoid.RigType.Name)
        end

        data.Info.Visible = #textParts > 0
        data.Info.Text = table.concat(textParts, " • ")
        data.Info.Position = UDim2.fromOffset(x - 40, y + height + 2)
        data.Info.Size = UDim2.fromOffset(width + 80, 16)

        data.HealthBack.Visible = settings.Health
        if settings.Health then
            data.HealthBack.Position = UDim2.fromOffset(x - 6, y)
            data.HealthBack.Size = UDim2.fromOffset(3, height)

            local ratio = humanoid.MaxHealth > 0
                and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                or 0

            data.HealthFill.Size = UDim2.new(1, 0, ratio, 0)
            data.HealthFill.Position = UDim2.new(0, 0, 1, 0)
            data.HealthFill.AnchorPoint = Vector2.new(0, 1)
            data.HealthFill.BackgroundColor3 = Color3.fromRGB(
                math.floor(255 * (1 - ratio)),
                math.floor(220 * ratio),
                65
            )
        else
            data.HealthFill.Visible = false
        end

        drawBones(data, character, humanoid)
    else
        data.Box.Visible = false
        data.Tracer.Visible = false
        data.Name.Visible = false
        data.Info.Visible = false
        data.HealthBack.Visible = false
        data.HealthFill.Visible = false

        for _, bone in ipairs(data.Bones) do
            bone.Visible = false
        end
    end

    data.Highlight.Enabled = settings.Highlight
    data.Highlight.Adornee = settings.Highlight and character or nil
end

local function register(player)
    if player == localPlayer then return end

    if not overlays[player] then
        createOverlay(player)
    end

    connect(player.CharacterRemoving, function()
        hide(overlays[player])
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    register(player)
end

connect(Players.PlayerAdded, register)
connect(Players.PlayerRemoving, removePlayer)

local lastUpdate = 0

connect(RunService.RenderStepped, function()
    if not alive then return end

    local camera = getCamera()

    fov.Visible = settings.FOV and camera ~= nil
    if settings.FOV and camera then
        fov.Position = UDim2.fromOffset(
            camera.ViewportSize.X / 2,
            camera.ViewportSize.Y / 2
        )
    end

    if os.clock() - lastUpdate < 0.05 then return end
    lastUpdate = os.clock()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local success, err = pcall(updatePlayer, player)
            if not success then
                warn("[AESTH HUB] Erro em " .. player.Name .. ": " .. tostring(err))
                hide(overlays[player])
            end
        end
    end
end)

connect(script.Destroying, function()
    alive = false

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for player in pairs(overlays) do
        removePlayer(player)
    end

    pcall(function() highlightFolder:Destroy() end)
    pcall(function() gui:Destroy() end)
end)

print("[AESTH HUB ELITE] Inicializado.")
