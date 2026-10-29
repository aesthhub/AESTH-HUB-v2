
--[[
    AESTH HUB ELITE
    Versão: 1.0 - reestruturada
    LocalScript: StarterPlayer > StarterPlayerScripts

    Recursos:
    - Interface escura com detalhes vermelhos
    - Menu minimizável e botão flutuante arrastável
    - ESP com caixa, nome, distância e linha
    - Esqueleto visual compatível com R6 e R15
    - Highlight de personagens
    - Círculo de FOV visual
    - Informações de Humanoid e vida
    - Limpeza de objetos e tratamento de respawn
    - Sem APIs de executores externos
]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// CONFIGURATION
local CONFIG = {
    Accent = Color3.fromRGB(255, 40, 65),
    Background = Color3.fromRGB(15, 15, 19),
    Panel = Color3.fromRGB(24, 24, 30),
    Text = Color3.fromRGB(245, 245, 248),
    Muted = Color3.fromRGB(160, 160, 170),
    Enemy = Color3.fromRGB(255, 55, 75),

    MaxDistance = 2000,
    FOVRadius = 120,
    UpdateInterval = 0.05,
}

local SETTINGS = {
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

local alive = true
local lastUpdate = 0
local connections = {}
local overlays = {}
local highlightFolder

--// SAFE HELPERS
local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function addConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function make(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function stroke(object, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or CONFIG.Accent,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, object)
end

local function getCamera()
    return Workspace.CurrentCamera
end

local function getCharacterInfo(player)
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoid or not root or not head then
        return nil
    end

    if humanoid.Health <= 0 then
        return nil
    end

    return character, humanoid, root, head
end

local function getRigName(humanoid)
    if not humanoid then
        return "Desconhecido"
    end

    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        return "R6"
    elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
        return "R15"
    end

    return "Outro"
end

local function projectPosition(position)
    local camera = getCamera()
    if not camera then
        return nil, false
    end

    local point, visible = camera:WorldToViewportPoint(position)

    return Vector2.new(point.X, point.Y), visible and point.Z > 0
end

--// HIGHLIGHT CONTAINER
highlightFolder = make("Folder", {
    Name = "AESTH_ClientHighlights"
}, Workspace)

--// GUI
local screenGui = make("ScreenGui", {
    Name = "AESTH_HUB_ELITE",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(330, 440),
    Position = UDim2.new(0.5, -165, 0.5, -220),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    Active = true,
}, screenGui)

round(main, 12)
stroke(main, CONFIG.Accent, 1.4, 0.15)

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
    Active = true,
}, main)

round(header, 12)

-- Cover the lower rounded corners of the header.
make("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, header)

local title = make("TextLabel", {
    Name = "Title",
    Position = UDim2.fromOffset(15, 4),
    Size = UDim2.new(1, -95, 0, 27),
    BackgroundTransparency = 1,
    Text = "AESTH HUB",
    TextColor3 = CONFIG.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true,
}, header)

local subtitle = make("TextLabel", {
    Position = UDim2.fromOffset(16, 29),
    Size = UDim2.new(1, -100, 0, 16),
    BackgroundTransparency = 1,
    Text = "ELITE  •  CLIENT VISUALS",
    TextColor3 = CONFIG.Accent,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minimizeButton = make("TextButton", {
    Name = "Minimize",
    Position = UDim2.new(1, -43, 0, 10),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(45, 25, 31),
    Text = "—",
    TextColor3 = CONFIG.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    AutoButtonColor = true,
}, header)

round(minimizeButton, 8)

local content = make("ScrollingFrame", {
    Name = "Options",
    Position = UDim2.fromOffset(12, 65),
    Size = UDim2.new(1, -24, 1, -77),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = CONFIG.Accent,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)

make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

make("UIPadding", {
    PaddingBottom = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 4),
}, content)

--// DRAGGING
local function makeDraggable(target, handle, onRelease)
    local dragging = false
    local moved = false
    local startPosition
    local startInputPosition
    local activeInput

    addConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        moved = false
        activeInput = input
        startInputPosition = input.Position
        startPosition = target.Position
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if activeInput
            and activeInput.UserInputType == Enum.UserInputType.Touch
            and input ~= activeInput then
            return
        end

        local delta = input.Position - startInputPosition

        if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
            moved = true
        end

        if moved then
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    addConnection(UserInputService.InputEnded:Connect(function(input)
        if not dragging then
            return
        end

        local isMouseRelease =
            input.UserInputType == Enum.UserInputType.MouseButton1

        local isTouchRelease =
            input.UserInputType == Enum.UserInputType.Touch
            and activeInput == input

        if isMouseRelease or isTouchRelease then
            dragging = false
            activeInput = nil

            if onRelease then
                onRelease(moved)
            end
        end
    end))
end

-- Drag only from the title area, not the minimize button.
makeDraggable(main, title)

--// FLOATING ORB
local orb = make("TextButton", {
    Name = "FloatingOrb",
    Size = UDim2.fromOffset(56, 56),
    Position = UDim2.new(1, -78, 0.5, -28),
    BackgroundColor3 = CONFIG.Background,
    Text = "A",
    TextColor3 = CONFIG.Accent,
    Font = Enum.Font.GothamBlack,
    TextSize = 26,
    Visible = false,
    AutoButtonColor = false,
    Active = true,
}, screenGui)

round(orb, 28)
stroke(orb, CONFIG.Accent, 2, 0)

local orbPressStart
local orbDragged = false

makeDraggable(orb, orb, function(wasMoved)
    orbDragged = wasMoved

    if not wasMoved and orbPressStart then
        main.Visible = true
        orb.Visible = false
    end

    orbPressStart = nil
end)

addConnection(orb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        orbPressStart = true
        orbDragged = false
    end
end))

addConnection(minimizeButton.Activated:Connect(function()
    main.Visible = false
    orb.Visible = true
end))

--// OPTION CONTROLS
local optionButtons = {}

local function createSection(text)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -2, 0, 24),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = CONFIG.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, content)

    return label
end

local function createToggle(key, labelText)
    local button = make("TextButton", {
        Size = UDim2.new(1, -2, 0, 38),
        BackgroundColor3 = CONFIG.Panel,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, content)

    round(button, 8)

    local label = make("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -66, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = CONFIG.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    local indicator = make("Frame", {
        Position = UDim2.new(1, -43, 0.5, -9),
        Size = UDim2.fromOffset(32, 18),
        BackgroundColor3 = Color3.fromRGB(65, 65, 73),
        BorderSizePixel = 0,
    }, button)

    round(indicator, 12)

    local knob = make("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(235, 235, 235),
        BorderSizePixel = 0,
    }, indicator)

    round(knob, 12)

    local function refresh()
        local enabled = SETTINGS[key]

        indicator.BackgroundColor3 = enabled
            and CONFIG.Accent
            or Color3.fromRGB(65, 65, 73)

        knob.Position = enabled
            and UDim2.new(1, -15, 0, 3)
            or UDim2.fromOffset(3, 3)

        button.BackgroundColor3 = enabled
            and Color3.fromRGB(38, 22, 28)
            or CONFIG.Panel
    end

    addConnection(button.Activated:Connect(function()
        SETTINGS[key] = not SETTINGS[key]
        refresh()
    end))

    optionButtons[key] = refresh
    refresh()
