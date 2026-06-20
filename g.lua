local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NightSyste/NightUI/refs/heads/main/Night.lua"))()

local Window = OrionLib:MakeWindow({
    Name         = "Night | discord.gg/DjvzXcqd5m ",
    SaveConfig   = false,
    IntroEnabled = false,
    ConfigFolder = "NightSystemCfgR",
    Icon         = "rbxassetid://140458594132153",
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

if not game:IsLoaded() then game.Loaded:Wait() end
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local RemoteFolder = ReplicatedStorage:WaitForChild("GpP")

local RemoteEvents = {
    rob = RemoteFolder:WaitForChild("0583c22f-b7b6-4a6b-9844-bad9657f2996"),
    sell = RemoteFolder:WaitForChild("d7052636-7370-4c6e-b9da-4693cd4159dc"),
    equip = RemoteFolder:WaitForChild("5fca12bf-61ba-4240-bdf1-ca8de18d361f"),
    buy = RemoteFolder:WaitForChild("7db6464e-0b73-4c83-9aff-024b292865b6"),
    bomb = RemoteFolder:WaitForChild("dbb557a2-5175-41d2-a557-1a22b4880b87"),
    OpenPhone = RemoteFolder:WaitForChild("5fca12bf-61ba-4240-bdf1-ca8de18d361f"),
    ClosePhone = RemoteFolder:WaitForChild("1a193de1-a4cc-49ec-8ea8-3c707c07b92d"),
    hand = RemoteFolder:WaitForChild("1a193de1-a4cc-49ec-8ea8-3c707c07b92d"),
}

local Locations = {
    start   = Vector3.new(-1248.078369140625, 5.846349239349365, 3339.4716796875),
    club = {
        position = Vector3.new(-1739.5330810546875, 11, 3052.31103515625),
        stand    = Vector3.new(-1740.8582763671875, 11.09850025177002, 3019.416015625),
        tresor   = Vector3.new(-1744, 11, 3012),
        safe     = Vector3.new(-1743.4300537109375, 11.124999046325684, 3049.96630859375),
    },
    bank    = Vector3.new(-1280.954833984375, 5.372693061828613, 3166.63720703125),
    jeweler = Vector3.new(-1248.078369140625, 5.846349239349365, 3339.4716796875),
}

local Codes = {
    money = "wEW",
    items = "2Lo",
}

local REJOIN_POSITION = Vector3.new(-1338.36, -23.71, 3778.24)

local Config = {
    range                = 200,
    proximityPromptTime  = 2.5,
    vehicleSpeed         = 170,
    playerSpeed          = 28,
    policeCheckRange     = 30,
    lowHealthThreshold   = 35,
    fastTeleportDistance = 100,
    selectedRadarPosition = "position1",
}

local RobberySelections = {
    mainRobbery = true,
    jewelerEnabled = true,
}

local State = {
    autorobToggle         = true,
    autoSellToggle        = true,
    fastTeleportToggle    = false,
    adminDetectionToggle  = true,
    autoVehicleTPToggle   = false,
    isRobbing             = false,
    collected             = {},
}

local BombDetectionEnabled   = true
local VehicleSpeedMultiplier = 125
local WebhookUrl             = ""
local DetonationItem         = "Bomb"

local RobberyStats = {
    sessionStartTime     = 0,
    bombsPurchased       = 0,
    safesRobbed          = 0,
    alreadyRobbedIgnored = 0,
    clubRobbed           = false,
    bankRobbed           = false,
    jewelerRobbed        = false,
}

local Stats = {
    currentBalance = "N/A",
    crimemoney     = "N/A",
}

cloneref = (type(cloneref) == "function") and cloneref or function(...) return ... end

local InvServices = setmetatable({}, {
    __index = function(_, n)
        return cloneref(game:GetService(n))
    end
})

local InvRunService = InvServices.RunService

local InvCharacter = Player.Character or Player.CharacterAdded:Wait()
local InvHumanoid  = InvCharacter:WaitForChild("Humanoid")

local InvisibleEnabled       = false
local InvisibleToggleEnabled = true
local CurrentTrack
local LastPosition       = InvCharacter.PrimaryPart and InvCharacter.PrimaryPart.Position or Vector3.new()
local OriginalCollisions = {}

local InvRenderConnection
local InvSteppedConnection
local InputBlockConnection

Player.CharacterAdded:Connect(function(c)
    InvCharacter = c
    InvHumanoid  = c:WaitForChild("Humanoid")
    LastPosition = InvCharacter.PrimaryPart and InvCharacter.PrimaryPart.Position or Vector3.new()
end)

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NightSyste/NightUI/refs/heads/main/Night.lua"))()

local Window = OrionLib:MakeWindow({
    Name         = "Night | .gg/DjvzXcqd5m ",
    SaveConfig   = false,
    IntroEnabled = false,
    ConfigFolder = "NightSystemCfgR",
    Icon         = "rbxassetid://140458594132153",
})

local InfoGroup = Window:MakeTabGroup({ Name = "Script" })
local AutorobGroup = Window:MakeTabGroup({ Name = "Autorob" })

local tabs = {
    Info  = InfoGroup:MakeTab({ Name = "Information",  Icon = "rbxassetid://92667392992793" }),
    AutoRob  = AutorobGroup:MakeTab({ Name = "AutoRob",  Icon = "rbxassetid://4814047006" }),
}

local function saveConfig()
    local config = {
        autorobToggle          = State.autorobToggle,
        autoSellToggle         = State.autoSellToggle,
        fastTeleportToggle     = State.fastTeleportToggle,
        adminDetectionToggle   = State.adminDetectionToggle,
        autoVehicleTPToggle    = State.autoVehicleTPToggle,
        mainRobbery            = RobberySelections.mainRobbery,
        jewelerEnabled         = RobberySelections.jewelerEnabled,
        VehicleSpeedMultiplier = VehicleSpeedMultiplier,
        playerSpeed            = Config.playerSpeed,
        lowHealthThreshold     = Config.lowHealthThreshold,
        policeCheckRange       = Config.policeCheckRange,
        WebhookUrl             = WebhookUrl,
        InvisibleToggleEnabled = InvisibleToggleEnabled,
        DetonationItem         = DetonationItem,
        fastTeleportDistance   = Config.fastTeleportDistance,
    }
    local configFileName = "NightSystemCfgR.json"
    if isfile then
        if isfile(configFileName) then delfile(configFileName) end
        writefile(configFileName, HttpService:JSONEncode(config))
    end
end

local function loadConfig()
    local configFileName = "NightSystemCfgR.json"
    if isfile and isfile(configFileName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFileName))
        end)
        if success and data then
            if data.autorobToggle ~= nil then State.autorobToggle = data.autorobToggle end
            if data.autoSellToggle ~= nil then State.autoSellToggle = data.autoSellToggle end
            if data.fastTeleportToggle ~= nil then State.fastTeleportToggle = data.fastTeleportToggle end
            if data.adminDetectionToggle ~= nil then State.adminDetectionToggle = data.adminDetectionToggle end
            if data.autoVehicleTPToggle ~= nil then State.autoVehicleTPToggle = data.autoVehicleTPToggle end
            if data.mainRobbery ~= nil then RobberySelections.mainRobbery = data.mainRobbery end
            if data.jewelerEnabled ~= nil then RobberySelections.jewelerEnabled = data.jewelerEnabled end
            if data.VehicleSpeedMultiplier ~= nil then VehicleSpeedMultiplier = data.VehicleSpeedMultiplier end
            if data.playerSpeed ~= nil then Config.playerSpeed = data.playerSpeed end
            if data.lowHealthThreshold ~= nil then Config.lowHealthThreshold = data.lowHealthThreshold end
            if data.policeCheckRange ~= nil then Config.policeCheckRange = data.policeCheckRange end
            if data.WebhookUrl ~= nil then WebhookUrl = data.WebhookUrl end
            if data.InvisibleToggleEnabled ~= nil then InvisibleToggleEnabled = data.InvisibleToggleEnabled end
            if data.DetonationItem ~= nil then DetonationItem = data.DetonationItem end
            if data.fastTeleportDistance ~= nil then Config.fastTeleportDistance = data.fastTeleportDistance end
        end
    end
