-- ============================================================
-- NIGHT SYSTEM – AIMBOT + VISUALS + CAR MODS
-- ============================================================
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/NightSyste/orion.lua/refs/heads/main/night.lua'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

-- ============================================================
-- KONFIGURATION
-- ============================================================
local UserConfig = {
    Visuals = {
        ShowNames = false,
        ShowTeam = false,
        ShowHealth = false,
        ShowWanted = false,
        SkeletonESP = false,
        SkeletonColor = {220, 220, 220},
        TextFont = "Cartoon",
        TextSize = 16,
        MaxRange = 1400
    },
    Graphics = {
        XRay = false,
        Fullbright = false,
        RemoveAtmosphere = false,
        GhostMode = false,
        RainbowGhost = false,
        GhostColor = {255, 255, 255},
        PlayerTrail = false,
        TrailColor = {255, 255, 255},
        RandomSkinLoop = false
    },
    CarMods = {
        GodMode = false,
        InfiniteFuel = false,
        GripBoost = false,
        AntiCrashDamage = false,
        EnterLockedCars = false,
        NumberplateText = "NightHub",
        CarFly = false,
        FlyMode = "Normal",
        MobileCarfly = false,
        VehicleFling = false,
        CarFlyKeybind = "X",
        CarFlySpeed = 100,
        VehicleSound = "Default",
        SuspensionHeight = 1.5,
        JumpHeight = 100,
        ForwardPower = 60,
        JumpKeybind = "F2",
        InstantBoostStrength = 2.5,
        AccelerationMultiplier = 2,
        Armor = 0,
        Brakes = 0,
        Engine = 0,
        WheelColor = {255, 255, 255},
        BodyColor = {255, 255, 255}
    },
    Aimbot = {
        Enabled = false,
        MobileButton = false,
        Keybind = "L",
        WallCheck = true,
        ShowFOV = true,
        FOVRadius = 60,
        TargetPart = "Head",
        Prediction = false,
        Smoothing = 2
    }
}

-- ============================================================
-- AIMBOT CORE
-- ============================================================
local Aimbot = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    Camera = workspace.CurrentCamera,
    FOVring = Drawing.new("Circle"),
    aimbotGui = nil,
    vehicleCache = {},
    cacheTime = {},
    CACHE_DURATION = 0.5
}

Aimbot.FOVring.Visible = UserConfig.Aimbot.ShowFOV and UserConfig.Aimbot.Enabled
Aimbot.FOVring.Thickness = 2
Aimbot.FOVring.Radius = UserConfig.Aimbot.FOVRadius
Aimbot.FOVring.Transparency = 1
Aimbot.FOVring.Color = Color3.fromRGB(127, 255, 0)

local function getVehicle(character)
    local now = tick()
    local cached = Aimbot.vehicleCache[character]
    if cached and Aimbot.cacheTime[character] and (now - Aimbot.cacheTime[character]) < Aimbot.CACHE_DURATION then
        return cached
    end
    local hum = character:FindFirstChildOfClass("Humanoid")
    local vehicle = nil
    if hum and hum.SeatPart then
        local current = hum.SeatPart
        while current ~= workspace and current.Parent ~= nil do
            if current:IsA("Model") then 
                vehicle = current
                break
            end
            current = current.Parent
        end
        if not vehicle then
            vehicle = hum.SeatPart.Parent
        end
    end
    Aimbot.vehicleCache[character] = vehicle
    Aimbot.cacheTime[character] = now
    return vehicle
end

local function isVisible(targetPart)
    if not UserConfig.Aimbot.WallCheck then return true end
    local myChar = Aimbot.LocalPlayer.Character
    if not myChar then return false end
    local ignoreList = {myChar, Aimbot.Camera}
    local targetChar = targetPart.Parent
    local vehicle = getVehicle(targetChar)
    if vehicle then table.insert(ignoreList, vehicle) end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    params.IgnoreWater = true
    local result = workspace:Raycast(Aimbot.Camera.CFrame.Position, targetPart.Position - Aimbot.Camera.CFrame.Position, params)
    return (not result or result.Instance:IsDescendantOf(targetChar) or (vehicle and result.Instance:IsDescendantOf(vehicle)))
end

local function toggleAimbot(state)
    UserConfig.Aimbot.Enabled = state
    Aimbot.FOVring.Visible = state and UserConfig.Aimbot.ShowFOV
end

local function createMobileGui()
    if Aimbot.aimbotGui then return end
    Aimbot.aimbotGui = Instance.new("ScreenGui")
    Aimbot.aimbotGui.ResetOnSpawn = false
    Aimbot.aimbotGui.Parent = Aimbot.LocalPlayer:WaitForChild("PlayerGui")
    local btn = Instance.new("TextButton", Aimbot.aimbotGui)
    btn.Size = UDim2.new(0, 200, 0, 50)
    btn.Position = UDim2.new(0.5, -100, 0.8, 0)
    btn.Text = UserConfig.Aimbot.Enabled and "Aimbot: ON" or "Aimbot: OFF"
    btn.BackgroundColor3 = UserConfig.Aimbot.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function()
        toggleAimbot(not UserConfig.Aimbot.Enabled)
        btn.Text = UserConfig.Aimbot.Enabled and "Aimbot: ON" or "Aimbot: OFF"
        btn.BackgroundColor3 = UserConfig.Aimbot.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end)
end

local function getClosestAimbot()
    local target, shortest = nil, math.huge
    local center = Aimbot.Camera.ViewportSize / 2
    local playerList = Aimbot.Players:GetPlayers()
    for _, p in pairs(playerList) do
        if p ~= Aimbot.LocalPlayer and p.Character then
            local part = p.Character:FindFirstChild(UserConfig.Aimbot.TargetPart)
            if part then
                local pos, onScreen = Aimbot.Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if onScreen and dist <= UserConfig.Aimbot.FOVRadius and isVisible(part) then
                    if dist < shortest then 
                        shortest = dist 
                        target = p 
                    end
                end
            end
        end
    end
    return target
end

local lastFOV = UserConfig.Aimbot.FOVRadius
local lastUpdate = 0
local updateInterval = 1/60

Aimbot.RunService.Heartbeat:Connect(function()
    local now = tick()
    local center = Aimbot.Camera.ViewportSize / 2
    Aimbot.FOVring.Position = center
    Aimbot.FOVring.Visible = UserConfig.Aimbot.Enabled and UserConfig.Aimbot.ShowFOV
    
    if lastFOV ~= UserConfig.Aimbot.FOVRadius then
        Aimbot.FOVring.Radius = UserConfig.Aimbot.FOVRadius
        lastFOV = UserConfig.Aimbot.FOVRadius
    end

    if UserConfig.Aimbot.Enabled and (now - lastUpdate) >= updateInterval then
        lastUpdate = now
        if Aimbot.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserConfig.Aimbot.MobileButton then
            local target = getClosestAimbot()
            if target and target.Character then
                local part = target.Character:FindFirstChild(UserConfig.Aimbot.TargetPart)
                if part then
                    local aimPos = part.Position
                    if UserConfig.Aimbot.Prediction then
                        local vel = part.AssemblyLinearVelocity
                        local veh = getVehicle(target.Character)
                        if veh and veh.PrimaryPart then 
                            vel = veh.PrimaryPart.AssemblyLinearVelocity
                        end
                        aimPos = aimPos + (vel * 0.0575)
                    end
                    local smoothing = (11 - UserConfig.Aimbot.Smoothing) / 10
                    Aimbot.Camera.CFrame = Aimbot.Camera.CFrame:Lerp(
                        CFrame.new(Aimbot.Camera.CFrame.Position, aimPos), 
                        smoothing
                    )
                end
            end
        end
    end
end)

if UserConfig.Aimbot.MobileButton then
    createMobileGui()
end

-- ============================================================
-- VISUALS / ESP
-- ============================================================
local Settings = {
    MaxDist = UserConfig.Visuals.MaxRange,
    Font = Enum.Font.Cartoon,
    TextSize = UserConfig.Visuals.TextSize,
    Visuals = {
        Names = UserConfig.Visuals.ShowNames,
        Team = UserConfig.Visuals.ShowTeam,
        Wanted = UserConfig.Visuals.ShowWanted,
        Health = UserConfig.Visuals.ShowHealth,
    },
    Skeleton = {
        Enabled = UserConfig.Visuals.SkeletonESP,
        Color = Color3.fromRGB(UserConfig.Visuals.SkeletonColor[1], UserConfig.Visuals.SkeletonColor[2], UserConfig.Visuals.SkeletonColor[3]),
        Thickness = 2.1
    }
}

local Cache = {}
local SkelDraws = {}
local Connections = {}

local Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local FontOptions = {
    ["Gotham Bold"] = Enum.Font.GothamBold,
    ["Arial"] = Enum.Font.Arial,
    ["Ubuntu"] = Enum.Font.Ubuntu,
    ["Cartoon"] = Enum.Font.Cartoon,
    ["Bangers"] = Enum.Font.Bangers,
    ["Luckiest Guy"] = Enum.Font.LuckiestGuy,
    ["Arcade"] = Enum.Font.Arcade,
    ["Highway"] = Enum.Font.Highway,
    ["Jura"] = Enum.Font.Jura,
    ["SciFi"] = Enum.Font.SciFi,
    ["Antique"] = Enum.Font.Antique
}