end

createSection("Visuals")
createToggle("ESP", "Ativar ESP")
createToggle("Box", "Caixa do personagem")
createToggle("Names", "Nome do jogador")
createToggle("Distance", "Distância")
createToggle("Tracers", "Linhas até jogadores")
createToggle("Skeleton", "Esqueleto R6 / R15")
createToggle("Highlight", "Highlight do personagem")

createSection("Humanoid")
createToggle("Health", "Vida do Humanoid")
createToggle("RigInfo", "Mostrar tipo de rig (R6/R15)")

createSection("Extras")
createToggle("FOV", "Círculo visual de FOV")

local footer = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 30),
    BackgroundTransparency = 1,
    Text = "AESTH  •  VISUAL MODE",
    TextColor3 = CONFIG.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
}, content)

--// FOV CIRCLE
local fovCircle = make("Frame", {
    Name = "FOVCircle",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(CONFIG.FOVRadius * 2, CONFIG.FOVRadius * 2),
    BackgroundTransparency = 1,
    Visible = false,
}, screenGui)

round(fovCircle, 999)
stroke(fovCircle, CONFIG.Accent, 1.5, 0.12)

--// OVERLAY OBJECTS
local function makeOverlay(player)
    local folder = make("Folder", {
        Name = "Player_" .. tostring(player.UserId)
    }, screenGui)

    local box = make("Frame", {
        Name = "Box",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, folder)

    stroke(box, CONFIG.Enemy, 1.5, 0)

    local tracer = make("Frame", {
        Name = "Tracer",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = CONFIG.Enemy,
        BorderSizePixel = 0,
        Visible = false,
    }, folder)

    local nameLabel = make("TextLabel", {
        Name = "Name",
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.Text,
        TextStrokeTransparency = 0.35,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Visible = false,
    }, folder)

    local infoLabel = make("TextLabel", {
        Name = "Info",
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.Muted,
        TextStrokeTransparency = 0.35,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Visible = false,
    }, folder)

    local healthBack = make("Frame", {
        Name = "HealthBack",
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderSizePixel = 0,
        Visible = false,
    }, folder)

    local healthFill = make("Frame", {
        Name = "HealthFill",
        BackgroundColor3 = Color3.fromRGB(80, 220, 120),
        BorderSizePixel = 0,
        Visible = false,
    }, healthBack)

    local skeleton = {}

    local function makeBone()
        return make("Frame", {
            Name = "Bone",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = CONFIG.Enemy,
            BorderSizePixel = 0,
            Visible = false,
        }, folder)
    end

    for i = 1, 18 do
        skeleton[i] = makeBone()
    end

    local highlight = make("Highlight", {
        Name = "Highlight",
        Enabled = false,
        FillColor = CONFIG.Enemy,
        OutlineColor = CONFIG.Accent,
        FillTransparency = 0.82,
        OutlineTransparency = 0.12,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    }, highlightFolder)

    overlays[player] = {
        Folder = folder,
        Box = box,
        Tracer = tracer,
        Name = nameLabel,
        Info = infoLabel,
        HealthBack = healthBack,
        HealthFill = healthFill,
        Skeleton = skeleton,
        Highlight = highlight,
    }

    return overlays[player]
end

local function hideOverlay(data)
    if not data then
        return
    end

    data.Box.Visible = false
    data.Tracer.Visible = false
    data.Name.Visible = false
    data.Info.Visible = false
    data.HealthBack.Visible = false
    data.HealthFill.Visible = false

    for _, bone in ipairs(data.Skeleton) do
        bone.Visible = false
    end

    data.Highlight.Enabled = false
    data.Highlight.Adornee = nil
end

local function removeOverlay(player)
    local data = overlays[player]
    if not data then
        return
    end

    pcall(function()
        data.Folder:Destroy()
        data.Highlight:Destroy()
    end)

    overlays[player] = nil
end

local function drawSegment(frame, a, b)
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

--// R6 / R15 SKELETON
local RIG_PAIRS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "HumanoidRootPart"},
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