end

loadConfig()

local function sendNotification(title, content)
    OrionLib:MakeNotification({
        Name    = title,
        Content = content,
        Image   = "rbxassetid://4483345998",
        Time    = 2,
    })
end

tabs.AutoRob:AddSection({ Name = "AutoRob Script" })
tabs.AutoRob:AddToggle({
    Name     = "Autorob",
    Default  = State.autorobToggle,
    Callback = function(v)
        State.autorobToggle = v
        saveConfig()
    end,
})
tabs.AutoRob:AddDropdown({
    Name    = "Select Robberies",
    Default = RobberySelections.jewelerEnabled and "Bank & Club & Jeweler" or "Bank & Club",
    Options = { "Bank & Club", "Bank & Club & Jeweler" },
    Callback = function(v)
        RobberySelections.mainRobbery = true
        RobberySelections.jewelerEnabled = (v == "Bank & Club & Jeweler")
        saveConfig()
    end,
})
tabs.AutoRob:AddToggle({
    Name     = "Autosell Items",
    Default  = State.autoSellToggle,
    Callback = function(v)
        State.autoSellToggle = v
        saveConfig()
    end,
})

tabs.AutoRob:AddSection({ Name = "Toggle Settings" })
tabs.AutoRob:AddToggle({
    Name     = "Fast Player Teleport",
    Default  = State.fastTeleportToggle,
    Callback = function(v)
        State.fastTeleportToggle = v
        saveConfig()
    end,
})
tabs.AutoRob:AddToggle({
    Name     = "Fast Vehicle Teleport",
    Default  = State.autoVehicleTPToggle,
    Callback = function(v)
        State.autoVehicleTPToggle = v
        saveConfig()
    end,
})
tabs.AutoRob:AddToggle({
    Name     = "Mod Detection",
    Default  = State.adminDetectionToggle,
    Callback = function(v)
        State.adminDetectionToggle = v
        saveConfig()
    end,
})
tabs.AutoRob:AddToggle({
    Name     = "Invisibility",
    Default  = InvisibleToggleEnabled,
    Callback = function(v)
        InvisibleToggleEnabled = v
        saveConfig()
    end,
})

tabs.AutoRob:AddSection({ Name = "Slider Settings" })
tabs.AutoRob:AddSlider({
    Name      = "Vehicle Speed",
    Min       = 75,
    Max       = 175,
    Default   = VehicleSpeedMultiplier,
    Color     = Color3.fromRGB(85, 170, 255),
    Increment = 25,
    ValueName = "speed",
    Callback  = function(v)
        VehicleSpeedMultiplier = v
        saveConfig()
    end,
})
tabs.AutoRob:AddSlider({
    Name      = "Player Speed",
    Min       = 20,
    Max       = 75,
    Default   = Config.playerSpeed,
    Color     = Color3.fromRGB(85, 170, 255),
    Increment = 5,
    ValueName = "speed",
    Callback  = function(v)
        Config.playerSpeed = v
        saveConfig()
    end,
})
tabs.AutoRob:AddSlider({
    Name      = "Low Health Threshold",
    Min       = 10,
    Max       = 100,
    Default   = Config.lowHealthThreshold,
    Color     = Color3.fromRGB(255, 85, 85),
    Increment = 5,
    ValueName = "health",
    Callback  = function(v)
        Config.lowHealthThreshold = v
        saveConfig()
    end,
})
tabs.AutoRob:AddSlider({
    Name      = "Police Detection Range",
    Min       = 10,
    Max       = 100,
    Default   = Config.policeCheckRange,
    Color     = Color3.fromRGB(85, 170, 255),
    Increment = 5,
    ValueName = "studs",
    Callback  = function(v)
        Config.policeCheckRange = v
        saveConfig()
    end,
})