for name, font in pairs(FontOptions) do
    if font == Settings.Font then
        Settings.Font = font
        break
    end
end

local function GetHealthColor(hum)
    local hp = hum.Health
    if hp <= 30 then
        return Color3.fromRGB(255, 0, 0)
    end
    local percentage = math.clamp(hp / hum.MaxHealth, 0, 1)
    local r = percentage < 0.5 and 1 or 2 * (1 - percentage)
    local g = percentage > 0.5 and 1 or 2 * percentage
    return Color3.new(r, g, 0)
end

local function UpdateAllFonts()
    for _, data in pairs(Cache) do
        for _, label in pairs(data.Labels) do
            label.Font = Settings.Font
            label.TextSize = Settings.TextSize
        end
    end
end

local function ClearSkeleton(player)
    if SkelDraws[player] then
        for _, line in pairs(SkelDraws[player]) do
            line.Visible = false
            line:Remove()
        end
        SkelDraws[player] = nil
    end
end

local function CreateSkeleton(player)
    if player == LocalPlayer then return end
    ClearSkeleton(player)
    local lines = {}
    for i = 1, #Bones do
        local line = Drawing.new("Line")
        line.Color = Settings.Skeleton.Color
        line.Thickness = Settings.Skeleton.Thickness
        line.Transparency = 1
        line.Visible = false
        table.insert(lines, line)
    end
    SkelDraws[player] = lines
end

local function UpdateSkeleton()
    if not Settings.Skeleton.Enabled then
        for _, lines in pairs(SkelDraws) do
            for _, line in pairs(lines) do
                line.Visible = false
            end
        end
        return
    end
    
    for skelPlayer, lines in pairs(SkelDraws) do
        local skelChar = skelPlayer.Character  
        local shouldDraw = false
        
        if skelChar then
            local root = skelChar:FindFirstChild("HumanoidRootPart")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if root and myRoot then
                if (root.Position - myRoot.Position).Magnitude <= Settings.MaxDist then
                    shouldDraw = true
                end
            end
        end
        
        if not shouldDraw then
            for _, line in pairs(lines) do
                line.Visible = false
            end
        else
            for i, bonePair in ipairs(Bones) do
                local part1 = skelChar:FindFirstChild(bonePair[1])
                local part2 = skelChar:FindFirstChild(bonePair[2])
                local line = lines[i]
                
                if part1 and part2 then
                    local v1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                    local v2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                    
                    if onScreen1 and onScreen2 and v1.Z > 0 and v2.Z > 0 then
                        line.From = Vector2.new(v1.X, v1.Y)
                        line.To = Vector2.new(v2.X, v2.Y)
                        line.Color = Settings.Skeleton.Color
                        line.Thickness = Settings.Skeleton.Thickness
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        end
    end
end

local function CreateLabel(name, parent, color, size)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.Font = Settings.Font
    lbl.TextSize = size or 14
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.RichText = true
    lbl.Visible = false
    lbl.Parent = parent
    return lbl
end

local function AddESP(player)
    if Cache[player] or player == LocalPlayer then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_" .. player.Name
    bb.Size = UDim2.new(0, 250, 0, 100)
    bb.AlwaysOnTop = true
    bb.ExtentsOffset = Vector3.new(0, 2.5, 0)
    bb.Enabled = false
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = bb
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 2)
    layout.Parent = frame
    
    local labels = {
        Name = CreateLabel("1_Name", frame, Color3.new(1,1,1), 14),
        TeamHP = CreateLabel("2_TeamHP", frame, nil, 13),
        Wanted = CreateLabel("3_Wanted", frame, Color3.fromRGB(255,215,0), 16),
    }
    Cache[player] = {Gui = bb, Labels = labels}
    if Settings.Skeleton.Enabled then CreateSkeleton(player) end
end

local function RemoveESP(player)
    if Cache[player] then
        Cache[player].Gui:Destroy()
        Cache[player] = nil
    end
    ClearSkeleton(player)
end

local function UpdateESP()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for player, data in pairs(Cache) do
        local playerChar = player.Character  
        local head = playerChar and playerChar:FindFirstChild("Head")
        local root = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
        local hum = playerChar and playerChar:FindFirstChild("Humanoid")
        if playerChar and head and root and hum and myRoot then
            local dist = (root.Position - myRoot.Position).Magnitude
            data.Gui.MaxDistance = Settings.MaxDist
            if dist < Settings.MaxDist then
                data.Gui.Parent = head
                data.Gui.Enabled = true
                local vis = Settings.Visuals
                
                data.Labels.Name.Visible = vis.Names
                data.Labels.Name.Text = vis.Names and player.DisplayName or ""
                data.Labels.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
                
                data.Labels.TeamHP.Visible = (vis.Team or vis.Health)
                local teamStr = vis.Team and (player.Team and player.Team.Name or "No Team") or ""
                local hpStr = ""
                if vis.Health then
                    local dynamicColor = GetHealthColor(hum)
                    local r, g, b = math.floor(dynamicColor.R * 255), math.floor(dynamicColor.G * 255), math.floor(dynamicColor.B * 255)
                    local spacing = vis.Team and " " or ""
                    hpStr = string.format("%s<font color='rgb(%d,%d,%d)'>[%d]</font>", spacing, r, g, b, math.floor(hum.Health))
                end
                data.Labels.TeamHP.Text = teamStr .. hpStr
                data.Labels.TeamHP.TextColor3 = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
                
                local isWanted = root:GetAttribute("IsWanted")
                data.Labels.Wanted.Visible = vis.Wanted and isWanted
                data.Labels.Wanted.Text = "⭐ WANTED ⭐"
                data.Labels.Wanted.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                data.Gui.Enabled = false
            end
        else
            data.Gui.Enabled = false
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end

table.insert(Connections, Players.PlayerAdded:Connect(function(p)
    AddESP(p)
    p.CharacterAdded:Connect(function()
        if Settings.Skeleton.Enabled then CreateSkeleton(p) end
    end)
end))

table.insert(Connections, Players.PlayerRemoving:Connect(RemoveESP))
table.insert(Connections, RunService.Heartbeat:Connect(UpdateESP))
table.insert(Connections, RunService.RenderStepped:Connect(UpdateSkeleton))

-- ============================================================
-- GRAPHICS / VISUALS
-- ============================================================
local xrayCache = {}
local xrayEnabled = UserConfig.Graphics.XRay