local R6_PAIRS = {
    {"Head", "Torso"},
    {"Torso", "HumanoidRootPart"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local function drawSkeleton(data, character, humanoid)
    for _, bone in ipairs(data.Skeleton) do
        bone.Visible = false
    end

    if not SETTINGS.ESP or not SETTINGS.Skeleton then
        return
    end

    local pairsToDraw = humanoid.RigType == Enum.HumanoidRigType.R6
        and R6_PAIRS
        or RIG_PAIRS

    local boneIndex = 0

    for _, pair in ipairs(pairsToDraw) do
        local partA = character:FindFirstChild(pair[1])
        local partB = character:FindFirstChild(pair[2])

        if partA and partB
            and partA:IsA("BasePart")
            and partB:IsA("BasePart") then

            local a, visibleA = projectPosition(partA.Position)
            local b, visibleB = projectPosition(partB.Position)

            boneIndex += 1

            if a and b and visibleA and visibleB
                and data.Skeleton[boneIndex] then
                drawSegment(data.Skeleton[boneIndex], a, b)
            end
        end
    end
end

--// PLAYER UPDATE
local function updatePlayer(player)
    local data = overlays[player] or makeOverlay(player)

    if not SETTINGS.ESP and not SETTINGS.Highlight then
        hideOverlay(data)
        return
    end

    local character, humanoid, root, head = getCharacterInfo(player)

    if not character then
        hideOverlay(data)
        return
    end

    local camera = getCamera()
    if not camera then
        hideOverlay(data)
        return
    end

    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter
        and localCharacter:FindFirstChild("HumanoidRootPart")

    local distance = localRoot
        and (root.Position - localRoot.Position).Magnitude
        or 0

    local shouldDraw = SETTINGS.ESP and distance <= CONFIG.MaxDistance

    local rootPoint, rootVisible = projectPosition(root.Position)
    local headPoint, headVisible = projectPosition(
        head.Position + Vector3.new(0, 0.5, 0)
    )

    local onScreen = rootVisible and headVisible
        and rootPoint ~= nil and headPoint ~= nil

    if not shouldDraw or not onScreen then
        data.Box.Visible = false
        data.Tracer.Visible = false
        data.Name.Visible = false
        data.Info.Visible = false
        data.HealthBack.Visible = false
        data.HealthFill.Visible = false

        for _, bone in ipairs(data.Skeleton) do
            bone.Visible = false
        end
    else
        local height = math.max(12, math.abs(rootPoint.Y - headPoint.Y) * 2.1)
        local width = math.max(8, height * 0.48)
        local boxX = rootPoint.X - width / 2
        local boxY = headPoint.Y

        data.Box.Visible = SETTINGS.Box

        if SETTINGS.Box then
            data.Box.Position = UDim2.fromOffset(boxX, boxY)
            data.Box.Size = UDim2.fromOffset(width, height)
        end

        data.Name.Visible = SETTINGS.Names

        if SETTINGS.Names then
            data.Name.Position = UDim2.fromOffset(boxX - 40, boxY - 20)
            data.Name.Size = UDim2.fromOffset(wid