tabs.AutoRob:AddSection({ Name = "Dropdown Settings" })
tabs.AutoRob:AddDropdown({
    Name     = "Detonation Item",
    Default  = DetonationItem,
    Options  = { "Bomb", "Grenade" },
    Callback = function(v)
        DetonationItem = v
        saveConfig()
    end,
})

tabs.AutoRob:AddSection({ Name = "Other Settings" })
tabs.AutoRob:AddTextbox({
    Name          = "Webhook URL",
    Default       = WebhookUrl,
    TextDisappear = true,
    Callback      = function(v)
        WebhookUrl = v
        saveConfig()
    end,
})
tabs.AutoRob:AddButton({
    Name = "Reset Config",
    Callback = function()
        local configFileName = "NightSystemCfgR.json"
        if isfile and isfile(configFileName) then delfile(configFileName) end
        State.autorobToggle = true
        State.autoSellToggle = true
        State.fastTeleportToggle = false
        State.adminDetectionToggle = true
        State.autoVehicleTPToggle = false
        RobberySelections.mainRobbery = true
        VehicleSpeedMultiplier = 125
        Config.playerSpeed = 28
        Config.lowHealthThreshold = 35
        Config.policeCheckRange = 30
        Config.fastTeleportDistance = 240
        WebhookUrl = ""
        InvisibleToggleEnabled = true
        DetonationItem = "Bomb"
        saveConfig()
        sendNotification("Settings Reset", "All settings have been reset to default.")
    end
})

tabs.Info:AddSection({ Name = "Information" })
tabs.Info:AddParagraph("Warning", "Your device might not be powerful enough to handle this script smoothly. If you get ejected from your vehicle or kicked, lower your graphics settings before running again.")
tabs.Info:AddParagraph("Important", "Always keep your vehicle speed set below the maximum speed your car is actually capable of reaching. Exceeding it may cause issues.")

local function saveCollisions()
    for _, p in ipairs(InvCharacter:GetDescendants()) do
        if p:IsA("BasePart") then
            OriginalCollisions[p] = p.CanCollide
        end
    end
end

local function disableCollisions()
    for _, p in ipairs(InvCharacter:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end

local function restoreCollisions()
    for p, state in pairs(OriginalCollisions) do
        if p and p.Parent then
            p.CanCollide = state
        end
    end
    OriginalCollisions = {}
end

local function startEmote()
    if CurrentTrack then CurrentTrack:Stop(0) end
    local animId = "rbxassetid://94292601332790"
    pcall(function()
        local objs = game:GetObjects(animId)
        if objs and #objs > 0 and objs[1]:IsA("Animation") then
            animId = objs[1].AnimationId
        end
    end)
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = InvHumanoid:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0.1, 1, 1)
    CurrentTrack = track
    if CurrentTrack.Length > 0 then CurrentTrack.TimePosition = 0 end
    saveCollisions()
    disableCollisions()
end

local function stopEmote()
    if CurrentTrack then
        CurrentTrack:Stop(0.1)
        CurrentTrack = nil
    end
    restoreCollisions()
end

local function enableInvisible()
    local invisibleEnabled = InvisibleToggleEnabled
    if not invisibleEnabled then return end
    if InvisibleEnabled then return end
    InvisibleEnabled = true
    startEmote()
    InputBlockConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local blocked = {
            Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
            Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
            Enum.KeyCode.Space,
        }
        for _, key in ipairs(blocked) do
            if input.KeyCode == key then return true end
        end
    end, true)
    InvRenderConnection = InvRunService.RenderStepped:Connect(function()
        if not InvisibleEnabled then return end
        if CurrentTrack and CurrentTrack.IsPlaying and InvCharacter.PrimaryPart then
            LastPosition = InvCharacter.PrimaryPart.Position
        end
    end)
    InvSteppedConnection = InvRunService.Stepped:Connect(function()
        if InvisibleEnabled and InvCharacter and InvCharacter.Parent then
            disableCollisions()
        end
    end)
end

local function disableInvisible()
    if not InvisibleEnabled then return end
    InvisibleEnabled = false
    stopEmote()
    if InputBlockConnection then InputBlockConnection:Disconnect(); InputBlockConnection = nil end
    if InvRenderConnection then InvRenderConnection:Disconnect(); InvRenderConnection = nil end
    if InvSteppedConnection then InvSteppedConnection:Disconnect(); InvSteppedConnection = nil end
end

local function checkForBomb()
    if not BombDetectionEnabled then return false end
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local playerPos = Player.Character.HumanoidRootPart.Position
    local foldersToCheck = {
        workspace.Objects.Throwables.Bomb,
        workspace.Objects.Throwables.Grenade,
    }
    for _, folder in ipairs(foldersToCheck) do
        if folder then
            for _, bombModel in ipairs(folder:GetChildren()) do
                local shouldIgnore = false
                local mainPart = bombModel:FindFirstChild("Main")
                if mainPart and mainPart:IsA("BasePart") then
                    local c = mainPart.Color
                    if math.floor(c.R*255)==27 and math.floor(c.G*255)==42 and math.floor(c.B*255)==53 then
                        shouldIgnore = true
                    end
                end
                if not shouldIgnore then
                    local bombPart = bombModel:FindFirstChild("Handle")
                        or bombModel:FindFirstChild("MainPart")
                        or bombModel:FindFirstChildWhichIsA("BasePart")
                    if bombPart then
                        if (bombPart.Position - playerPos).Magnitude <= 5 then return true end
                    else
                        for _, part in ipairs(bombModel:GetDescendants()) do
                            if part:IsA("BasePart") and (part.Position - playerPos).Magnitude <= 5 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function isPlayerStaff(player)
    if player.UserId == game.CreatorId then return true end
    if game.CreatorType == Enum.CreatorType.Group then
        local ok, rank = pcall(function() return player:GetRankInGroup(game.CreatorId) end)
        if ok and rank >= 250 then return true end
    end
    return false