local function toggleXRay(val)
    xrayEnabled = val
    UserConfig.Graphics.XRay = val
    if val then
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent ~= LocalPlayer.Character then
                xrayCache[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 0.5
            end
        end
    else
        for part, originalValue in pairs(xrayCache) do
            if part and part.Parent then
                part.LocalTransparencyModifier = originalValue
            end
        end
        xrayCache = {}
    end
end

local originalLightingProps = {}
local fullbrightEnabled = UserConfig.Graphics.Fullbright

local function toggleFullbright(val)
    fullbrightEnabled = val
    UserConfig.Graphics.Fullbright = val
    if val then
        originalLightingProps.Brightness = Lighting.Brightness
        originalLightingProps.ClockTime = Lighting.ClockTime
        originalLightingProps.FogEnd = Lighting.FogEnd
        originalLightingProps.GlobalShadows = Lighting.GlobalShadows
        originalLightingProps.OutdoorAmbient = Lighting.OutdoorAmbient
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        for prop, value in pairs(originalLightingProps) do
            Lighting[prop] = value
        end
    end
end

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local atmosphereConnection = nil
local removeAtmosEnabled = UserConfig.Graphics.RemoveAtmosphere

local function freezeAtmosphere()
    if atmosphere and atmosphere.Parent then
        atmosphere.Density = 0
        atmosphere.Haze = 0
        atmosphere.Glare = 0
    end
end

local function toggleRemoveAtmosphere(val)
    removeAtmosEnabled = val
    UserConfig.Graphics.RemoveAtmosphere = val
    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    
    if val then
        if atmosphere then
            freezeAtmosphere()
            if atmosphereConnection then atmosphereConnection:Disconnect() end
            atmosphereConnection = atmosphere.Changed:Connect(freezeAtmosphere)
        end
    else
        if atmosphereConnection then
            atmosphereConnection:Disconnect()
            atmosphereConnection = nil
        end
        if atmosphere then
            atmosphere.Density = 0.3
            atmosphere.Haze = 0
            atmosphere.Glare = 0
        end
    end
end

-- ============================================================
-- GHOST MODE
-- ============================================================
local ghostColor = Color3.fromRGB(UserConfig.Graphics.GhostColor[1], UserConfig.Graphics.GhostColor[2], UserConfig.Graphics.GhostColor[3])
local ghostEnabled = UserConfig.Graphics.GhostMode
local rainbowGhost = UserConfig.Graphics.RainbowGhost
local originalColors = {}
local rainbowConnection = nil

local function applyGhostEffect(val)
    local character = LocalPlayer.Character
    if not character then return end

    if val then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if not originalColors[part] then
                    originalColors[part] = part.Color
                end
                part.Material = Enum.Material.ForceField
                if not rainbowGhost then
                    part.Color = ghostColor
                end
            end
        end
    else
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if originalColors[part] then
                    part.Color = originalColors[part]
                end
                part.Material = Enum.Material.SmoothPlastic
            end
        end
        originalColors = {}
    end
end

local function startRainbow()
    if rainbowConnection then rainbowConnection:Disconnect() end
    local hue = 0
    rainbowConnection = RunService.Heartbeat:Connect(function()
        if not ghostEnabled or not rainbowGhost then return end
        local character = LocalPlayer.Character
        if character then
            hue = (hue + 0.005) % 1
            local rainbowColor = Color3.fromHSV(hue, 1, 1)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Color = rainbowColor
                end
            end
        end
    end)
end

local function stopRainbow()
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end
    if ghostEnabled then
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Color = ghostColor
                end
            end
        end
    end
end

-- ============================================================
-- PLAYER TRAIL
-- ============================================================
local currentTrails = {}
local trailAttachments = {}
local trailColor = Color3.fromRGB(UserConfig.Graphics.TrailColor[1], UserConfig.Graphics.TrailColor[2], UserConfig.Graphics.TrailColor[3])
local trailEnabled = UserConfig.Graphics.PlayerTrail

local function createTrail(arm)
    local att0 = Instance.new("Attachment", arm)
    att0.Position = Vector3.new(0, 0, 0)
    local att1 = Instance.new("Attachment", arm)
    att1.Position = Vector3.new(0, -1, 0)
    local trail = Instance.new("Trail")
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Color = ColorSequence.new(trailColor)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Lifetime = 1.2
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.MinLength = 0.05
    trail.TextureMode = Enum.TextureMode.Stretch
    trail.Parent = arm
    return trail, att0, att1
end

local function toggleTrail(val)
    trailEnabled = val
    UserConfig.Graphics.PlayerTrail = val
    if val then
        local char = LocalPlayer.Character
        if char then
            if char:FindFirstChild("Left Arm") then
                local t, a0, a1 = createTrail(char["Left Arm"])
                table.insert(currentTrails, t)
                table.insert(trailAttachments, a0)
                table.insert(trailAttachments, a1)
            elseif char:FindFirstChild("LeftUpperArm") then
                local t, a0, a1 = createTrail(char["LeftUpperArm"])
                table.insert(currentTrails, t)
                table.insert(trailAttachments, a0)
                table.insert(trailAttachments, a1)
            end
            if char:FindFirstChild("Right Arm") then
                local t, a0, a1 = createTrail(char["Right Arm"])
                table.insert(currentTrails, t)
                table.insert(trailAttachments, a0)
                table.insert(trailAttachments, a1)
            elseif char:FindFirstChild("RightUpperArm") then
                local t, a0, a1 = createTrail(char["RightUpperArm"])
                table.insert(currentTrails, t)
                table.insert(trailAttachments, a0)
                table.insert(trailAttachments, a1)
            end
        end
    else
        for _, trail in pairs(currentTrails) do trail:Destroy() end
        for _, att in pairs(trailAttachments) do att:Destroy() end
        currentTrails = {}
        trailAttachments = {}
    end
end

-- ============================================================
-- SKIN CHANGER / RANDOM SKIN LOOP
-- ============================================================
_G.ST = {Lp = UserConfig.Graphics.RandomSkinLoop}
local P = Players
local L = LocalPlayer

function _G.ST.C(t)
    local c, tc = L.Character, t and t.Character
    if not c or not tc then return end
    for _, v in next, c:GetChildren() do
        if v:IsA("Clothing") or v:IsA("ShirtGraphic") then v:Destroy() end
    end
    for _, v in next, tc:GetChildren() do
        if v:IsA("Clothing") or v:IsA("ShirtGraphic") then v:Clone().Parent = c end
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            local p = c:FindFirstChild(v.Name)
            if p then p.BrickColor = v.BrickColor p.Material = v.Material end
        end
    end
    local h, th = c:FindFirstChild("Head"), tc:FindFirstChild("Head")
    if h and th then
        for _, d in next, h:GetChildren() do if d:IsA("Decal") then d:Destroy() end end
        local f = th:FindFirstChildOfClass("Decal")
        if f then f:Clone().Parent = h end
    end
end

function _G.ST.G()
    local t = {}
    for _, v in next, P:GetPlayers() do if v ~= L then table.insert(t, v.Name) end end
    return t
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.ST.Lp then
            local pl = P:GetPlayers()
            local r = pl[math.random(1, #pl)]
            if r ~= L then _G.ST.C(r) end
        end
    end
end)

-- ============================================================
-- VEHICLE GODMODE & INFINITE FUEL
-- ============================================================
local VehicleFeatures = {
    godMode = UserConfig.CarMods.GodMode,
    infiniteFuel = UserConfig.CarMods.InfiniteFuel,
    lastVehicle = nil,
    player = LocalPlayer,
    
    getVehicle = function(self)
        if not self.lastVehicle or not self.lastVehicle.Parent then
            local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
            self.lastVehicle = vehiclesFolder and vehiclesFolder:FindFirstChild(self.player.Name)
        end
        return self.lastVehicle
    end,
    
    update = function(self)
        if not (self.godMode or self.infiniteFuel) then return end
        local vehicle = self:getVehicle()
        if not vehicle then return end
        vehicle:SetAttribute("IsOn", true)
        if self.godMode then
            vehicle:SetAttribute("currentHealth", 500)
        end
        if self.infiniteFuel then
            vehicle:SetAttribute("currentFuel", 99999)
        end
    end,
    
    reset = function(self)
        if self.lastVehicle then
            if not self.godMode then
                self.lastVehicle:SetAttribute("currentHealth", 100)
            end
            if not self.infiniteFuel then
                self.lastVehicle:SetAttribute("currentFuel", 100)
            end
        end
        if not self.godMode and not self.infiniteFuel then
            self.lastVehicle = nil
        end
    end
}

local lastUpdate = 0
getgenv().VehicleConnection = RunService.Heartbeat:Connect(function()
    if tick() - lastUpdate >= 0.1 then
        VehicleFeatures:update()
        lastUpdate = tick()
    end
end)

-- ============================================================
-- GRIP BOOST
-- ============================================================
local function toggleGripBoost(Value)
    UserConfig.CarMods.GripBoost = Value
    local success, err = pcall(function()
        if not getgenv().GripBoost then
            getgenv().GripBoost = {
                configured = false,
                originalValues = {},
                configTable = nil
            }
        end
        local config = getgenv().GripBoost
        if not config.configured then
            local targetFunction = nil
            for _, v in pairs(getgc()) do
                local success, info = pcall(function() return getinfo(v) end)
                if success and info and info.name == "handleSteering" then
                    for i = 1, 100 do
                        local upSuccess, upValue = pcall(debug.getupvalue, v, i)
                        if upSuccess and type(upValue) == "table" and upValue.maxSteeringAngle then
                            targetFunction = v
                            config.configTable = upValue
                            break
                        end
                        if not upSuccess then break end
                    end
                end
                if targetFunction then break end
            end
            if config.configTable then
                local value = config.configTable
                config.originalValues = {
                    maxSteeringAngle = value.maxSteeringAngle,
                    steeringModifierSpeed = value.steeringModifierSpeed,
                    steeringSpeed = value.steeringSpeed,
                    steerBackMultiplier = value.steerBackMultiplier,
                    minSteer = value.minSteer
                }
                config.configured = true
            end
        end
        if config.configured and config.configTable then
            if Value then
                config.configTable.maxSteeringAngle = 25
                config.configTable.steeringModifierSpeed = 10
                config.configTable.steeringSpeed = 6
                config.configTable.steerBackMultiplier = 1.2
                config.configTable.minSteer = 0.03
            else
                config.configTable.maxSteeringAngle = config.originalValues.maxSteeringAngle or 8
                config.configTable.steeringModifierSpeed = config.originalValues.steeringModifierSpeed or 35
                config.configTable.steeringSpeed = config.originalValues.steeringSpeed or 1.5
                config.configTable.steerBackMultiplier = config.originalValues.steerBackMultiplier or 3
                config.configTable.minSteer = config.originalValues.minSteer or 0.15
            end
        end
    end)
    if not success then
        warn("Grip Boost Error: " .. tostring(err))
    end
end

-- ============================================================
-- ANTI CRASH DAMAGE
-- ============================================================
local antiDamageEnabled = UserConfig.CarMods.AntiCrashDamage
local currentVehicle = nil

local function findPlayerVehicle()
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        return humanoid.SeatPart.Parent
    end
    return nil
end

local function toggleAntiCrashDamage(Value)
    UserConfig.CarMods.AntiCrashDamage = Value
    antiDamageEnabled = Value
    if Value then
        task.spawn(function()
            while antiDamageEnabled do
                local vehicle = findPlayerVehicle()
                if vehicle ~= currentVehicle then
                    if currentVehicle then
                        pcall(function() currentVehicle:SetAttribute("IsBeingTowed", false) end)
                    end
                    currentVehicle = vehicle
                end
                if currentVehicle then
                    pcall(function() currentVehicle:SetAttribute("IsBeingTowed", true) end)
                end
                task.wait(0.5)
            end
        end)
    else
        antiDamageEnabled = false
        if currentVehicle then
            pcall(function() currentVehicle:SetAttribute("IsBeingTowed", false) end)
            currentVehicle = nil
        end
    end
end

-- ============================================================
-- ENTER LOCKED CARS
-- ============================================================
local mouse = LocalPlayer:GetMouse()
local enterLockedActive = UserConfig.CarMods.EnterLockedCars

mouse.Button1Down:Connect(function()
    if not enterLockedActive then return end
    local target = mouse.Target
    if not target then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    local model = target:FindFirstAncestorOfClass("Model") or target.Parent
    if not model then return end
    local foundSeat = nil
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            local name = obj.Name:lower()
            if name:find("beifahrer") or name:find("passenger") or name:find("copilot") then
                foundSeat = obj
                break
            end
        end
    end
    if not foundSeat then
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
                foundSeat = obj
                break
            end
        end
    end
    if foundSeat then
        foundSeat.Locked = false
        hrp.CFrame = foundSeat.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.1)
        foundSeat:Sit(humanoid)
    end
end)

-- ============================================================
-- NUMBERPLATE
-- ============================================================
local savedPlates = {}

local function setNumberplateText(txt)
    UserConfig.CarMods.NumberplateText = txt
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, part in ipairs(vehiclesFolder:GetDescendants()) do
            if part:IsA("SurfaceGui") and part.Parent and part.Parent:IsA("BasePart") then
                local dist = (part.Parent.Position - root.Position).Magnitude
                if dist < 200 then
                    local label = part:FindFirstChildWhichIsA("TextLabel")
                    if label then label.Text = txt end
                end
            end
        end
    end
end

local function toggleInvisibleNumberplate(state)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, part in ipairs(vehiclesFolder:GetDescendants()) do
            if part:IsA("SurfaceGui") and part.Parent and part.Parent:IsA("BasePart") then
                local dist = (part.Parent.Position - root.Position).Magnitude
                if dist < 200 then
                    local label = part:FindFirstChildWhichIsA("TextLabel")
                    if label then
                        if state then
                            if not savedPlates[label] then
                                savedPlates[label] = label.Text
                            end
                            label.Text = ""
                        else
                            if savedPlates[label] then
                                label.Text = savedPlates[label]
                                savedPlates[label] = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- CAR FLY MIT FLY MODES
-- ============================================================
getgenv().CarFly = getgenv().CarFly or {}
local CF = getgenv().CarFly

local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local vehicles = Workspace:WaitForChild("Vehicles")

CF.enabled = UserConfig.CarMods.CarFly
CF.speed = UserConfig.CarMods.CarFlySpeed * 7.77
CF.lastPos = nil
CF.lastLook = nil
CF.flingEnabled = UserConfig.CarMods.VehicleFling
CF.flingActive = false
CF.flingStart = 0
CF.mobileEnabled = UserConfig.CarMods.MobileCarfly
CF.mobileGui = nil
CF.moveU, CF.moveD, CF.moveL, CF.moveR = false, false, false, false
CF.flyMode = UserConfig.CarMods.FlyMode or "Normal"
CF.spinRotation = 0
CF.spinSpeed = 1,4

local singleExitDone = false
local safeFlyConn, autoEnterConn
local lastEnterTime = 0

local function enterVehicle()
    if not CF.enabled then return false end
    local vehicle = vehicles:FindFirstChild(LocalPlayer.Name)
    if vehicle and char:FindFirstChild("Humanoid") then
        local seat = vehicle:FindFirstChild("DriveSeat")
        if seat then
            seat:Sit(char.Humanoid)
            return true
        end
    end
    return false
end

local function performSingleExit()
    if singleExitDone or not CF.enabled or CF.flingEnabled then return end
    local hum = char and char:FindFirstChild("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart.Name == "DriveSeat" then
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        task.delay(0.2, function()
            if CF.enabled and not CF.flingEnabled then
                enterVehicle()
                singleExitDone = true
            end
        end)
    end
end

local function startSafeFly()
    if safeFlyConn then return end
    singleExitDone = false
    local singleExitTimer = false
    safeFlyConn = RunService.Heartbeat:Connect(function()
        if CF.enabled and not CF.flingEnabled then
            local hum = char and char:FindFirstChild("Humanoid")
            local currentTime = tick()
            if hum then
                if not singleExitTimer then
                    singleExitTimer = true
                    task.delay(3, performSingleExit)
                end
                if not hum.SeatPart or hum.SeatPart.Name ~= "DriveSeat" then
                    if (currentTime - lastEnterTime) > 0.5 then
                        lastEnterTime = currentTime
                        local success = enterVehicle()
                        if not success then
                            task.wait(0.1)
                            enterVehicle()
                        end
                    end
                end
            end
        end
    end)
end

local function stopSafeFly()
    if safeFlyConn then
        safeFlyConn:Disconnect()
        safeFlyConn = nil
    end
    singleExitDone = false
end

local function turnCarOff()
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        local pVehicle = vehiclesFolder:FindFirstChild(LocalPlayer.Name)
        if pVehicle and pVehicle:IsA("Model") then
            pVehicle:SetAttribute("IsOn", false)
            local hum = pVehicle:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = 500
                hum.Health = 500
            end
        end
    end
end

local function createMobileControls()
    if CF.mobileGui then CF.mobileGui:Destroy() end
    local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    CF.mobileGui = sg
    sg.Name = "MobileCarFlyControls"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 150, 0, 180)
    f.Position = UDim2.new(0.5, -75, 0.5, -90)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    f.BackgroundTransparency = 0.3
    f.Active = true
    f.Draggable = true
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    local c1 = Instance.new("UICorner", f)
    c1.CornerRadius = UDim.new(0, 8)
    local tog = Instance.new("TextButton", f)
    tog.Size = UDim2.new(1, -20, 0, 35)
    tog.Position = UDim2.new(0, 10, 0, 10)
    tog.BackgroundColor3 = CF.mobileEnabled and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
    tog.Text = CF.mobileEnabled and "Mobile Controls ON" or "Mobile Controls OFF"
    tog.TextColor3 = Color3.new(1,1,1)
    tog.Font = Enum.Font.SourceSansBold
    tog.TextSize = 16
    tog.AutoButtonColor = false
    local c2 = Instance.new("UICorner", tog)
    c2.CornerRadius = UDim.new(0, 6)
    tog.MouseButton1Click:Connect(function()
        CF.mobileEnabled = not CF.mobileEnabled
        UserConfig.CarMods.MobileCarfly = CF.mobileEnabled
        tog.Text = CF.mobileEnabled and "Mobile Controls ON" or "Mobile Controls OFF"
        tog.BackgroundColor3 = CF.mobileEnabled and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
        if CF.mobileEnabled then
            if not CF.enabled then
                CF.enabled = true
                UserConfig.CarMods.CarFly = true
                startSafeFly()
                startAutoEnter()
            end
        else
            CF.enabled = false
            UserConfig.CarMods.CarFly = false
            stopSafeFly()
            stopAutoEnter()
        end
    end)
    local function createArrow(txt, pos)
        local btn = Instance.new("TextButton", f)
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 28
        btn.Text = txt
        btn.AutoButtonColor = false
        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 6)
        return btn
    end
    local bU = createArrow("↑", UDim2.new(0.5, -20, 0, 55))
    local bD = createArrow("↓", UDim2.new(0.5, -20, 0, 110))
    local bL = createArrow("←", UDim2.new(0.22, -20, 0, 82))
    local bR = createArrow("→", UDim2.new(0.78, -20, 0, 82))
    bU.MouseButton1Down:Connect(function() CF.moveU = true end)
    bU.MouseButton1Up:Connect(function() CF.moveU = false end)
    bU.MouseLeave:Connect(function() CF.moveU = false end)
    bD.MouseButton1Down:Connect(function() CF.moveD = true end)
    bD.MouseButton1Up:Connect(function() CF.moveD = false end)
    bD.MouseLeave:Connect(function() CF.moveD = false end)
    bL.MouseButton1Down:Connect(function() CF.moveL = true end)
    bL.MouseButton1Up:Connect(function() CF.moveL = false end)
    bL.MouseLeave:Connect(function() CF.moveL = false end)
    bR.MouseButton1Down:Connect(function() CF.moveR = true end)
    bR.MouseButton1Up:Connect(function() CF.moveR = false end)
    bR.MouseLeave:Connect(function() CF.moveR = false end)