end

local function checkForStaffPlayers()
    local adminToggle = State.adminDetectionToggle
    if not adminToggle then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            local ok, isStaff = pcall(function() return isPlayerStaff(player) end)
            if ok and isStaff then
                sendNotification("Mod Detected", "Mod " .. player.Name .. " detected.")
                Player:Kick("Night System|Mod detected")
                return
            end
        end
    end
end

local function AdminDtc()
    local function startDetection()
        Players.PlayerAdded:Connect(function(player)
            task.wait(2)
            local adminToggle = State.adminDetectionToggle
            if not adminToggle then return end
            local ok, isStaff = pcall(function() return isPlayerStaff(player) end)
            if ok and isStaff then
                sendNotification("Mod Detected", "Mod " .. player.Name .. " joined.")
                Player:Kick("Night System|Mod detected")
            end
        end)
        checkForStaffPlayers()
    end
    task.spawn(startDetection)
end

local function isPoliceNearby()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team == policeTeam and plr.Character then
            local pHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if pHRP and HumanoidRootPart and (pHRP.Position - HumanoidRootPart.Position).Magnitude <= Config.policeCheckRange then
                return true
            end
        end
    end
    return false
end

local function isPlayerHurt()
    local char = Player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health <= Config.lowHealthThreshold
end

local function isPlayerWanted()
    local char = Player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:GetAttribute("IsWanted") then return true end
    if hrp and hrp:GetAttribute("WantedLevel") and hrp:GetAttribute("WantedLevel") > 0 then return true end
    return false
end

local function waitUntilNotWanted()
    if not isPlayerWanted() then return end
    while isPlayerWanted() do
        task.wait(2)
    end
    task.wait(1)
end

local function updateStats()
    local pg = Player:FindFirstChild("PlayerGui")
    if not pg then return end
    pcall(function()
        for _, e in pairs(pg:GetDescendants()) do
            if (e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox")) and e.Text then
                if string.find(e.Text, "€") and not string.find(e.Text:lower(), "stolen") then
                    local amount = string.match(e.Text, "([%d%.]+[kKmM]?)%s*€")
                    if amount then Stats.currentBalance = amount; break end
                end
            end
        end
    end)
end

local function sendEndReport()
    if WebhookUrl == "" then return end
    updateStats()
    local data = {
        content = "",
        embeds = {{
            title = "Autorob",
            color = 0,
            description = "**Information about this lobby:**",
            fields = {
                {
                    name = "Statistics",
                    value = string.format(
                        "> **Bombs Purchased:** %d\n> **Robbed:** %d\n> **Already Robbed:** %d\n> **Current Money:** %s €",
                        RobberyStats.bombsPurchased, RobberyStats.safesRobbed,
                        RobberyStats.alreadyRobbedIgnored, Stats.currentBalance
                    ),
                    inline = true,
                },
                {
                    name = "Player Info",
                    value = string.format("> **Name:** %s\n> **Server ID:** %s", Player.Name, game.JobId),
                    inline = true,
                },
            },
            footer = { text = "NightSystem" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    }
    local encoded = HttpService:JSONEncode(data)
    local requestFunc = request or http_request or (syn and syn.request)
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = WebhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = encoded,
            })
        end)
    end
end

local function clickAtCoordinates(scaleX, scaleY, duration)
    local cam = Workspace.CurrentCamera
    local ax = cam.ViewportSize.X * scaleX
    local ay = cam.ViewportSize.Y * scaleY
    VirtualInputManager:SendMouseButtonEvent(ax, ay, 0, true, game, 0)
    if duration and duration > 0 then task.wait(duration) end
    VirtualInputManager:SendMouseButtonEvent(ax, ay, 0, false, game, 0)
end

local function ensurePlayerInVehicle()
    local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(Player.Name)
    local char = Player.Character or Player.CharacterAdded:Wait()
    if vehicle and char then
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        local driveSeat = vehicle:FindFirstChild("DriveSeat")
        if humanoid and driveSeat and humanoid.SeatPart ~= driveSeat then
            driveSeat:Sit(humanoid)
        end
    end
end

local function tweenTo(destination)
    local car = Workspace.Vehicles[Player.Name]
    if not car then return end
    car:SetAttribute("ParkingBrake", true)
    car:SetAttribute("Locked", true)
    if car:FindFirstChild("DriveSeat") then
        car.PrimaryPart = car.DriveSeat
        car.DriveSeat:Sit(Player.Character.Humanoid)
    end
    ensurePlayerInVehicle()
    local currentPos = car.PrimaryPart.Position
    local distance = (Vector3.new(currentPos.X,0,currentPos.Z) - Vector3.new(destination.X,0,destination.Z)).Magnitude
    
    if not State.autoVehicleTPToggle then
        local lowY = -1
        local tweenDuration = distance / VehicleSpeedMultiplier
        local TweenValue = Instance.new("CFrameValue")
        TweenValue.Value = car:GetPivot()
        local connection
        connection = TweenValue.Changed:Connect(function(newCFrame)
            local fixedCF = CFrame.new(newCFrame.Position.X, lowY, newCFrame.Position.Z)
            car:PivotTo(fixedCF)
            if car.DriveSeat then
                car.DriveSeat.AssemblyLinearVelocity = Vector3.new(0,0,0)
                car.DriveSeat.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end
        end)
        local tween = TweenService:Create(TweenValue, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Value = CFrame.new(destination.X, lowY, destination.Z) })
        tween:Play()
        tween.Completed:Wait()
        connection:Disconnect()
        TweenValue:Destroy()
        car:PivotTo(CFrame.new(destination))
        car:SetAttribute("ParkingBrake", true)
        car:SetAttribute("Locked", true)
    else
        local lowY = -1
        local tweenDuration = distance / VehicleSpeedMultiplier
        local TweenValue = Instance.new("CFrameValue")
        TweenValue.Value = car:GetPivot()
        local teleportExecuted = false
        local connection
        connection = TweenValue.Changed:Connect(function(newCFrame)
            if teleportExecuted then return end
            local fixedCF = CFrame.new(newCFrame.Position.X, lowY, newCFrame.Position.Z)
            car:PivotTo(fixedCF)
            if car.DriveSeat then
                car.DriveSeat.AssemblyLinearVelocity = Vector3.new(0,0,0)
                car.DriveSeat.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end
            local d = (Vector3.new(fixedCF.Position.X,0,fixedCF.Position.Z) - Vector3.new(destination.X,0,destination.Z)).Magnitude
            if d < Config.fastTeleportDistance then
                teleportExecuted = true
                connection:Disconnect()
                car:PivotTo(CFrame.new(destination))
                car:SetAttribute("ParkingBrake", true)
                car:SetAttribute("Locked", true)
                TweenValue:Destroy()
            end
        end)
        local tween = TweenService:Create(TweenValue, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Value = CFrame.new(destination.X, lowY, destination.Z) })
        tween:Play()
        tween.Completed:Wait()
        if not teleportExecuted then
            if connection then connection:Disconnect() end
            TweenValue:Destroy()
            car:PivotTo(CFrame.new(destination))
            car:SetAttribute("ParkingBrake", true)
            car:SetAttribute("Locked", true)
        end
    end
end

local function teleportPlayer(destination)
    local char = Player.Character
    if not char or not char.PrimaryPart then return end
    if State.fastTeleportToggle then
        char:SetPrimaryPartCFrame(CFrame.new(destination))
    else
        local dist = (char.PrimaryPart.Position - destination).Magnitude
        local tweenDuration = math.max(0.5, dist / Config.playerSpeed)
        local tween = TweenService:Create(char.PrimaryPart, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(destination) })
        tween:Play()
        tween.Completed:Wait()
    end
end

local function teleportToBankPosition(position)
    teleportPlayer(position)
end

local function JumpOut()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function SpawnBomb()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    task.wait(0.5)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function hasDetonationItem()
    local function check(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name == DetonationItem then return true end
        end
        return false
    end
    return check(Player.Backpack) or check(Player.Character)
end

local function MoveToDealer()
    local vehicle = workspace.Vehicles:FindFirstChild(Player.Name)
    if not vehicle then sendNotification("Error", "No vehicle found."); return end
    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then
        sendNotification("Error", "Dealers not found.")
        OpenCrimeApp()
        task.wait(0.75)
        sendEndReport()
        tweenTo(REJOIN_POSITION)
        ensurePlayerInVehicle()
        tweenTo(REJOIN_POSITION)
        task.wait(1)
        Player:Kick("NightSystem Autorob - ServerHop")
        return
    end
    local closest, shortest = nil, math.huge
    for _, dealer in pairs(dealers:GetChildren()) do
        if dealer:FindFirstChild("Head") then
            local dist = (Character.HumanoidRootPart.Position - dealer.Head.Position).Magnitude
            if dist < shortest then shortest = dist; closest = dealer.Head end
        end
    end
    if not closest then
        sendNotification("Error", "Dealers not found.")
        tweenTo(Vector3.new(-1241.8756103515625, -23.776233673095703, 3719.95849609375))
        tweenTo(Vector3.new(-1241.78857421875, -358.98175048828125, 3718.096435546875))
        task.wait(0.5)
        Player:Kick("NightSystem Autorob - ServerHop")
        return
    end
    tweenTo(closest.Position + Vector3.new(0, 5, 0))
end

local HealthTripwire = false

local function HealthCheck()
    local function watchChar(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.HealthChanged:Connect(function(health)
            if HealthTripwire or not State.autorobToggle then return end
            if health > 0 and health <= Config.lowHealthThreshold then
                HealthTripwire = true
                State.isRobbing = false
                disableInvisible()
                sendNotification("Low Health", "Server hopping...")
              FirstRejoin()
            end
        end)
        humanoid.Died:Connect(function()
            if HealthTripwire or not State.autorobToggle then return end
            HealthTripwire = true
            State.isRobbing = false
            disableInvisible()
            sendNotification("Low Health", "Server hopping...")
            task.wait(0.5)
            sendEndReport()
            task.wait(0.3)
            Player:Kick("NightSystem Autorob - ServerHop")
        end)
    end
    watchChar(Player.Character or Player.CharacterAdded:Wait())
    Player.CharacterAdded:Connect(function(char)
        HealthTripwire = false
        watchChar(char)
    end)
end

local function lootVisibleMeshParts(folder)
    if not folder then return end
    if isPlayerHurt() then
        sendNotification("Low Health", "Looting aborted")
        State.isRobbing = false
        return
    end
    local currentChar = Player.Character
    local currentHRP = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
    if not currentChar or not currentHRP then return end
    local meshParts = {}
    for _, mp in ipairs(folder:GetDescendants()) do
        if mp:IsA("MeshPart") and mp.Transparency == 0 and not State.collected[mp] then
            table.insert(meshParts, mp)
        end
    end
    table.sort(meshParts, function(a, b)
        return (a.Position - currentHRP.Position).Magnitude < (b.Position - currentHRP.Position).Magnitude
    end)
    for _, mp in ipairs(meshParts) do
        if not currentChar or not currentHRP then break end
        if isPoliceNearby() and State.isRobbing then
            sendNotification("Police Nearby", "Looting aborted")
            State.isRobbing = false
            return
        end
        if isPlayerHurt() then State.isRobbing = false; return end
        if mp.Transparency == 0 and (mp.Position - currentHRP.Position).Magnitude <= Config.range then
            State.collected[mp] = true
            task.spawn(function()
                local code = mp.Parent and mp.Parent.Name == "Money" and Codes.money or Codes.items
                RemoteEvents.rob:FireServer(mp, code, true)
                task.wait(Config.proximityPromptTime)
                RemoteEvents.rob:FireServer(mp, code, false)
                if mp and mp.Parent then State.collected[mp] = nil end
            end)
            task.wait(0.05)
        end
    end
end

local function handlePlayerHurt()
    if isPlayerHurt() then
        sendNotification("Low Health", "Moving to safe position...")
        disableInvisible()
        ensurePlayerInVehicle()
        task.wait(0.5)
        if workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(Player.Name) then
            tweenTo(REJOIN_POSITION)
        else
            teleportPlayer(REJOIN_POSITION)
        end
        ensurePlayerInVehicle()
        waitUntilNotWanted()
        sendEndReport()
        task.wait(0.5)
        Rejoin()
        task.wait(5)
        return true
    end
    return false
end

local function checkSafeRobStatus()
    task.wait(1)
    local robberiesFolder = Workspace:FindFirstChild("Robberies")
    if not robberiesFolder then return false end
    local jewelerSafeFolder = robberiesFolder:FindFirstChild("Jeweler Safe Robbery")
    if not jewelerSafeFolder then return false end
    local jewelerFolder = jewelerSafeFolder:FindFirstChild("Jeweler")
    if not jewelerFolder then return false end
    local doorFolder = jewelerFolder:FindFirstChild("Door")
    if not doorFolder then return false end
    local targetPart
    for _, v in ipairs(doorFolder:GetDescendants()) do
        if v:IsA("BasePart") then targetPart = v; break end
    end
    if not targetPart then return false end
    local _, y, _ = targetPart.CFrame:ToEulerAnglesYXZ()
    y = math.deg(y) % 360
    return math.abs(y - 90) < 10 or math.abs(y - 270) < 10
end

local function Rejoin()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/7711635737/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if ok and data and data.data then
        for _, server in ipairs(data.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(7711635737, server.id, Player)
                end)
                task.wait(3)
                Player:Kick("NightSystem Autorob - ServerHop")
                return
            end
        end
    end
    
    pcall(function()
        TeleportService:Teleport(7711635737, Player)
    end)
    
    task.wait(3)
    Player:Kick("NightSystem Autorob - ServerHop")
end

local function OpenCrimeApp()
    if not State.autorobToggle then return false end
    local pg = Player:WaitForChild("PlayerGui")
    RemoteEvents.OpenPhone:FireServer("Phone")
    local gui
    local attempts = 0
    repeat
        attempts = attempts + 1
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.DisplayOrder == 29 and g.IgnoreGuiInset == true and g.ResetOnSpawn == false then
                gui = g
                break
            end
        end
        if not gui then task.wait(0.5) end
    until gui or attempts >= 30
    if not gui then
        RemoteEvents.OpenPhone:FireServer("Phone")
        task.wait(1)
        attempts = 0
        repeat
            attempts = attempts + 1
            for _, g in ipairs(pg:GetChildren()) do
                if g:IsA("ScreenGui") and g.DisplayOrder == 29 and g.IgnoreGuiInset == true and g.ResetOnSpawn == false then
                    gui = g
                    break
                end
            end
            if not gui then task.wait(0.5) end
        until gui or attempts >= 30
    end
    if not gui then RemoteEvents.ClosePhone:FireServer(); return false end
    local frame
    attempts = 0
    repeat
        attempts = attempts + 1
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("Frame") then
                local pos = obj.Position
                if math.abs(pos.X.Scale - 0.005) < 0.005 and math.abs(pos.Y.Scale - 0.995) < 0.005 and obj.AnchorPoint.Y == 1 then
                    frame = obj
                    break
                end
            end
        end
        if not frame then task.wait(0.5) end
    until frame or attempts >= 20
    if not frame then RemoteEvents.ClosePhone:FireServer(); return false end
    task.wait(0.3)
    local btn
    for _, obj in ipairs(frame:GetDescendants()) do
        if obj.Name == "Criminal" then btn = obj; break end
    end
    if not btn then
        for _, obj in ipairs(frame:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("TextLabel")) and obj.Text == "Criminal" then btn = obj; break end
        end
    end
    if not btn then RemoteEvents.ClosePhone:FireServer(); return false end
    local p = btn.AbsolutePosition
    local s = btn.AbsoluteSize
    VirtualInputManager:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, true, game, 1)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, false, game, 1)
    task.wait(0.5)
    RemoteEvents.ClosePhone:FireServer()
    return true