end

local function destroyMobileControls()
    if CF.mobileGui then
        CF.mobileGui:Destroy()
        CF.mobileGui = nil
    end
    CF.moveU, CF.moveD, CF.moveL, CF.moveR = false, false, false, false
    CF.mobileEnabled = false
end

RunService.Heartbeat:Connect(function()
    if CF.flingEnabled then
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart and h:GetState() == Enum.HumanoidStateType.Seated then
                CF.flingActive = true
                local currentTime = tick()
                if (currentTime - CF.flingStart) >= 0.6 then
                    local fhrp = c:FindFirstChild("HumanoidRootPart")
                    if fhrp then
                        for _, part in pairs(fhrp:GetTouchingParts()) do
                            if part:IsA("BasePart") and part:IsDescendantOf(Workspace) and not part:IsDescendantOf(LocalPlayer) then
                                fhrp.AssemblyLinearVelocity = -(part.Position - fhrp.Position).Unit * 9999999
                                turnCarOff()
                                break
                            end
                        end
                    end
                end
            else
                CF.flingActive = false
            end
        else
            CF.flingActive = false
        end
    else
        CF.flingActive = false
    end
end)

local function startAutoEnter()
    if autoEnterConn then return end
    autoEnterConn = RunService.Heartbeat:Connect(function()
        if CF.enabled then
            local c = LocalPlayer.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            if not h then return end
            if not h.SeatPart or h.SeatPart.Name ~= "DriveSeat" then
                CF.flingActive = false
                local vehicle = Workspace:FindFirstChild("Vehicles") and Workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
                if not vehicle then
                    for _, m in ipairs(Workspace:GetDescendants()) do
                        if m:IsA("Model") and m.Name:lower():find(LocalPlayer.Name:lower()) then
                            vehicle = m
                            break
                        end
                    end
                end
                if vehicle then
                    local seat = vehicle:FindFirstChild("DriveSeat") or vehicle:FindFirstChildWhichIsA("VehicleSeat")
                    if seat then
                        local ahrp = c:FindFirstChild("HumanoidRootPart")
                        if ahrp then ahrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0) end
                        h.Sit = false
                        task.wait(0.0)
                        seat:Sit(h)
                        task.wait(0.0)
                        if not h.SeatPart then seat:Sit(h) end
                    end
                end
            else
                CF.flingActive = true
            end
        end
    end)
end

local function stopAutoEnter()
    if autoEnterConn then
        autoEnterConn:Disconnect()
        autoEnterConn = nil
    end
end

local straightStart, hasShifted = nil, false

RunService.RenderStepped:Connect(function(dt)
    local character = LocalPlayer.Character
    if CF.flingEnabled then CF.enabled = true end
    
    if CF.enabled and character then
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart and hum.SeatPart.Name == "DriveSeat" then
            local seat = hum.SeatPart
            local vehicle = seat.Parent
            if not vehicle.PrimaryPart then vehicle.PrimaryPart = seat end
            local lookVec = Workspace.CurrentCamera.CFrame.LookVector
            
            if CF.flyMode == "Spin" then
                CF.spinRotation = (CF.spinRotation or 0) + dt * CF.spinSpeed
                local spinCF = CFrame.Angles(0, CF.spinRotation, 0)
                vehicle:SetPrimaryPartCFrame(vehicle:GetPivot() * spinCF)
            end
            
            if not CF.lastPos then CF.lastPos = vehicle.PrimaryPart.Position end
            if not CF.lastLook then CF.lastLook = lookVec end
            
            local mY, mZ, mX = 0, 0, 0
            if CF.mobileEnabled then
                if CF.moveU then mZ = 1 end
                if CF.moveD then mZ = -1 end
                if CF.moveL then mX = -1 end
                if CF.moveR then mX = 1 end
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mZ = 1
                elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then mZ = -1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then mY = 1
                elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then mY = -1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mX = -1
                elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then mX = 1 end
            end
            
            local isStraight = false
            if not CF.mobileEnabled then
                isStraight = UserInputService:IsKeyDown(Enum.KeyCode.W) and not UserInputService:IsKeyDown(Enum.KeyCode.S) and not UserInputService:IsKeyDown(Enum.KeyCode.E) and not UserInputService:IsKeyDown(Enum.KeyCode.Q) and not UserInputService:IsKeyDown(Enum.KeyCode.A) and not UserInputService:IsKeyDown(Enum.KeyCode.D)
            else
                isStraight = CF.moveU and not CF.moveD and not CF.moveL and not CF.moveR
            end
            
            local currentTime = tick()
            if isStraight and CF.flyMode ~= "Spin" then
                if not straightStart then straightStart = currentTime end
                if not hasShifted and (currentTime - straightStart) >= 1 then
                    local rightVec = lookVec:Cross(Vector3.new(0, 1, 0)).Unit
                    local shiftPos = vehicle.PrimaryPart.Position + (rightVec * 10)
                    local shiftCF = CFrame.new(shiftPos, shiftPos + lookVec)
                    vehicle:SetPrimaryPartCFrame(shiftCF)
                    CF.lastPos = shiftPos
                    hasShifted = true
                end
            else
                straightStart = nil
                hasShifted = false
            end
            
            local speedMult = CF.speed / 100
            local rightVec = lookVec:Cross(Vector3.new(0, 1, 0)).Unit
            local targetPos = vehicle.PrimaryPart.Position + (lookVec * mZ * speedMult) + (Vector3.new(0, 1, 0) * mY * speedMult) + (rightVec * mX * speedMult)
            local newPos = CF.lastPos:Lerp(targetPos, 0.3)
            local smoothLook = CF.lastLook:Lerp(lookVec, 0.2)
            
            if CF.flyMode == "Spin" then
                vehicle:SetPrimaryPartCFrame(CFrame.new(newPos, newPos + smoothLook) * CFrame.Angles(0, CF.spinRotation, 0))
            elseif mZ ~= 0 or mY ~= 0 or mX ~= 0 then
                vehicle:SetPrimaryPartCFrame(CFrame.new(newPos, newPos + smoothLook))
            else
                vehicle:SetPrimaryPartCFrame(CFrame.new(vehicle.PrimaryPart.Position, vehicle.PrimaryPart.Position + smoothLook))
            end
            
            CF.lastPos = newPos
            CF.lastLook = smoothLook
            
            for _, part in pairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
        else
            CF.lastPos = nil
            CF.lastLook = nil
            straightStart = nil
            hasShifted = false
        end
    else
        CF.lastPos = nil
        CF.lastLook = nil
        straightStart = nil
        hasShifted = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    char = character
    hrp = character:WaitForChild("HumanoidRootPart")
    CF.enabled = UserConfig.CarMods.CarFly
    CF.flingActive = false
    CF.lastPos = nil
    CF.lastLook = nil
    singleExitDone = false
    destroyMobileControls()
    task.wait(1)
    if CF.enabled then
        startSafeFly()
        startAutoEnter()
    end
end)

-- ============================================================
-- VEHICLE SOUND
-- ============================================================
local soundOptions = {
    "Default",
    "Turbo Engine",
    "Power Engine",
    "Street Racer"
}

local soundIds = {
    ["Turbo Engine"] = "rbxassetid://92387486484055",
    ["Power Engine"] = "rbxassetid://91912342333180",
    ["Street Racer"] = "rbxassetid://75247492673971"
}

local originalSounds = {}

local function initializeSounds()
    for _, sound in pairs(Workspace:GetDescendants()) do
        if sound:IsA("Sound") then
            local currentId = sound.SoundId
            if currentId == "rbxassetid://358130654" or currentId == "rbxassetid://358130655" then
                originalSounds[sound] = currentId
            end
        end
    end
end

local function changeSounds(selectedSound)
    local newSoundId = soundIds[selectedSound]
    for sound, originalId in pairs(originalSounds) do
        if sound and sound.Parent then
            if selectedSound == "Default" then
                sound.SoundId = originalId
            else
                sound.SoundId = newSoundId
            end
        end
    end
end

initializeSounds()

-- ============================================================
-- SUSPENSION HEIGHT
-- ============================================================
local VehiclesFolder = Workspace:WaitForChild("Vehicles")
local sliderMoved = false

local function setSuspensionHeight(Value)
    UserConfig.CarMods.SuspensionHeight = Value
    if not sliderMoved then
        sliderMoved = true
        return
    end
    pcall(function()
        local vehicle = VehiclesFolder:FindFirstChild(LocalPlayer.Name)
        if not vehicle then return end
        local driveSeat = vehicle:FindFirstChild("DriveSeat", true)
        if not driveSeat then return end
        for _, v in pairs(driveSeat:GetChildren()) do
            if v:IsA("SpringConstraint") then
                v.LimitsEnabled = true
                v.MinLength = Value
                v.MaxLength = Value
            elseif v:IsA("RopeConstraint") then
                v.Length = Value
            end
        end
    end)
end

-- ============================================================
-- VEHICLE JUMP
-- ============================================================
local jumpPower = UserConfig.CarMods.JumpHeight
local forwardPower = UserConfig.CarMods.ForwardPower

local function GetCurrentVehicle()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return hum.SeatPart end
    local vehFolder = Workspace:FindFirstChild("Vehicles")
    if vehFolder then
        for _, v in pairs(vehFolder:GetChildren()) do
            if v:IsA("Model") and (v.Name:find(LocalPlayer.Name) or v:FindFirstChild("Owner")) then
                return v:FindFirstChildOfClass("VehicleSeat") or v.PrimaryPart
            end
        end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            if (v.Position - char.PrimaryPart.Position).Magnitude < 10 then
                return v
            end
        end
    end
    return nil
end

local function DoVehicleJump()
    local DriveSeat = GetCurrentVehicle()
    if DriveSeat then
        local target = DriveSeat:IsA("VehicleSeat") and DriveSeat or DriveSeat.Parent.PrimaryPart
        target.AssemblyLinearVelocity = target.AssemblyLinearVelocity + Vector3.new(0, jumpPower, 0) + (target.CFrame.LookVector * forwardPower)
    end
end