end


local function checkBankHasLoot()
    local goldFolder = workspace.Robberies.BankRobbery.Gold
    local moneyFolder = workspace.Robberies.BankRobbery.Money
    
    local hasGold = false
    local hasMoney = false
    
    for _, item in ipairs(goldFolder:GetChildren()) do
        if item:IsA("MeshPart") and item.Transparency == 0 then
            hasGold = true
            break
        end
    end
    
    for _, item in ipairs(moneyFolder:GetChildren()) do
        if item:IsA("MeshPart") and item.Transparency == 0 then
            hasMoney = true
            break
        end
    end
    
    return hasGold or hasMoney
end

local function hasLootInRange(folder, character, range)
    if not folder or not character or not character.PrimaryPart then return false end
    local rootPos = character.PrimaryPart.Position
    for _, mp in ipairs(folder:GetDescendants()) do
        if mp:IsA("MeshPart") and mp.Transparency == 0 then
            if (mp.Position - rootPos).Magnitude <= range then
                return true
            end
        end
    end
    return false
end

local function runMainRobberySequence()    
    if handlePlayerHurt() then return false end
    ensurePlayerInVehicle()
    task.wait(0.2)
    clickAtCoordinates(0.5, 0.9)
    task.wait(0.2)
    tweenTo(Locations.start)

    if handlePlayerHurt() then return false end

    local musikPart = Workspace.Robberies["Club Robbery"].Club.Door.Accessory.Black
    local bankLight = Workspace.Robberies.BankRobbery.LightGreen.Light
    local bankLight2 = Workspace.Robberies.BankRobbery.LightRed.Light

    if musikPart.Rotation == Vector3.new(180, 0, 180) then
        if handlePlayerHurt() then return false end
        clickAtCoordinates(0.5, 0.9)
        sendNotification("Club Robbery", "Safe is open, starting...")

        if not hasDetonationItem() then
            ensurePlayerInVehicle()
            MoveToDealer()
            task.wait(0.2)
            RemoteEvents.buy:FireServer(DetonationItem, "Dealer")
            task.wait(0.2)
            RobberyStats.bombsPurchased = RobberyStats.bombsPurchased + 1
        end

        if handlePlayerHurt() then return false end
        ensurePlayerInVehicle()
        tweenTo(Locations.club.position)
        JumpOut()
        task.wait(0.2)
        RemoteEvents.equip:FireServer(DetonationItem)
        task.wait(0.2)
        teleportPlayer(Locations.club.stand)
        task.wait(0.3)
        SpawnBomb()
        task.wait(0.25)
        RemoteEvents.bomb:FireServer()
        State.isRobbing = true

        enableInvisible()

        teleportPlayer(Locations.club.safe)
        task.wait(2.9)
        teleportPlayer(Locations.club.tresor)

        local safeFolder = Workspace.Robberies["Club Robbery"].Club
        local itemsFolder = safeFolder:FindFirstChild("Items")
        local moneyFolder = safeFolder:FindFirstChild("Money")

        local collectStartTime = tick()
        while tick() - collectStartTime < 25 do
            if handlePlayerHurt() then State.isRobbing = false; break end
            if isPoliceNearby() then sendNotification("Police Detected", "Aborting club robbery"); State.isRobbing = false; break end
            
            local hasItems = hasLootInRange(itemsFolder, Character, 15)
            local hasMoney = hasLootInRange(moneyFolder, Character, 15)
            
            if not hasItems and not hasMoney then
                break
            end
            
            lootVisibleMeshParts(itemsFolder)
            lootVisibleMeshParts(moneyFolder)
            task.wait(0.5)
        end

        disableInvisible()

        State.isRobbing = false
        RobberyStats.clubRobbed = true
        RobberyStats.safesRobbed = RobberyStats.safesRobbed + 1

        if State.autoSellToggle then
            if handlePlayerHurt() then return false end
            ensurePlayerInVehicle()
            MoveToDealer()
            task.wait(0.2)
            for _, item in ipairs({"MP5","Glock 17","Machete","Gold"}) do
                RemoteEvents.sell:FireServer(item, "Dealer")
            end
            task.wait(0.2)
            ensurePlayerInVehicle()
            tweenTo(Locations.start)
        end

        if handlePlayerHurt() then return false end
        ensurePlayerInVehicle()

    else
        sendNotification("Club Safe", "Closed, going to bank")
        RobberyStats.alreadyRobbedIgnored = RobberyStats.alreadyRobbedIgnored + 1
    end

    if handlePlayerHurt() then return false end

    if bankLight2.Enabled == false and bankLight.Enabled == true then
        if handlePlayerHurt() then return false end
        clickAtCoordinates(0.5, 0.9)
        sendNotification("Bank Robbery", "Bank is open, starting...")

        if not hasDetonationItem() then
            ensurePlayerInVehicle()
            MoveToDealer()
            task.wait(0.2)
            RemoteEvents.buy:FireServer(DetonationItem, "Dealer")
            task.wait(0.2)
            RobberyStats.bombsPurchased = RobberyStats.bombsPurchased + 1
        end

        tweenTo(Locations.bank)
        task.wait(0.4)
        JumpOut()
        task.wait(0.45)

        if handlePlayerHurt() then return false end
        teleportToBankPosition(Vector3.new(-1242.367919921875, 7.749999046325684, 3144.705322265625))
        task.wait(0.55)

        local bombEquipped, equipAttempts = false, 0
        while not bombEquipped and equipAttempts < 5 do
            RemoteEvents.equip:FireServer(DetonationItem)
            task.wait(0.5)
            if Player.Character:FindFirstChild(DetonationItem) then
                bombEquipped = true
            else
                equipAttempts = equipAttempts + 1
                task.wait(0.3)
            end
        end

        if not bombEquipped then
            sendNotification("Error", "Failed to equip " .. DetonationItem)
        else
            SpawnBomb()
            task.wait(0.25)
            RemoteEvents.bomb:FireServer()
            teleportToBankPosition(Vector3.new(-1246.291015625, 7.749999046325684, 3120.8505859375))
            State.isRobbing = true

            enableInvisible()

            task.wait(3.15)

            local hasLoot = checkBankHasLoot()
            
            if hasLoot then
                local bankRobberyFolder = Workspace.Robberies.BankRobbery
                local bankCollectPositions = {
                    Vector3.new(-1249.897216796875, 7.723498821258545, 3121.068603515625),
                    Vector3.new(-1231.8480224609375, 7.723498821258545, 3123.696044921875),
                    Vector3.new(-1246.9058837890625, 7.723498821258545, 3102.236083984375),
                    Vector3.new(-1234.6124267578125, 7.723498821258545, 3102.63134765625),
                }

                for _, position in ipairs(bankCollectPositions) do
                    if handlePlayerHurt() then State.isRobbing = false; break end
                    if isPoliceNearby() then sendNotification("Police Detected", "Aborting bank robbery"); State.isRobbing = false; break end
                    
                    teleportPlayer(position)
                    
                    local collectStartTime = tick()
                    while tick() - collectStartTime < 6 do
                        if handlePlayerHurt() then State.isRobbing = false; break end
                        if isPoliceNearby() then State.isRobbing = false; break end
                        
                        local lootRemaining = hasLootInRange(bankRobberyFolder, Character, 9)
                        
                        if not lootRemaining then
                            break
                        end
                        
                        lootVisibleMeshParts(bankRobberyFolder)
                        task.wait(0.5)
                    end
                    if not State.isRobbing then break end
                end
            end

            disableInvisible()

            State.isRobbing = false
            RobberyStats.bankRobbed = true
            RobberyStats.safesRobbed = RobberyStats.safesRobbed + 1

            if handlePlayerHurt() then return false end
            ensurePlayerInVehicle()

            if State.autoSellToggle then
                task.wait(0.2)
                MoveToDealer()
                task.wait(0.2)
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                task.wait(0.2)
                ensurePlayerInVehicle()
            end
        end
    else
        sendNotification("Bank", "Not open, going to jeweler")
        RobberyStats.alreadyRobbedIgnored = RobberyStats.alreadyRobbedIgnored + 1
    end

    if handlePlayerHurt() then return false end

    if RobberySelections.jewelerEnabled then
        tweenTo(Locations.jeweler)
        task.wait(0.5)

        if not isPoliceNearby() and checkSafeRobStatus() then
            if handlePlayerHurt() then return false end
            sendNotification("Jeweler Robbery", "Jeweler is open, starting...")
            ensurePlayerInVehicle()
            MoveToDealer()
            task.wait(0.2)
            RemoteEvents.buy:FireServer(DetonationItem, "Dealer")
            task.wait(0.2)
            RobberyStats.bombsPurchased = RobberyStats.bombsPurchased + 1
            tweenTo(Vector3.new(-423.84393310546875, 22.29579734802246, 3577.518798828125))
            task.wait(0.4)
            JumpOut()
            task.wait(0.2)
            teleportPlayer(Vector3.new(-435.2751770019531, 21.223411560058594, 3550.939453125))
            RemoteEvents.equip:FireServer(DetonationItem)
            task.wait(0.8)
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(90), 0) end
            SpawnBomb()
            task.wait(0.25)
            RemoteEvents.bomb:FireServer()
            State.isRobbing = true

            enableInvisible()

            task.wait(0.5)
            teleportPlayer(Vector3.new(-425.7878112792969, 21.223413467407227, 3568.551513671875))
            task.wait(3)
            teleportPlayer(Vector3.new(-438.992919921875, 21.223411560058594, 3553.45166015625))
            task.wait(0.5)
            hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(90), 0) end
            task.wait(0.5)

            local jewelerSafeFolder = Workspace.Robberies:FindFirstChild("Jeweler Safe Robbery")
            if jewelerSafeFolder then
                local jewelerFolder = jewelerSafeFolder:FindFirstChild("Jeweler")
                if jewelerFolder then
                    local itemsFolder = jewelerFolder:FindFirstChild("Items")
                    local moneyFolder = jewelerFolder:FindFirstChild("Money")

                    local t = tick()
                    while tick() - t < 25 do
                        if handlePlayerHurt() then State.isRobbing = false; break end
                        if isPoliceNearby() then sendNotification("Police Detected", "Aborting jeweler robbery"); State.isRobbing = false; break end
                        
                        local hasItems = hasLootInRange(itemsFolder, Character, 15)
                        local hasMoney = hasLootInRange(moneyFolder, Character, 15)
                        
                        if not hasItems and not hasMoney then
                            break
                        end
                        
                        lootVisibleMeshParts(itemsFolder)
                        lootVisibleMeshParts(moneyFolder)
                        task.wait(0.5)
                    end
                    State.isRobbing = false
                end
            end

            disableInvisible()

            RobberyStats.jewelerRobbed = true
            RobberyStats.safesRobbed = RobberyStats.safesRobbed + 1

            if State.autoSellToggle then
                if handlePlayerHurt() then return false end
                ensurePlayerInVehicle()
                task.wait(0.2)
                MoveToDealer()
                task.wait(0.2)
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                RemoteEvents.sell:FireServer("Gold", "Dealer")
                task.wait(0.2)
                ensurePlayerInVehicle()
            end

            return true
        else
            sendNotification("Jeweler", "Not open, rejoining...")
            RobberyStats.alreadyRobbedIgnored = RobberyStats.alreadyRobbedIgnored + 1
            return false
        end
    end

    return true