-- ============================================================
-- COLORS
-- ============================================================
local function setWheelColor(color)
    UserConfig.CarMods.WheelColor = {color.R * 255, color.G * 255, color.B * 255}
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    local car = vehiclesFolder:FindFirstChild(LocalPlayer.Name)
    if not car then return end
    for _, part in pairs(car:GetDescendants()) do
        if part.Name == "FL" or part.Name == "FR" or part.Name == "RL" or part.Name == "RR" then
            local rim = part:FindFirstChild("Rim")
            if rim then
                local main = rim:FindFirstChild("Main")
                if main and main:IsA("BasePart") then
                    main.Color = color
                end
            end
        end
    end
end

local function setBodyColor(color)
    UserConfig.CarMods.BodyColor = {color.R * 255, color.G * 255, color.B * 255}
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    local car = vehiclesFolder:FindFirstChild(LocalPlayer.Name)
    if not car then return end
    for _, part in pairs(car:GetDescendants()) do
        if part.Name == "Body" and part:IsA("BasePart") then
            part.Color = color
        end
    end
end

-- ============================================================
-- DUPLICATE
-- ============================================================
local function duplicateCurrentCar()
    local originalCar = Workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
    if not originalCar then
        OrionLib:MakeNotification({
            Name = "Error",
            Content = "No car found!",
            Image = "rbxassetid://79390235538362",
            Time = 3
        })
        return
    end
    local clone = originalCar:Clone()
    clone.Name = LocalPlayer.Name .. "Clone" .. math.random(1000, 9999)
    local offset = 10
    local newPosition = originalCar:GetPivot().Position + Vector3.new(offset, 0, 0)
    clone:PivotTo(CFrame.new(newPosition))
    clone.Parent = Workspace.Vehicles
    OrionLib:MakeNotification({
        Name = "Success",
        Content = "Car duplicated!",
        Image = "rbxassetid://79390235538362",
        Time = 3
    })
end

local function duplicateNearbyCar()
    local playerCar = Workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
    if not playerCar then return end
    local playerPos = playerCar:GetPivot().Position
    local closestCar = nil
    local closestDistance = math.huge
    for _, vehicle in pairs(Workspace.Vehicles:GetChildren()) do
        if vehicle:IsA("Model") and vehicle ~= playerCar then
            local distance = (vehicle:GetPivot().Position - playerPos).Magnitude
            if distance < closestDistance and distance < 50 then
                closestDistance = distance
                closestCar = vehicle
            end
        end
    end
    if closestCar then
        local clone = closestCar:Clone()
        clone.Name = "Stolen" .. closestCar.Name
        clone:PivotTo(playerCar:GetPivot() * CFrame.new(15, 0, 0))
        clone.Parent = Workspace.Vehicles
        OrionLib:MakeNotification({
            Name = "Success",
            Content = "Nearby car duplicated!",
            Image = "rbxassetid://79390235538362",
            Time = 3
        })
    else
        OrionLib:MakeNotification({
            Name = "Error",
            Content = "No nearby car found!",
            Image = "rbxassetid://79390235538362",
            Time = 3
        })
    end
end

-- ============================================================
-- ACCELERATION & BOOST
-- ============================================================
local instantBoostMultiplier = UserConfig.CarMods.InstantBoostStrength
local accelerationMultiplier = UserConfig.CarMods.AccelerationMultiplier
local accelerationEnabled = false
local accelerationConnection = nil

local function getCurrentVehicleForMods()
    if not char then return nil end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid or not humanoid.SeatPart then return nil end
    local seat = humanoid.SeatPart
    if seat:IsA("VehicleSeat") or seat.Name == "DriveSeat" then
        return seat.Parent
    end
    return nil
end

local function applySmartAcceleration()
    if accelerationConnection then accelerationConnection:Disconnect() end
    accelerationConnection = RunService.Heartbeat:Connect(function()
        if not accelerationEnabled then return end
        local vehicle = getCurrentVehicleForMods()
        if not vehicle or not vehicle.PrimaryPart then return end
        local root = vehicle.PrimaryPart
        local velocity = root.AssemblyLinearVelocity
        local lookVector = root.CFrame.LookVector
        local isW = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
        local isS = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
        if velocity.Magnitude < 0.1 then return end
        local moveDir = velocity.Unit:Dot(lookVector)
        if velocity.Magnitude > 1 then
            if isW and moveDir > -0.2 then
                root.AssemblyLinearVelocity = velocity * (1 + (accelerationMultiplier - 1) * 0.015)
            elseif isS and moveDir < 0.2 then
                root.AssemblyLinearVelocity = velocity * (1 + (accelerationMultiplier - 1) * 0.015)
            end
        end
        if (isS and moveDir > 0.3) or (isW and moveDir < -0.3) then
            root.AssemblyLinearVelocity = velocity * 0.94
        end
    end)
end

local function instantBoost()
    local vehicle = getCurrentVehicleForMods()
    if vehicle and vehicle.PrimaryPart then
        vehicle.PrimaryPart.AssemblyLinearVelocity = vehicle.PrimaryPart.AssemblyLinearVelocity * instantBoostMultiplier
    end
end

-- ============================================================
-- TUNING MODS
-- ============================================================
local function findCarByName(name)
    for _, v in pairs(Workspace.Vehicles:GetChildren()) do
        if v.Name:find(name) then
            return v
        end
    end
    return nil
end

local function setCarAttribute(attribute, value)
    local car = Workspace.Vehicles:FindFirstChild(LocalPlayer.Name) or findCarByName(LocalPlayer.Name)
    if car then
        car:SetAttribute(attribute, value)
    end
end

-- ============================================================
-- UI
-- ============================================================
local Window = OrionLib:MakeWindow({
    Name = "Night System",
    SaveConfig = true,
    ConfigFolder = "Night"
})

-- ============================================================
-- AIMBOT TAB
-- ============================================================
local AimbotTab = Window:MakeTab({Name = "Aimbot", Icon = "rbxassetid://10734977012"})

AimbotTab:AddSection({Name = "Aimbot Settings"})

AimbotTab:AddToggle({
    Name = "Enable Aimbot",
    Default = UserConfig.Aimbot.Enabled,
    Callback = function(v)
        toggleAimbot(v)
    end
})

AimbotTab:AddToggle({
    Name = "Mobile Button",
    Default = UserConfig.Aimbot.MobileButton,
    Callback = function(v)
        UserConfig.Aimbot.MobileButton = v
        if v then
            createMobileGui()
        elseif Aimbot.aimbotGui then
            Aimbot.aimbotGui:Destroy()
            Aimbot.aimbotGui = nil
        end
    end
})

AimbotTab:AddBind({
    Name = "Aimbot Keybind",
    Default = Enum.KeyCode[UserConfig.Aimbot.Keybind] or Enum.KeyCode.L,
    Hold = false,
    Callback = function()
        toggleAimbot(not UserConfig.Aimbot.Enabled)
    end
})

AimbotTab:AddSection({Name = "Visibility & Checks"})

AimbotTab:AddToggle({
    Name = "Wall Check",
    Default = UserConfig.Aimbot.WallCheck,
    Callback = function(v)
        UserConfig.Aimbot.WallCheck = v
    end
})

AimbotTab:AddToggle({
    Name = "Show FOV Circle",
    Default = UserConfig.Aimbot.ShowFOV,
    Callback = function(v)
        UserConfig.Aimbot.ShowFOV = v
        Aimbot.FOVring.Visible = UserConfig.Aimbot.Enabled and v
    end
})

AimbotTab:AddSlider({
    Name = "FOV Radius",
    Min = 10, Max = 500,
    Default = UserConfig.Aimbot.FOVRadius,
    Color = Color3.fromRGB(127, 255, 0),
    Callback = function(v)
        UserConfig.Aimbot.FOVRadius = v
        Aimbot.FOVring.Radius = v
    end
})

AimbotTab:AddSection({Name = "Targeting"})

AimbotTab:AddDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart"},
    Default = UserConfig.Aimbot.TargetPart,
    Callback = function(v)
        UserConfig.Aimbot.TargetPart = v
    end
})

AimbotTab:AddToggle({
    Name = "Prediction",
    Default = UserConfig.Aimbot.Prediction,
    Callback = function(v)
        UserConfig.Aimbot.Prediction = v
    end
})

AimbotTab:AddSlider({
    Name = "Smoothing (1 = stark, 10 = schwach)",
    Min = 1, Max = 10,
    Default = UserConfig.Aimbot.Smoothing,
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(v)
        UserConfig.Aimbot.Smoothing = v
    end
})

-- ============================================================
-- ESP TAB
-- ============================================================
local ESPTab = Window:MakeTab({Name = "ESP", Icon = "rbxassetid://140499484856973"})