end

local function FirstRejoin()
    tweenTo(REJOIN_POSITION)
    waitUntilNotWanted()
    sendEndReport()
    task.wait(0.5)
    Player:Kick("NightSystem Autorob - ServerHop")
    Rejoin()
    task.wait(5)
end

game:GetService("CoreGui").DescendantAdded:Connect(function(d)
    if d.Name == "ErrorPrompt" or d.Name == "ErrorTitle" then
        task.wait(0.5)
        Rejoin()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == Player then Rejoin() end
end)

RobberyStats.sessionStartTime = os.time()

RemoteEvents.sell:FireServer("Bomb", "Dealer")
clickAtCoordinates(0.5, 0.9)
task.wait(2)
if State.autorobToggle then
    OpenCrimeApp()
end
AdminDtc()
HealthCheck()

while task.wait(0.1) do
    if not State.autorobToggle then
        continue
    end
    
    if not RobberySelections.mainRobbery then
        sendNotification("Warning", "No robberies selected! Please select at least one in Rob Selections.")
        task.wait(5)
        continue
    end

    if checkForBomb() then
        sendNotification("Bomb Detected", "Waiting for explosion...")
        task.wait(3)
    end

    if handlePlayerHurt() then break end

    Character = Player.Character or Player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local camera = Workspace.CurrentCamera

    camera.CameraType = Enum.CameraType.Scriptable
    local cameraLockConnection = RunService.RenderStepped:Connect(function()
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local rp = Character.HumanoidRootPart
        camera.CFrame = CFrame.new(rp.Position - rp.CFrame.LookVector*5 + Vector3.new(0,4,0), rp.Position)
        camera.FieldOfView = 80
    end)

    if RobberySelections.mainRobbery then
        runMainRobberySequence()
    end
    
    FirstRejoin()

    if cameraLockConnection then
        cameraLockConnection:Disconnect()
        camera.CameraType = Enum.CameraType.Custom
    end

    task.wait(1)
end