ESPTab:AddSection({Name = "Player Visuals"})
ESPTab:AddToggle({
    Name = "Show Names",
    Default = Settings.Visuals.Names,
    Callback = function(v) 
        Settings.Visuals.Names = v
        UserConfig.Visuals.ShowNames = v
    end
})
ESPTab:AddToggle({
    Name = "Show Team",
    Default = Settings.Visuals.Team,
    Callback = function(v) 
        Settings.Visuals.Team = v
        UserConfig.Visuals.ShowTeam = v
    end
})
ESPTab:AddToggle({
    Name = "Show Health",
    Default = Settings.Visuals.Health,
    Callback = function(v) 
        Settings.Visuals.Health = v
        UserConfig.Visuals.ShowHealth = v
    end
})
ESPTab:AddToggle({
    Name = "Show Wanted",
    Default = Settings.Visuals.Wanted,
    Callback = function(v) 
        Settings.Visuals.Wanted = v
        UserConfig.Visuals.ShowWanted = v
    end
})
ESPTab:AddToggle({
    Name = "Skeleton ESP",
    Default = Settings.Skeleton.Enabled,
    Callback = function(v)
        Settings.Skeleton.Enabled = v
        UserConfig.Visuals.SkeletonESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then CreateSkeleton(p) end
            end
        else
            for p, _ in pairs(SkelDraws) do ClearSkeleton(p) end
        end
    end
})

ESPTab:AddSection({Name = "ESP Options"})
ESPTab:AddColorpicker({
    Name = "Skeleton Color",
    Default = Settings.Skeleton.Color,
    Callback = function(v)
        Settings.Skeleton.Color = v
        UserConfig.Visuals.SkeletonColor = {v.R * 255, v.G * 255, v.B * 255}
        for _, lines in pairs(SkelDraws) do
            for _, l in pairs(lines) do l.Color = v end
        end
    end
})

ESPTab:AddDropdown({
    Name = "Text Font",
    Default = "Cartoon",
    Options = {"Gotham Bold", "Arial", "Ubuntu", "Cartoon", "Bangers", "Luckiest Guy", "Arcade", "Highway", "Jura", "SciFi", "Antique"},
    Callback = function(v)
        if FontOptions[v] then
            Settings.Font = FontOptions[v]
            UserConfig.Visuals.TextFont = v
            UpdateAllFonts()
        end
    end
})

ESPTab:AddSlider({
    Name = "Text Size",
    Min = 6,
    Max = 30,
    Default = Settings.TextSize,
    Increment = 1,
    ValueName = "px",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(v)
        Settings.TextSize = v
        UserConfig.Visuals.TextSize = v
        UpdateAllFonts()
    end
})

ESPTab:AddSlider({
    Name = "Max Range",
    Min = 100,
    Max = 5000,
    Default = Settings.MaxDist,
    Increment = 100,
    ValueName = "studs",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(v) 
        Settings.MaxDist = v
        UserConfig.Visuals.MaxRange = v
    end
})

-- ============================================================
-- GRAPHICS TAB
-- ============================================================
local GraphicsTab = Window:MakeTab({Name = "Graphics", Icon = "rbxassetid://126907380304420"})

GraphicsTab:AddSection({Name = "Graphics"})

GraphicsTab:AddToggle({
    Name = "XRay",
    Default = UserConfig.Graphics.XRay,
    Callback = function(val)
        toggleXRay(val)
    end
})

GraphicsTab:AddToggle({
    Name = "Fullbright",
    Default = UserConfig.Graphics.Fullbright,
    Callback = function(val)
        toggleFullbright(val)
    end
})

GraphicsTab:AddToggle({
    Name = "Remove Atmosphere",
    Default = UserConfig.Graphics.RemoveAtmosphere,
    Callback = function(val)
        toggleRemoveAtmosphere(val)
    end
})

GraphicsTab:AddButton({
    Name = "Remove Signs",
    Callback = function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("sign") or obj.Name:lower():find("schild") then
                obj:Destroy()
            end
        end
    end    
})

GraphicsTab:AddButton({
    Name = "Remove Trees",
    Callback = function()
        local winterAssets = Workspace:FindFirstChild("Winter Assets")
        if winterAssets then
            local treeSnow = winterAssets:FindFirstChild("Tree Snow")
            if treeSnow then treeSnow:Destroy() end
        end
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Baum") or obj.Name:find("Bush")) then
                obj:Destroy()
            end
        end
    end    
})

GraphicsTab:AddSection({Name = "Player Options"})

GraphicsTab:AddToggle({
    Name = "Ghost Mode",
    Default = UserConfig.Graphics.GhostMode,
    Callback = function(val)
        ghostEnabled = val
        UserConfig.Graphics.GhostMode = val
        applyGhostEffect(val)
        if val and rainbowGhost then
            startRainbow()
        elseif not val then
            stopRainbow()
        end
    end
})

GraphicsTab:AddToggle({
    Name = "Rainbow Ghost Mode",
    Default = UserConfig.Graphics.RainbowGhost,
    Callback = function(val)
        rainbowGhost = val
        UserConfig.Graphics.RainbowGhost = val
        if val and ghostEnabled then
            startRainbow()
        else
            stopRainbow()
        end
    end
})

GraphicsTab:AddColorpicker({
    Name = "Ghost Color",
    Default = ghostColor,
    Callback = function(val)
        ghostColor = val
        UserConfig.Graphics.GhostColor = {val.R * 255, val.G * 255, val.B * 255}
        if ghostEnabled and not rainbowGhost then
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Color = ghostColor
                    end
                end
            end
        end
    end
})

GraphicsTab:AddToggle({
    Name = "Player Trail",
    Default = UserConfig.Graphics.PlayerTrail,
    Callback = function(val)
        toggleTrail(val)
    end
})

GraphicsTab:AddColorpicker({
    Name = "Trail Color",
    Default = trailColor,
    Callback = function(val)
        trailColor = val
        UserConfig.Graphics.TrailColor = {val.R * 255, val.G * 255, val.B * 255}
        for _, trail in pairs(currentTrails) do
            trail.Color = ColorSequence.new(trailColor)
        end
    end
})

GraphicsTab:AddSection({Name = "Skin Changer"})

local skinDropdown = GraphicsTab:AddDropdown({
    Name = "Select Player",
    Default = "...",
    Options = _G.ST.G(),
    Callback = function(v)
        _G.ST.C(P:FindFirstChild(v))
    end
})

GraphicsTab:AddToggle({
    Name = "Random Loop",
    Default = UserConfig.Graphics.RandomSkinLoop,
    Callback = function(v)
        UserConfig.Graphics.RandomSkinLoop = v
        _G.ST.Lp = v
    end
})

P.PlayerAdded:Connect(function() skinDropdown:Refresh(_G.ST.G(), true) end)
P.PlayerRemoving:Connect(function() skinDropdown:Refresh(_G.ST.G(), true) end)

-- ============================================================
-- VEHICLE TAB
-- ============================================================
local VehicleTab = Window:MakeTab({Name = "Car Mods", Icon = "rbxassetid://114187792807811"})

VehicleTab:AddSection({Name = "Vehicle Mods"})

VehicleTab:AddToggle({
    Name = "Vehicle Godmode",
    Default = UserConfig.CarMods.GodMode,
    Callback = function(Value)
        UserConfig.CarMods.GodMode = Value
        VehicleFeatures.godMode = Value
        if not Value then VehicleFeatures:reset() end
    end
})

VehicleTab:AddToggle({
    Name = "Infinite Fuel",
    Default = UserConfig.CarMods.InfiniteFuel,
    Callback = function(Value)
        UserConfig.CarMods.InfiniteFuel = Value
        VehicleFeatures.infiniteFuel = Value
        if not Value then VehicleFeatures:reset() end
    end
})

VehicleTab:AddToggle({
    Name = "Grip Boost",
    Default = UserConfig.CarMods.GripBoost,
    Callback = function(Value)
        toggleGripBoost(Value)
    end
})

VehicleTab:AddToggle({
    Name = "Anti Crash Damage",
    Default = UserConfig.CarMods.AntiCrashDamage,
    Callback = function(Value)
        toggleAntiCrashDamage(Value)
    end
})

VehicleTab:AddToggle({
    Name = "Enter Locked Cars [Left Mouse click]",
    Default = UserConfig.CarMods.EnterLockedCars,
    Callback = function(val)
        UserConfig.CarMods.EnterLockedCars = val
        enterLockedActive = val
    end
})

VehicleTab:AddToggle({
    Name = "Invisible Numberplate",
    Default = false,
    Callback = function(state)
        toggleInvisibleNumberplate(state)
    end
})

VehicleTab:AddTextbox({
    Name = "Numberplate Text",
    Default = UserConfig.CarMods.NumberplateText,
    PressEnter = false,
    Callback = function(txt)
        setNumberplateText(txt)
    end
})

VehicleTab:AddSection({Name = "CarFly Options"})

VehicleTab:AddToggle({
    Name = "Car Fly",
    Default = UserConfig.CarMods.CarFly,
    Callback = function(Value)
        UserConfig.CarMods.CarFly = Value
        if CF.flingEnabled then CF.enabled = true else CF.enabled = Value end
        if CF.enabled then startSafeFly(); startAutoEnter()
        else stopSafeFly(); stopAutoEnter() end
    end
})

VehicleTab:AddDropdown({
    Name = "Fly Mode",
    Default = UserConfig.CarMods.FlyMode or "Normal",
    Options = {"Normal", "Spin"},
    Callback = function(Value)
        UserConfig.CarMods.FlyMode = Value
        CF.flyMode = Value
        if Value == "Spin" then
            CF.spinRotation = 0
        end
    end
})

VehicleTab:AddToggle({
    Name = "Mobile Carfly",
    Default = UserConfig.CarMods.MobileCarfly,
    Callback = function(Value)
        UserConfig.CarMods.MobileCarfly = Value
        if Value then
            createMobileControls()
            if not CF.enabled then
                CF.enabled = true
                UserConfig.CarMods.CarFly = true
                startSafeFly()
                startAutoEnter()
            end
        else
            destroyMobileControls()
        end
    end
})

VehicleTab:AddToggle({
    Name = "Vehicle Fling",
    Default = UserConfig.CarMods.VehicleFling,
    Callback = function(value)
        UserConfig.CarMods.VehicleFling = value
        CF.flingEnabled = value
        if value then
            CF.enabled = true
            UserConfig.CarMods.CarFly = true
            CF.flingStart = tick()
            startSafeFly()
            startAutoEnter()
        else
            stopAutoEnter()
        end
    end
})

VehicleTab:AddBind({
    Name = "Car Fly Keybind",
    Default = Enum.KeyCode[UserConfig.CarMods.CarFlyKeybind] or Enum.KeyCode.X,
    Hold = false,
    Callback = function()
        if not CF.flingEnabled then
            CF.enabled = not CF.enabled
            UserConfig.CarMods.CarFly = CF.enabled
            if CF.enabled then startSafeFly(); startAutoEnter()
            else stopSafeFly(); stopAutoEnter() end
        end
    end
})

VehicleTab:AddSlider({
    Name = "Car Fly Speed",
    Min = 50, Max = 300,
    Default = UserConfig.CarMods.CarFlySpeed,
    Color = Color3.fromRGB(137, 207, 240),
    Increment = 1, ValueName = "Speed",
    Callback = function(kmhValue)
        UserConfig.CarMods.CarFlySpeed = kmhValue
        CF.speed = kmhValue * 7.77
    end
})

VehicleTab:AddSection({Name = "Extras"})

VehicleTab:AddButton({
    Name = "Jump Out Of Vehicle",
    Callback = function()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.SeatPart then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
})

VehicleTab:AddButton({
    Name = "Enter Own Car",
    Callback = function()
        local car = Workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
        if car and car:FindFirstChild("DriveSeat") and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                if humanoid.Sit then humanoid.Sit = false task.wait(0.1) end
                car.DriveSeat:Sit(humanoid)
            end
        end
    end
})

VehicleTab:AddButton({
    Name = "Bring Own Car",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local car
        local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
        if vehiclesFolder then car = vehiclesFolder:FindFirstChild(LocalPlayer.Name) end
        if not car then
            for _, descendant in ipairs(Workspace:GetDescendants()) do
                if descendant:IsA("Model") and descendant.Name:lower():find(LocalPlayer.Name:lower()) then
                    car = descendant
                    break
                end
            end
        end
        if car and car:IsA("Model") then
            local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
            if seat then
                if not car.PrimaryPart then car.PrimaryPart = seat end
                car:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, 3, -8))
                task.wait(0.2)
                if humanoid and not humanoid.SeatPart then seat:Sit(humanoid) end
            end
        end
    end
})

VehicleTab:AddButton({
    Name = "Steal Nearest E-Bike",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local vehiclesFolder = Workspace:WaitForChild("Vehicles")
        local function isUUID(name)
            local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
            return string.match(name, pattern) ~= nil
        end
        local function findNearestDriveSeat()
            local closestDistance = math.huge
            local closestSeat = nil
            for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
                if isUUID(vehicle.Name) then
                    local driveSeat = vehicle:FindFirstChild("DriveSeat", true)
                    if driveSeat and driveSeat:IsA("Seat") then
                        local distance = (driveSeat.Position - humanoidRootPart.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestSeat = driveSeat
                        end
                    end
                end
            end
            return closestSeat
        end
        local seat = findNearestDriveSeat()
        if seat then seat:Sit(character:WaitForChild("Humanoid")) end
    end
})

VehicleTab:AddSection({Name = "Vehicle Sound"})

VehicleTab:AddDropdown({
    Name = "Vehicle Sound",
    Default = UserConfig.CarMods.VehicleSound,
    Options = soundOptions,
    Callback = function(selectedSound)
        UserConfig.CarMods.VehicleSound = selectedSound
        changeSounds(selectedSound)
    end
})

VehicleTab:AddSection({Name = "Suspension"})

VehicleTab:AddSlider({
    Name = "Suspension Height",
    Min = 0.5,
    Max = 13,
    Default = UserConfig.CarMods.SuspensionHeight,
    Color = Color3.fromRGB(137, 207, 240),
    Increment = 0.1,
    Callback = function(Value)
        setSuspensionHeight(Value)
    end
})

VehicleTab:AddSection({Name = "Vehicle Jump"})

VehicleTab:AddSlider({
    Name = "Jump Height",
    Min = 10,
    Max = 250,
    Default = UserConfig.CarMods.JumpHeight,
    Increment = 5,
    ValueName = "Power",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(Value)
        UserConfig.CarMods.JumpHeight = Value
        jumpPower = Value
    end
})

VehicleTab:AddSlider({
    Name = "Forward Power",
    Min = 0,
    Max = 250,
    Default = UserConfig.CarMods.ForwardPower,
    Increment = 5,
    ValueName = "Boost",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(Value)
        UserConfig.CarMods.ForwardPower = Value
        forwardPower = Value
    end
})

VehicleTab:AddButton({
    Name = "Car Jump",
    Callback = function() DoVehicleJump() end
})

VehicleTab:AddBind({
    Name = "Jump Keybind",
    Default = Enum.KeyCode[UserConfig.CarMods.JumpKeybind] or Enum.KeyCode.F2,
    Hold = false,
    Callback = function() DoVehicleJump() end
})

VehicleTab:AddSection({Name = "Colors"})

VehicleTab:AddColorpicker({
    Name = "Wheel Color",
    Default = Color3.fromRGB(UserConfig.CarMods.WheelColor[1], UserConfig.CarMods.WheelColor[2], UserConfig.CarMods.WheelColor[3]),
    Callback = function(color)
        setWheelColor(color)
    end
})

VehicleTab:AddColorpicker({
    Name = "Body Color",
    Default = Color3.fromRGB(UserConfig.CarMods.BodyColor[1], UserConfig.CarMods.BodyColor[2], UserConfig.CarMods.BodyColor[3]),
    Callback = function(color)
        setBodyColor(color)
    end
})

VehicleTab:AddSection({Name = "Duplicate"})

VehicleTab:AddButton({
    Name = "Duplicate Current Car",
    Callback = duplicateCurrentCar
})

VehicleTab:AddButton({
    Name = "Duplicate Nearby Car",
    Callback = duplicateNearbyCar
})

VehicleTab:AddSection({Name = "Mods"})

VehicleTab:AddButton({
    Name = "Instant Speed Boost",
    Callback = instantBoost
})

VehicleTab:AddBind({
    Name = "Instant Boost Keybind",
    Default = Enum.KeyCode.F3,
    Hold = false,
    Callback = instantBoost
})

VehicleTab:AddToggle({
    Name = "Acceleration Boost",
    Default = false,
    Callback = function(value)
        accelerationEnabled = value
        if value then 
            applySmartAcceleration()
        elseif accelerationConnection then 
            accelerationConnection:Disconnect() 
        end
    end
})

VehicleTab:AddSlider({
    Name = "Instant Boost Strength",
    Min = 1, Max = 10, Increment = 0.5,
    Default = UserConfig.CarMods.InstantBoostStrength,
    ValueName = "x",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(value)
        UserConfig.CarMods.InstantBoostStrength = value
        instantBoostMultiplier = value
    end
})

VehicleTab:AddSlider({
    Name = "Acceleration Multiplier",
    Min = 1, Max = 5, Increment = 0.1,
    Default = UserConfig.CarMods.AccelerationMultiplier,
    ValueName = "x",
    Color = Color3.fromRGB(137, 207, 240),
    Callback = function(value)
        UserConfig.CarMods.AccelerationMultiplier = value
        accelerationMultiplier = value
    end
})

VehicleTab:AddSection({Name = "Tuning Mods"})

VehicleTab:AddSlider({
    Name = "Armor",
    Min = 0,
    Max = 6,
    Default = UserConfig.CarMods.Armor,
    Color = Color3.fromRGB(137, 207, 240),
    Increment = 1,
    ValueName = "Level",
    Callback = function(val)
        UserConfig.CarMods.Armor = val
        setCarAttribute("armorLevel", val)
    end
})

VehicleTab:AddSlider({
    Name = "Brakes",
    Min = 0,
    Max = 6,
    Default = UserConfig.CarMods.Brakes,
    Color = Color3.fromRGB(137, 207, 240),
    Increment = 1,
    ValueName = "Level",
    Callback = function(val)
        UserConfig.CarMods.Brakes = val
        setCarAttribute("brakesLevel", val)
    end
})

VehicleTab:AddSlider({
    Name = "Engine",
    Min = 0,
    Max = 6,
    Default = UserConfig.CarMods.Engine,
    Color = Color3.fromRGB(137, 207, 240),
    Increment = 1,
    ValueName = "Level",
    Callback = function(val)
        UserConfig.CarMods.Engine = val
        setCarAttribute("engineLevel", val)
    end
})

OrionLib:Init()

print("Night System Ultimate geladen!")
