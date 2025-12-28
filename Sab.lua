--[[
    ARCADE UI - MODULAR STRUCTURE (NO GLOBALS)
    Dibungkus dalam Namespace 'S' dan Table Modules.
    Logic asal dikekalkan sepenuhnya.
]]

-- ==================== 1. NAMESPACE UTAMA (S) ====================
local S = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

-- ==================== 2. LOAD LIBRARY ====================
local ArcadeUILib = (function()
    local s, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/Nightmare-Ui/refs/heads/main/ArcadeUiLib.lua"))()
    end)
    return s and lib or nil
end)()

if not ArcadeUILib then
    warn("❌ Failed to load ArcadeUI library!")
    return
end

-- ==================== 3. LOAD MODULES (Dalam S.Modules) ====================
S.Modules = {}
pcall(function()
    S.Modules.Animals = require(S.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
    S.Modules.Traits = require(S.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Traits"))
    S.Modules.Mutations = require(S.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Mutations"))
end)

pcall(function()
    local Packages = S.ReplicatedStorage:WaitForChild("Packages")
    local Datas = S.ReplicatedStorage:WaitForChild("Datas")
    local Shared = S.ReplicatedStorage:WaitForChild("Shared")
    local Utils = S.ReplicatedStorage:WaitForChild("Utils")
    
    S.Modules.Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    S.Modules.AnimalsData = require(Datas:WaitForChild("Animals"))
    S.Modules.RaritiesData = require(Datas:WaitForChild("Rarities"))
    S.Modules.AnimalsShared = require(Shared:WaitForChild("Animals"))
    S.Modules.NumberUtils = require(Utils:WaitForChild("NumberUtils"))
end)

-- ==================== 4. MODULE DEFINITIONS (Table Structure) ====================

--- [[ MODULE: ESP PLAYERS ]] ---
local ESP_Players = {
    Enabled = false,
    Objects = {},
    Connection = nil
}

-- Local Functions untuk ESP Players
local function getEquippedItem(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then return child.Name end
        end
    end
    return "None"
end

local function createESP(targetPlayer)
    if targetPlayer == S.LocalPlayer then return end
    local character = targetPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPInfo"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 18)
    itemLabel.Position = UDim2.new(0, 0, 0, 22)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item: None"
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    itemLabel.TextStrokeTransparency = 0.5
    itemLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextSize = 12
    itemLabel.Parent = billboard
    
    ESP_Players.Objects[targetPlayer] = {
        highlight = highlight,
        billboard = billboard,
        itemLabel = itemLabel,
        character = character
    }
end

local function removeESP(targetPlayer)
    if ESP_Players.Objects[targetPlayer] then
        if ESP_Players.Objects[targetPlayer].highlight then ESP_Players.Objects[targetPlayer].highlight:Destroy() end
        if ESP_Players.Objects[targetPlayer].billboard then ESP_Players.Objects[targetPlayer].billboard:Destroy() end
        ESP_Players.Objects[targetPlayer] = nil
    end
end

local function updateESP()
    if not ESP_Players.Enabled then return end
    for targetPlayer, espData in pairs(ESP_Players.Objects) do
        if targetPlayer and targetPlayer.Parent and espData.character and espData.character.Parent then
            local character = espData.character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local equippedItem = getEquippedItem(character)
                espData.itemLabel.Text = "Item: " .. equippedItem
                if equippedItem ~= "None" then
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                else
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                end
            else
                removeESP(targetPlayer)
            end
        else
            removeESP(targetPlayer)
        end
    end
end

-- Public API
function ESP_Players.Enable()
    if ESP_Players.Enabled then return end
    ESP_Players.Enabled = true
    for _, targetPlayer in pairs(S.Players:GetPlayers()) do
        if targetPlayer ~= S.LocalPlayer and targetPlayer.Character then createESP(targetPlayer) end
    end
    ESP_Players.Connection = S.RunService.RenderStepped:Connect(updateESP)
    print("✅ ESP Players Diaktifkan")
end

function ESP_Players.Disable()
    if not ESP_Players.Enabled then return end
    ESP_Players.Enabled = false
    for targetPlayer, _ in pairs(ESP_Players.Objects) do removeESP(targetPlayer) end
    if ESP_Players.Connection then ESP_Players.Connection:Disconnect(); ESP_Players.Connection = nil end
    print("❌ ESP Players Dimatikan")
end

function ESP_Players.Toggle(state)
    if state then ESP_Players.Enable() else ESP_Players.Disable() end
end

--- [[ MODULE: ESP BEST ]] ---
local ESP_Best = {
    Enabled = false,
    Data = nil,
    Objects = {}, -- highlight, box, billboard, beam, etc
    Thread = nil,
    LastNotifiedPet = nil
}

-- Helper Functions
local function getTraitMultiplier(model)
    if not S.Modules.Traits then return 0 end
    local traitJson = model:GetAttribute("Traits")
    if not traitJson or traitJson == "" then return 0 end
    local traits = {}
    local ok, decoded = pcall(function() return S.HttpService:JSONDecode(traitJson) end)
    if ok and typeof(decoded) == "table" then traits = decoded else
        for t in string.gmatch(traitJson, "[^,]+") do table.insert(traits, t) end
    end
    local mult = 0
    for _, entry in pairs(traits) do
        local name = typeof(entry) == "table" and entry.Name or tostring(entry)
        name = name:gsub("^_Trait%.", "")
        local trait = S.Modules.Traits[name]
        if trait and trait.MultiplierModifier then mult += tonumber(trait.MultiplierModifier) or 0 end
    end
    return mult
end

local function getFinalGeneration(model)
    if not S.Modules.Animals then return 0 end
    local animalData = S.Modules.Animals[model.Name]
    if not animalData then return 0 end
    local baseGen = tonumber(animalData.Generation) or tonumber(animalData.Price or 0)
    local traitMult = getTraitMultiplier(model)
    local mutationMult = 0
    if S.Modules.Mutations then
        local mutation = model:GetAttribute("Mutation")
        if mutation and S.Modules.Mutations[mutation] then mutationMult = tonumber(S.Modules.Mutations[mutation].Modifier or 0) end
    end
    local final = baseGen * (1 + traitMult + mutationMult)
    return math.max(1, math.round(final))
end

local function formatNumber(num)
    local value, suffix
    if num >= 1e12 then value = num / 1e12; suffix = "T/s"
    elseif num >= 1e9 then value = num / 1e9; suffix = "B/s"
    elseif num >= 1e6 then value = num / 1e6; suffix = "M/s"
    elseif num >= 1e3 then value = num / 1e3; suffix = "K/s"
    else return string.format("%.0f/s", num) end
    if value == math.floor(value) then return string.format("%.0f%s", value, suffix)
    else return string.format("%.1f%s", value, suffix) end
end

local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local yourBase = plotSign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return true end
    end
    return false
end

local function findHighestBrainrot()
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local highest = {value = 0}
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("Model") and S.Modules.Animals and S.Modules.Animals[obj.Name] then
                    pcall(function()
                        local gen = getFinalGeneration(obj)
                        if gen > 0 and gen > highest.value then
                            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                            if root then
                                highest = {
                                    plot = plot, plotName = plot.Name, petName = obj.Name,
                                    generation = gen, formattedValue = formatNumber(gen),
                                    model = obj, value = gen
                                }
                            end
                        end
                    end)
                end
            end
        end
    end
    return highest.value > 0 and highest or nil
end

local function createHighestValueESP(brainrotData)
    if not brainrotData or not brainrotData.model then return end
    pcall(function()
        -- Cleanup Lama
        if ESP_Best.Objects.highlight then ESP_Best.Objects.highlight:Destroy() end
        if ESP_Best.Objects.nameLabel then ESP_Best.Objects.nameLabel:Destroy() end
        if ESP_Best.Objects.boxAdornment then ESP_Best.Objects.boxAdornment:Destroy() end
        if ESP_Best.Objects.podiumHighlight then ESP_Best.Objects.podiumHighlight:Destroy() end
        if ESP_Best.Objects.tracerBeam then ESP_Best.Objects.tracerBeam:Destroy() end
        if ESP_Best.Objects.tracerConn then ESP_Best.Objects.tracerConn:Disconnect() end
        
        local espContainer = {}
        local model = brainrotData.model
        local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA('BasePart')
        if not part then return end
        
        -- Highlight
        local highlight = Instance.new("Highlight", model)
        highlight.Name = "BrainrotESPHighlight"; highlight.Adornee = model
        highlight.FillColor = Color3.fromRGB(255, 0, 0); highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.6; highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espContainer.highlight = highlight
        
        -- Box
        local boxAdornment = Instance.new("BoxHandleAdornment")
        boxAdornment.Name = "BrainrotBoxHighlight"; boxAdornment.Adornee = part
        boxAdornment.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
        boxAdornment.Color3 = Color3.fromRGB(255, 0, 0); boxAdornment.Transparency = 0.7
        boxAdornment.AlwaysOnTop = true; boxAdornment.ZIndex = 1; boxAdornment.Parent = part
        espContainer.boxAdornment = boxAdornment
        
        -- Podium Highlight
        local plot = brainrotData.plot
        if plot then
            local podium = plot:FindFirstChild("Podium") or plot:FindFirstChild("Platform") or plot:FindFirstChild("Base")
            if podium and podium:IsA("BasePart") then
                local podiumHighlight = Instance.new("Highlight")
                podiumHighlight.Name = "PodiumOutline"; podiumHighlight.Adornee = podium
                podiumHighlight.FillColor = Color3.fromRGB(255, 0, 0); podiumHighlight.FillTransparency = 0.9
                podiumHighlight.OutlineColor = Color3.fromRGB(255, 0, 0); podiumHighlight.OutlineTransparency = 0
                podiumHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; podiumHighlight.Parent = podium
                espContainer.podiumHighlight = podiumHighlight
            end
        end
        
        -- Billboard
        local billboard = Instance.new("BillboardGui", part)
        billboard.Size = UDim2.new(0, 220, 0, 80); billboard.StudsOffset = Vector3.new(0, 8, 0); billboard.AlwaysOnTop = true
        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0); container.BackgroundTransparency = 1
        
        local petNameLabel = Instance.new("TextLabel", container)
        petNameLabel.Size = UDim2.new(1, 0, 0.5, 0); petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = brainrotData.petName or "Unknown"; petNameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        petNameLabel.TextStrokeTransparency = 0; petNameLabel.TextScaled = true; petNameLabel.Font = Enum.Font.Arcade
        petNameLabel.TextXAlignment = Enum.TextXAlignment.Center; petNameLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        local genLabel = Instance.new("TextLabel", container)
        genLabel.Size = UDim2.new(1, 0, 0.5, 0); genLabel.Position = UDim2.new(0, 0, 0.5, 0); genLabel.BackgroundTransparency = 1
        genLabel.Text = brainrotData.formattedValue or formatNumber(brainrotData.generation or 0); genLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        genLabel.TextStrokeTransparency = 0; genLabel.TextScaled = true; genLabel.Font = Enum.Font.Arcade
        genLabel.TextXAlignment = Enum.TextXAlignment.Center; genLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        espContainer.nameLabel = billboard
        ESP_Best.Objects = espContainer
        ESP_Best.Data = brainrotData
        
        -- Notification Logic
        if ESP_Best.Enabled then
            local petName = brainrotData.petName or "Unknown"
            local genValue = brainrotData.formattedValue or formatNumber(brainrotData.generation or 0)
            if not ESP_Best.LastNotifiedPet or ESP_Best.LastNotifiedPet ~= petName .. genValue then
                ESP_Best.LastNotifiedPet = petName .. genValue
                ArcadeUILib:Notify(petName .. " " .. genValue)
            end
        end
    end)
end

local function createTracerLine()
    if not ESP_Best.Data or not ESP_Best.Data.model then return false end
    local character = S.LocalPlayer.Character
    if not character then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local targetPart = ESP_Best.Data.model.PrimaryPart or ESP_Best.Data.model:FindFirstChild("HumanoidRootPart") or ESP_Best.Data.model:FindFirstChildWhichIsA('BasePart')
    if not targetPart then return false end
    
    pcall(function()
        if ESP_Best.Objects.tracerConn then ESP_Best.Objects.tracerConn:Disconnect() end
        if ESP_Best.Objects.tracerBeam then ESP_Best.Objects.tracerBeam:Destroy() end
        if ESP_Best.Objects.tracerAtt0 then ESP_Best.Objects.tracerAtt0:Destroy() end
        if ESP_Best.Objects.tracerAtt1 then ESP_Best.Objects.tracerAtt1:Destroy() end
        
        local tracerAttachment0 = Instance.new("Attachment")
        tracerAttachment0.Name = "Att0"; tracerAttachment0.Parent = rootPart
        
        local tracerAttachment1 = Instance.new("Attachment")
        tracerAttachment1.Name = "Att1"; tracerAttachment1.Parent = targetPart
        
        local tracerBeam = Instance.new("Beam")
        tracerBeam.Name = "TracerBeam"
        tracerBeam.Attachment0 = tracerAttachment0; tracerBeam.Attachment1 = tracerAttachment1
        tracerBeam.FaceCamera = true; tracerBeam.Width0 = 0.3; tracerBeam.Width1 = 0.3
        tracerBeam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
        tracerBeam.Transparency = NumberSequence.new(0)
        tracerBeam.LightEmission = 1; tracerBeam.LightInfluence = 0; tracerBeam.Brightness = 3
        tracerBeam.Parent = rootPart
        
        ESP_Best.Objects.tracerAtt0 = tracerAttachment0
        ESP_Best.Objects.tracerAtt1 = tracerAttachment1
        ESP_Best.Objects.tracerBeam = tracerBeam
        
        local pulseTime = 0
        ESP_Best.Objects.tracerConn = S.RunService.Heartbeat:Connect(function(dt)
            if tracerBeam and tracerBeam.Parent and ESP_Best.Enabled then
                pulseTime = pulseTime + dt
                local pulse = (math.sin(pulseTime * 3) + 1) / 2
                local r = 230 + (25 * pulse)
                tracerBeam.Color = ColorSequence.new(Color3.fromRGB(r, 0, 0))
                local width = 0.25 + (0.15 * pulse)
                tracerBeam.Width0 = width; tracerBeam.Width1 = width
                if targetPart and targetPart.Parent and tracerAttachment1 then tracerAttachment1.Parent = targetPart end
            else
                if ESP_Best.Objects.tracerConn then ESP_Best.Objects.tracerConn:Disconnect() end
            end
        end)
    end)
    return true
end

local function removeTracerLine()
    if ESP_Best.Objects.tracerConn then ESP_Best.Objects.tracerConn:Disconnect(); ESP_Best.Objects.tracerConn = nil end
    if ESP_Best.Objects.tracerBeam then ESP_Best.Objects.tracerBeam:Destroy(); ESP_Best.Objects.tracerBeam = nil end
    if ESP_Best.Objects.tracerAtt0 then ESP_Best.Objects.tracerAtt0:Destroy(); ESP_Best.Objects.tracerAtt0 = nil end
    if ESP_Best.Objects.tracerAtt1 then ESP_Best.Objects.tracerAtt1:Destroy(); ESP_Best.Objects.tracerAtt1 = nil end
end

local function refreshTracerLine()
    if not ESP_Best.Enabled or not ESP_Best.Data then removeTracerLine(); return end
    removeTracerLine()
    createTracerLine()
end

local function checkPetExists()
    if not ESP_Best.Data then return false end
    local exists = false
    pcall(function()
        local model = ESP_Best.Data.model
        if model and model.Parent then exists = true end
    end)
    return exists
end

local function updateHighestValueESP()
    if ESP_Best.Data and not checkPetExists() then
        if ESP_Best.Objects.highlight then ESP_Best.Objects.highlight:Destroy() end
        if ESP_Best.Objects.nameLabel then ESP_Best.Objects.nameLabel:Destroy() end
        if ESP_Best.Objects.boxAdornment then ESP_Best.Objects.boxAdornment:Destroy() end
        if ESP_Best.Objects.podiumHighlight then ESP_Best.Objects.podiumHighlight:Destroy() end
        ESP_Best.Objects = {}
        ESP_Best.Data = nil
        removeTracerLine()
        ESP_Best.LastNotifiedPet = nil
    end
    
    local newHighest = findHighestBrainrot()
    if newHighest then
        if not ESP_Best.Data or newHighest.value > ESP_Best.Data.value then
            createHighestValueESP(newHighest)
            if ESP_Best.Enabled then refreshTracerLine() end
            return newHighest
        end
    end
    return ESP_Best.Data
end

-- Public API
function ESP_Best.Enable()
    if ESP_Best.Enabled then return end
    ESP_Best.Enabled = true
    updateHighestValueESP()
    if ESP_Best.Thread then task.cancel(ESP_Best.Thread) end
    local lastTracerRefresh = 0
    ESP_Best.Thread = task.spawn(function()
        while ESP_Best.Enabled do
            S.RunService.Heartbeat:Wait()
            updateHighestValueESP()
            if tick() - lastTracerRefresh >= 2 then
                refreshTracerLine()
                lastTracerRefresh = tick()
            end
        end
    end)
    print("✅ ESP Best Enabled")
end

function ESP_Best.Disable()
    if not ESP_Best.Enabled then return end
    ESP_Best.Enabled = false
    if ESP_Best.Objects.highlight then ESP_Best.Objects.highlight:Destroy() end
    if ESP_Best.Objects.nameLabel then ESP_Best.Objects.nameLabel:Destroy() end
    if ESP_Best.Objects.boxAdornment then ESP_Best.Objects.boxAdornment:Destroy() end
    if ESP_Best.Objects.podiumHighlight then ESP_Best.Objects.podiumHighlight:Destroy() end
    removeTracerLine()
    ESP_Best.Objects = {}
    ESP_Best.Data = nil
    if ESP_Best.Thread then task.cancel(ESP_Best.Thread); ESP_Best.Thread = nil end
    print("❌ ESP Best Disabled")
end

function ESP_Best.Toggle(state)
    if state then ESP_Best.Enable() else ESP_Best.Disable() end
end

--- [[ MODULE: BASE LINE ]] ---
local BaseLine = {
    Enabled = false,
    Connection = nil,
    BeamPart = nil,
    TargetPart = nil,
    Beam = nil,
    Animation = nil
}

local function findPlayerPlot()
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then warn("❌ Plots folder not found!"); return nil end
    local playerBaseName = S.LocalPlayer.DisplayName .. "'s Base"
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("SurfaceGui") then
                local surfaceGui = plotSign.SurfaceGui
                if surfaceGui:FindFirstChild("Frame") and surfaceGui.Frame:FindFirstChild("TextLabel") then
                    local plotSignText = surfaceGui.Frame.TextLabel.Text
                    if plotSignText == playerBaseName then
                        print("✅ Found player's plot:", plot.Name)
                        return plot, plotSign
                    end
                end
            end
        end
    end
    warn("❌ Player's base not found!")
    return nil, nil
end

local function createPlotLine()
    local Character = S.LocalPlayer.Character
    if not Character then return false end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end
    
    local playerPlot, plotSign = findPlayerPlot()
    if not playerPlot or not plotSign then warn("❌ Cannot find your base or its sign!"); return false end
    
    local targetPosition = plotSign.Position
    print("📍 Creating line to PlotSign at:", targetPosition)
    
    BaseLine.TargetPart = Instance.new("Part")
    BaseLine.TargetPart.Name = "PlotLineTarget"; BaseLine.TargetPart.Size = Vector3.new(0.1, 0.1, 0.1)
    BaseLine.TargetPart.Position = targetPosition; BaseLine.TargetPart.Anchored = true
    BaseLine.TargetPart.CanCollide = false; BaseLine.TargetPart.Transparency = 1; BaseLine.TargetPart.Parent = S.Workspace
    
    BaseLine.BeamPart = Instance.new("Part")
    BaseLine.BeamPart.Name = "PlotLineBeam"; BaseLine.BeamPart.Size = Vector3.new(0.1, 0.1, 0.1)
    BaseLine.BeamPart.Transparency = 1; BaseLine.BeamPart.CanCollide = false; BaseLine.BeamPart.Parent = S.Workspace
    
    local att0 = Instance.new("Attachment"); att0.Name = "Att0"; att0.Parent = BaseLine.BeamPart
    local att1 = Instance.new("Attachment"); att1.Name = "Att1"; att1.Parent = BaseLine.TargetPart
    
    BaseLine.Beam = Instance.new("Beam"); BaseLine.Beam.Name = "PlotLineBeam"
    BaseLine.Beam.Attachment0 = att0; BaseLine.Beam.Attachment1 = att1; BaseLine.Beam.FaceCamera = true
    BaseLine.Beam.Width0 = 0.3; BaseLine.Beam.Width1 = 0.3
    BaseLine.Beam.Color = ColorSequence.new(Color3.fromRGB(100, 0, 0))
    BaseLine.Beam.Transparency = NumberSequence.new(0); BaseLine.Beam.LightEmission = 0.5; BaseLine.Beam.Parent = BaseLine.BeamPart
    
    local pulseTime = 0
    BaseLine.Animation = S.RunService.Heartbeat:Connect(function(dt)
        if BaseLine.Beam and BaseLine.Beam.Parent then
            pulseTime = pulseTime + dt
            local pulse = (math.sin(pulseTime * 2) + 1) / 2
            local r = 100 + (155 * pulse)
            BaseLine.Beam.Color = ColorSequence.new(Color3.fromRGB(r, 0, 0))
        else
            if BaseLine.Animation then BaseLine.Animation:Disconnect() end
        end
    end)
    
    BaseLine.Connection = S.RunService.Heartbeat:Connect(function()
        local char = S.LocalPlayer.Character
        if not char or not char.Parent then BaseLine.Stop(); return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and BaseLine.BeamPart and BaseLine.BeamPart.Parent then BaseLine.BeamPart.CFrame = root.CFrame end
    end)
    print("✅ Base line to PlotSign created!")
    return true
end

function BaseLine.Stop()
    if BaseLine.Connection then BaseLine.Connection:Disconnect(); BaseLine.Connection = nil end
    if BaseLine.BeamPart then BaseLine.BeamPart:Destroy(); BaseLine.BeamPart = nil end
    if BaseLine.TargetPart then BaseLine.TargetPart:Destroy(); BaseLine.TargetPart = nil end
    if BaseLine.Beam then BaseLine.Beam:Destroy(); BaseLine.Beam = nil end
    if BaseLine.Animation then BaseLine.Animation:Disconnect(); BaseLine.Animation = nil end
    print("🛑 Base line removed")
end

function BaseLine.Enable()
    if BaseLine.Enabled then return end
    BaseLine.Enabled = true
    pcall(createPlotLine)
    print("✅ Base Line Enabled")
end

function BaseLine.Disable()
    if not BaseLine.Enabled then return end
    BaseLine.Enabled = false
    pcall(BaseLine.Stop)
    print("❌ Base Line Disabled")
end

function BaseLine.Toggle(state)
    if state then BaseLine.Enable() else BaseLine.Disable() end
end

--- [[ MODULE: ANTI TURRET ]] ---
local AntiTurret = {
    Enabled = false,
    Processed = {},
    ActiveSentries = {},
    Connections = {},
    FollowConnections = {},
    MyUserId = tostring(S.LocalPlayer.UserId)
}

local function isSentryPlaced(desc)
    if not desc or not desc.Parent then return false end
    local inWorkspace = desc:IsDescendantOf(S.Workspace)
    if not inWorkspace then return false end
    for _, playerObj in pairs(S.Players:GetPlayers()) do
        if playerObj.Character and desc:IsDescendantOf(playerObj.Character) then return false end
        if playerObj.Backpack and desc:IsDescendantOf(playerObj.Backpack) then return false end
    end
    local isAnchored = false
    pcall(function()
        if desc:IsA("Model") and desc.PrimaryPart then isAnchored = desc.PrimaryPart.Anchored
        elseif desc:IsA("BasePart") then isAnchored = desc.Anchored end
    end)
    return isAnchored
end

local function isMySentry(sentryName)
    return string.find(sentryName, AntiTurret.MyUserId) ~= nil
end

local function isOwnedByPlayer(desc)
    return isMySentry(desc.Name)
end

local function findBat()
    local tool = nil
    pcall(function()
        tool = S.LocalPlayer.Backpack:FindFirstChild("Bat")
        if not tool and S.LocalPlayer.Character then tool = S.LocalPlayer.Character:FindFirstChild("Bat") end
    end)
    return tool
end

local function equipBat()
    local bat = findBat()
    if bat and bat.Parent == S.LocalPlayer.Backpack then
        pcall(function() S.LocalPlayer.Character.Humanoid:EquipTool(bat) end)
        return true
    end
    return bat and bat.Parent == S.LocalPlayer.Character
end

local function unequipBat()
    local bat = findBat()
    if bat and bat.Parent == S.LocalPlayer.Character then
        pcall(function() S.LocalPlayer.Character.Humanoid:UnequipTools() end)
    end
end

local function sentryExists(desc)
    if not desc or not desc.Parent then return false end
    local stillExists = false
    pcall(function() stillExists = desc.Parent ~= nil and desc:IsDescendantOf(S.Workspace) end)
    return stillExists
end

local function updateSentryPosition(desc)
    local char = S.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    local lookDir = hrp.CFrame.LookVector
    local spawnOffset = lookDir * 3.5 + Vector3.new(0, 1.2, 0)
    local success = pcall(function()
        if desc:IsA("Model") and desc.PrimaryPart then
            desc:SetPrimaryPartCFrame(hrp.CFrame + spawnOffset)
            for _, part in pairs(desc:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        elseif desc:IsA("BasePart") then desc.CFrame = hrp.CFrame + spawnOffset; desc.CanCollide = false end
    end)
    return success
end

local function destroySentry(desc)
    if not AntiTurret.Enabled then return end
    if AntiTurret.ActiveSentries[desc] then return end
    if AntiTurret.Processed[desc] then return end
    if isOwnedByPlayer(desc) then print("[🛡️] Skipping own sentry: " .. desc.Name); AntiTurret.Processed[desc] = true; return end
    if not isSentryPlaced(desc) then print("[⏳] Sentry not placed yet, skipping: " .. desc.Name); return end
    
    local char = S.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    AntiTurret.ActiveSentries[desc] = true; AntiTurret.Processed[desc] = true
    
    local bat = findBat()
    if not bat then warn("[⚠️] Bat not found!"); AntiTurret.ActiveSentries[desc] = nil; return end
    print("[🎯] Attacking enemy sentry: " .. desc.Name)
    
    local hitCount = 0
    local running = true
    
    local destroyConnection = desc.AncestryChanged:Connect(function()
        if not sentryExists(desc) then running = false; print("[💥] Sentry destroyed! Total hits: " .. hitCount); if destroyConnection then destroyConnection:Disconnect() end end
    end)
    
    local followConnection = S.RunService.RenderStepped:Connect(function()
        if not running or not AntiTurret.Enabled or not sentryExists(desc) then
            if followConnection then followConnection:Disconnect(); AntiTurret.FollowConnections[desc] = nil end
            return
        end
        updateSentryPosition(desc)
    end)
    AntiTurret.FollowConnections[desc] = followConnection
    
    task.spawn(function()
        while running and AntiTurret.Enabled and sentryExists(desc) do
            equipBat(); task.wait(0.05)
            if not running or not sentryExists(desc) then break end
            unequipBat(); task.wait(0.05)
        end
    end)
    
    task.spawn(function()
        task.wait(0.1)
        local spamConnection = S.RunService.Heartbeat:Connect(function()
            if not AntiTurret.Enabled or not sentryExists(desc) then
                running = false; if spamConnection then spamConnection:Disconnect() end
                if destroyConnection then destroyConnection:Disconnect() end
                if AntiTurret.FollowConnections[desc] then AntiTurret.FollowConnections[desc]:Disconnect(); AntiTurret.FollowConnections[desc] = nil end
                unequipBat(); AntiTurret.ActiveSentries[desc] = nil
                if not sentryExists(desc) then print("[✅] Enemy sentry DESTROYED! Total hits: " .. hitCount) else print("[⏹️] Attack stopped. Hits: " .. hitCount) end
                return
            end
            local currentBat = findBat()
            if currentBat and currentBat.Parent == S.LocalPlayer.Character then
                for i = 1, 12 do if currentBat.Parent == S.LocalPlayer.Character and sentryExists(desc) then currentBat:Activate(); hitCount = hitCount + 1 else break end end
            end
        end)
    end)
end

local function scanExistingSentries()
    if not AntiTurret.Enabled then return end
    local char = S.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local foundCount = 0
    pcall(function()
        for _, desc in pairs(S.Workspace:GetDescendants()) do
            if AntiTurret.Enabled and (desc:IsA("Model") or desc:IsA("BasePart")) then
                if string.find(desc.Name:lower(), "sentry") then
                    if isSentryPlaced(desc) and not AntiTurret.Processed[desc] and not isOwnedByPlayer(desc) then
                        foundCount = foundCount + 1; updateSentryPosition(desc); destroySentry(desc); task.wait(0.1)
                    end
                end
            end
        end
    end)
    if foundCount > 0 then print("[🔍] Scan found " .. foundCount .. " placed enemy sentries") end
end

local function startSentryWatch()
    if AntiTurret.Connections.Sentry then AntiTurret.Connections.Sentry:Disconnect() end
    if AntiTurret.Connections.Scan then task.cancel(AntiTurret.Connections.Scan) end
    
    AntiTurret.Connections.Sentry = S.Workspace.DescendantAdded:Connect(function(desc)
        if not AntiTurret.Enabled then return end
        if not desc:IsA("Model") and not desc:IsA("BasePart") then return end
        if not string.find(desc.Name:lower(), "sentry") then return end
        local char = S.LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        if isOwnedByPlayer(desc) then print("[🛡️] Detected own sentry: " .. desc.Name); AntiTurret.Processed[desc] = true; return end
        task.wait(0.5)
        if not isSentryPlaced(desc) then
            print("[⏳] Waiting for sentry to be placed: " .. desc.Name)
            task.spawn(function()
                local waitTime = 0
                while waitTime < 10 and not isSentryPlaced(desc) and sentryExists(desc) and AntiTurret.Enabled do
                    task.wait(0.5); waitTime = waitTime + 0.5
                end
                if isSentryPlaced(desc) and sentryExists(desc) and AntiTurret.Enabled then
                    print("[✅] Sentry placed, attacking: " .. desc.Name); updateSentryPosition(desc); destroySentry(desc)
                end
            end)
            return
        end
        task.wait(4.1)
        if not sentryExists(desc) or not AntiTurret.Enabled then return end
        updateSentryPosition(desc); destroySentry(desc)
    end)
    
    AntiTurret.Connections.Scan = task.spawn(function()
        while AntiTurret.Enabled do scanExistingSentries(); task.wait(5) end
    end)
    print("✅ Sentry Watch V4: Started (RenderStepped follow mode)")
end

function AntiTurret.Enable()
    if AntiTurret.Enabled then return end
    AntiTurret.Enabled = true
    startSentryWatch()
    print("✅ Anti Turret Enabled")
end

function AntiTurret.Disable()
    if not AntiTurret.Enabled then return end
    AntiTurret.Enabled = false
    if AntiTurret.Connections.Sentry then AntiTurret.Connections.Sentry:Disconnect(); AntiTurret.Connections.Sentry = nil end
    if AntiTurret.Connections.Scan then task.cancel(AntiTurret.Connections.Scan); AntiTurret.Connections.Scan = nil end
    for _, conn in pairs(AntiTurret.FollowConnections) do if conn then conn:Disconnect() end end
    AntiTurret.FollowConnections = {}; AntiTurret.ActiveSentries = {}; AntiTurret.Processed = {}
    print("❌ Anti Turret Disabled")
end

function AntiTurret.Toggle(state)
    if state then AntiTurret.Enable() else AntiTurret.Disable() end
end

--- [[ MODULE: AIMBOT ]] ---
local Aimbot = {
    Enabled = false,
    Thread = nil,
    BlacklistNames = {"alex4eva", "jkxkelu", "BigTulaH", "xxxdedmoth", "JokiTablet", "sleepkola", "Aimbot36022", "Djrjdjdk0", "elsodidudujd", "SENSEIIIlSALT", "yaniecky", "ISAAC_EVO", "7xc_ls", "itz_d1egx"},
    Blacklist = {}
}
for _, name in ipairs(Aimbot.BlacklistNames) do Aimbot.Blacklist[string.lower(name)] = true end

local function getLaserRemote()
    local remote = nil
    pcall(function()
        if S.ReplicatedStorage:FindFirstChild("Packages") and S.ReplicatedStorage.Packages:FindFirstChild("Net") then
            remote = S.ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem") or S.ReplicatedStorage.Packages.Net:FindFirstChild("RE"):FindFirstChild("UseItem")
        end
        if not remote then remote = S.ReplicatedStorage:FindFirstChild("RE/UseItem") or S.ReplicatedStorage:FindFirstChild("UseItem") end
    end)
    return remote
end

local function isValidTarget(p)
    if not p or not p.Character or p == S.LocalPlayer then return false end
    local name = p.Name and string.lower(p.Name) or ""
    if Aimbot.Blacklist[name] then return false end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    return true
end

local function findNearestAllowed()
    if not S.LocalPlayer.Character or not S.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = S.LocalPlayer.Character.HumanoidRootPart.Position
    local nearest = nil; local nearestDist = math.huge
    for _, pl in ipairs(S.Players:GetPlayers()) do
        if isValidTarget(pl) then
            local targetHRP = pl.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
                if d < nearestDist then nearestDist = d; nearest = pl end
            end
        end
    end
    return nearest
end

local function safeFire(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local remote = getLaserRemote()
    local args = {[1] = targetHRP.Position, [2] = targetHRP}
    if remote and remote.FireServer then pcall(function() remote:FireServer(unpack(args)) end) end
end

local function autoLaserWorker()
    while Aimbot.Enabled do
        local target = findNearestAllowed()
        if target then safeFire(target) end
        local t0 = tick()
        while tick() - t0 < 0.6 do if not Aimbot.Enabled then break end; S.RunService.Heartbeat:Wait() end
    end
end

function Aimbot.Enable()
    if Aimbot.Enabled then return end
    Aimbot.Enabled = true
    if Aimbot.Thread then task.cancel(Aimbot.Thread) end
    Aimbot.Thread = task.spawn(autoLaserWorker)
    print("✓ Laser Cape (Aimbot): ON")
end

function Aimbot.Disable()
    if not Aimbot.Enabled then return end
    Aimbot.Enabled = false
    if Aimbot.Thread then task.cancel(Aimbot.Thread); Aimbot.Thread = nil end
    print("✗ Laser Cape (Aimbot): OFF")
end

function Aimbot.Toggle(state)
    if state then Aimbot.Enable() else Aimbot.Disable() end
end

--- [[ MODULE: KICK STEAL ]] ---
local KickSteal = {
    Enabled = false,
    LastStealCount = 0,
    Connection = nil
}

local function getStealCount()
    local success, result = pcall(function()
        if not S.LocalPlayer or not S.LocalPlayer:FindFirstChild("leaderstats") then return 0 end
        local stealsObject = S.LocalPlayer.leaderstats:FindFirstChild("Steals")
        if not stealsObject then return 0 end
        if stealsObject:IsA("IntValue") or stealsObject:IsA("NumberValue") then return stealsObject.Value
        elseif stealsObject:IsA("StringValue") then return tonumber(stealsObject.Value) or 0
        else return tonumber(tostring(stealsObject.Value)) or 0 end
    end)
    return success and result or 0
end

local function kickPlayer()
    local success = pcall(function() S.LocalPlayer:Kick("Steal Success!") end)
    if not success then warn("Failed to kick, attempting shutdown..."); game:Shutdown() end
end

local function startMonitoring()
    KickSteal.Connection = S.RunService.Heartbeat:Connect(function()
        if not KickSteal.Enabled then return end
        local currentStealCount = getStealCount()
        if currentStealCount > KickSteal.LastStealCount then
            print("🚨 [Monitor] Steal detected!", KickSteal.LastStealCount, "→", currentStealCount)
            KickSteal.Enabled = false
            if KickSteal.Connection then KickSteal.Connection:Disconnect(); KickSteal.Connection = nil end
            task.wait(0.1); kickPlayer()
        end
        KickSteal.LastStealCount = currentStealCount
    end)
end

function KickSteal.Enable()
    if KickSteal.Enabled then return end
    KickSteal.Enabled = true; KickSteal.LastStealCount = getStealCount()
    print("✅ [Monitor] Started. Initial steals:", KickSteal.LastStealCount); startMonitoring()
    print("✅ Auto Kick After Steal: ON")
end

function KickSteal.Disable()
    if not KickSteal.Enabled then return end
    KickSteal.Enabled = false; print("⛔ [Monitor] Stopped")
    if KickSteal.Connection then KickSteal.Connection:Disconnect(); KickSteal.Connection = nil end
    print("❌ Auto Kick After Steal: OFF")
end

function KickSteal.Toggle(state)
    if state then KickSteal.Enable() else KickSteal.Disable() end
end

--- [[ MODULE: UNWALK ANIM ]] ---
local UnwalkAnim = {
    Enabled = false,
    Connections = {}
}

local function setupNoWalkAnimation(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    local function stopAllAnimations()
        local tracks = animator:GetPlayingAnimationTracks()
        for _, track in pairs(tracks) do if track.IsPlaying then track:Stop() end end
    end
    local runningConnection = humanoid.Running:Connect(function(speed) stopAllAnimations() end)
    local jumpingConnection = humanoid.Jumping:Connect(function() stopAllAnimations() end)
    local animationPlayedConnection = animator.AnimationPlayed:Connect(function(animationTrack) animationTrack:Stop() end)
    local renderSteppedConnection = S.RunService.RenderStepped:Connect(function() stopAllAnimations() end)
    table.insert(UnwalkAnim.Connections, runningConnection)
    table.insert(UnwalkAnim.Connections, jumpingConnection)
    table.insert(UnwalkAnim.Connections, animationPlayedConnection)
    table.insert(UnwalkAnim.Connections, renderSteppedConnection)
    print("✅ No Walk Animation: AKTIF")
end

function UnwalkAnim.Enable()
    if UnwalkAnim.Enabled then return end
    UnwalkAnim.Enabled = true
    if S.LocalPlayer.Character then setupNoWalkAnimation(S.LocalPlayer.Character) end
    print("✅ Unwalk Animation Enabled")
end

function UnwalkAnim.Disable()
    if not UnwalkAnim.Enabled then return end
    UnwalkAnim.Enabled = false
    for _, connection in pairs(UnwalkAnim.Connections) do if connection then connection:Disconnect() end end
    UnwalkAnim.Connections = {}
    print("❌ Unwalk Animation Disabled")
end

function UnwalkAnim.Toggle(state)
    if state then UnwalkAnim.Enable() else UnwalkAnim.Disable() end
end

--- [[ MODULE: AUTO STEAL ]] ---
local AutoSteal = {
    Enabled = false,
    AllAnimalsCache = {},
    PromptMemoryCache = {},
    InternalStealCache = {},
    Connection = nil,
    Radius = 20
}

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then return false end
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return false end
    if S.Modules.Synchronizer then
        local channel = S.Modules.Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == S.LocalPlayer.UserId
                elseif typeof(owner) == "table" and owner.UserId then return owner.UserId == S.LocalPlayer.UserId
                elseif typeof(owner) == "Instance" then return owner == S.LocalPlayer end
            end
        end
    end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then return yourBase.Enabled == true end
    end
    return false
end

local function findProximityPromptForAnimal(animalData)
    if not animalData then return nil end
    local cachedPrompt = AutoSteal.PromptMemoryCache[animalData.uid]
    if cachedPrompt and cachedPrompt.Parent then return cachedPrompt end
    local plot = S.Workspace.Plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    local base = podium:FindFirstChild("Base")
    if not base then return nil end
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return nil end
    local attach = spawn:FindFirstChild("PromptAttachment")
    if not attach then return nil end
    for _, p in ipairs(attach:GetChildren()) do if p:IsA("ProximityPrompt") then AutoSteal.PromptMemoryCache[animalData.uid] = p; return p end end
    return nil
end

local function getAnimalPosition(animalData)
    local plot = S.Workspace.Plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    return podium:GetPivot().Position
end

local function getNearestAnimal()
    local character = S.LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    if not hrp then return nil end
    local nearest = nil; local minDist = math.huge
    for _, animalData in ipairs(AutoSteal.AllAnimalsCache) do
        if isMyBaseAnimal(animalData) then continue end
        local pos = getAnimalPosition(animalData)
        if pos then
            local dist = (hrp.Position - pos).Magnitude
            if dist < minDist then minDist = dist; nearest = animalData end
        end
    end
    return nearest
end

local function buildStealCallbacks(prompt)
    if AutoSteal.InternalStealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then for _, conn in ipairs(conns1) do if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end end end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then for _, conn in ipairs(conns2) do if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end end end
    if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then AutoSteal.InternalStealCache[prompt] = data end
end

local function executeInternalStealAsync(prompt)
    local data = AutoSteal.InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        if #data.holdCallbacks > 0 then for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end end
        task.wait(1.3)
        if #data.triggerCallbacks > 0 then for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end end
        task.wait(0.1); data.ready = true
    end)
    return true
end

local function attemptSteal(prompt)
    if not prompt or not prompt.Parent then return false end
    buildStealCallbacks(prompt)
    if not AutoSteal.InternalStealCache[prompt] then return false end
    return executeInternalStealAsync(prompt)
end

local function scanAllPlots()
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return {} end
    local newCache = {}
    for _, plot in ipairs(plots:GetChildren()) do
        if not S.Modules.Synchronizer then continue end
        local channel = S.Modules.Synchronizer:Get(plot.Name)
        if not channel then continue end
        local animalList = channel:Get("AnimalList")
        if not animalList then continue end
        local owner = channel:Get("Owner")
        if not owner then continue end
        local ownerName = "Unknown"
        if typeof(owner) == "Instance" and owner:IsA("Player") then ownerName = owner.Name
        elseif typeof(owner) == "table" and owner.Name then ownerName = owner.Name end
        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table" then
                local animalName = animalData.Index
                local animalInfo = S.Modules.AnimalsData[animalName]
                if not animalInfo then continue end
                local genValue = S.Modules.AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
                table.insert(newCache, {
                    name = animalInfo.DisplayName or animalName, genValue = genValue, owner = ownerName,
                    plot = plot.Name, slot = tostring(slot), uid = plot.Name .. "_" .. tostring(slot),
                })
            end
        end
    end
    AutoSteal.AllAnimalsCache = newCache
    table.sort(AutoSteal.AllAnimalsCache, function(a, b) return a.genValue > b.genValue end)
    return #AutoSteal.AllAnimalsCache
end

local function startAutoSteal()
    AutoSteal.Connection = S.RunService.Heartbeat:Connect(function()
        if not AutoSteal.Enabled then return end
        local targetAnimal = getNearestAnimal()
        if not targetAnimal then return end
        local character = S.LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
        if not hrp then return end
        local animalPos = getAnimalPosition(targetAnimal)
        if not animalPos then return end
        local dist = (hrp.Position - animalPos).Magnitude
        if dist > AutoSteal.Radius then return end
        local prompt = AutoSteal.PromptMemoryCache[targetAnimal.uid]
        if not prompt or not prompt.Parent then prompt = findProximityPromptForAnimal(targetAnimal) end
        if prompt then attemptSteal(prompt) end
    end)
end

function AutoSteal.Enable()
    if AutoSteal.Enabled then return end
    AutoSteal.Enabled = true; startAutoSteal()
    print("✅ Auto Steal Enabled")
end

function AutoSteal.Disable()
    if not AutoSteal.Enabled then return end
    AutoSteal.Enabled = false
    if AutoSteal.Connection then AutoSteal.Connection:Disconnect(); AutoSteal.Connection = nil end
    print("❌ Auto Steal Disabled")
end

function AutoSteal.Toggle(state)
    if state then AutoSteal.Enable() else AutoSteal.Disable() end
end

--- [[ MODULE: ANTI DEBUFF ]] ---
local AntiDebuff = {
    BeeEnabled = false,
    BoogieEnabled = false,
    IsEventHandlerActive = false,
    Connections = {},
    BoogieAnimId = "109061983885712"
}

local function updateUseItemEventHandler()
    local success, Event = pcall(function() return require(S.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")):RemoteEvent("UseItem") end)
    if not success or not Event then warn("Could not find UseItem event. Anti-Debuff feature will not work."); return end
    if not AntiDebuff.BeeEnabled and not AntiDebuff.BoogieEnabled then
        if AntiDebuff.IsEventHandlerActive then
            if AntiDebuff.Connections.Unified then AntiDebuff.Connections.Unified:Disconnect(); AntiDebuff.Connections.Unified = nil end
            for _, conn in pairs(AntiDebuff.Connections.Originals) do pcall(function() conn:Enable() end) end
            AntiDebuff.Connections.Originals = {}; AntiDebuff.IsEventHandlerActive = false
        end
        return
    end
    if (AntiDebuff.BeeEnabled or AntiDebuff.BoogieEnabled) and not AntiDebuff.IsEventHandlerActive then
        for i, v in pairs(getconnections(Event.OnClientEvent)) do table.insert(AntiDebuff.Connections.Originals, v); pcall(function() v:Disable() end) end
        AntiDebuff.Connections.Unified = Event.OnClientEvent:Connect(function(Action, ...)
            if AntiDebuff.BeeEnabled and Action == "Bee Attack" then print("🐝 Blocked Bee Attack!"); return end
            if AntiDebuff.BoogieEnabled and Action == "Boogie" then print("🕺 Blocked Boogie Bomb!"); return end
        end)
        AntiDebuff.IsEventHandlerActive = true
    end
end

local function setupInstantAnimationBlocker()
    local character = S.LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    if AntiDebuff.Connections.AnimBlocker then AntiDebuff.Connections.AnimBlocker:Disconnect() end
    AntiDebuff.Connections.AnimBlocker = animator.AnimationPlayed:Connect(function(track)
        if track and track.Animation and tostring(track.Animation.AnimationId):gsub("%D", "") == AntiDebuff.BoogieAnimId then
            track:Stop(0); track:Destroy(); print("⚡ INSTANT BLOCK: Boogie animation destroyed!")
        end
    end)
end

local function enableContinuousMonitoring()
    if AntiDebuff.Connections.Loop then AntiDebuff.Connections.Loop:Disconnect() end
    local lastCheck = 0
    AntiDebuff.Connections.Loop = S.RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastCheck < 0.03 then return end
        lastCheck = now
        pcall(function()
            if S.Lighting:FindFirstChild("DiscoEffect") then S.Lighting.DiscoEffect:Destroy() end
            for _, v in pairs(S.Lighting:GetChildren()) do if v:IsA("BlurEffect") then v:Destroy() end end
            local camera = S.Workspace.CurrentCamera
            if camera and camera.FieldOfView > 70 and camera.FieldOfView <= 80 then camera.FieldOfView = 70 end
            local boogieScript = S.LocalPlayer.PlayerScripts:FindFirstChild("Boogie", true)
            if boogieScript then local boom = boogieScript:FindFirstChild("BOOM"); if boom and boom:IsA("Sound") and boom.Playing then boom:Stop() end end
        end)
    end)
end

function AntiDebuff.Enable()
    AntiDebuff.BeeEnabled = true; AntiDebuff.BoogieEnabled = true
    updateUseItemEventHandler()
    if AntiDebuff.BoogieEnabled then setupInstantAnimationBlocker(); enableContinuousMonitoring(); print("✅ Anti Boogie Bomb: ENABLED") end
    print("✅ Anti Debuff Enabled")
end

function AntiDebuff.Disable()
    AntiDebuff.BeeEnabled = false; AntiDebuff.BoogieEnabled = false
    if AntiDebuff.Connections.AnimBlocker then AntiDebuff.Connections.AnimBlocker:Disconnect(); AntiDebuff.Connections.AnimBlocker = nil end
    if AntiDebuff.Connections.Loop then AntiDebuff.Connections.Loop:Disconnect(); AntiDebuff.Connections.Loop = nil end
    updateUseItemEventHandler()
    print("❌ Anti Debuff Disabled")
end

function AntiDebuff.Toggle(state)
    if state then AntiDebuff.Enable() else AntiDebuff.Disable() end
end

--- [[ MODULE: ANTI RAGDOLL ]] ---
local ANTI_RAGDOLL = {
    Enabled = false,
    Connections = {},
    CachedCharData = {}
}

local function getHRP()
    local char = S.LocalPlayer.Character; if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function cacheCharacterData()
    local char = S.LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    ANTI_RAGDOLL.CachedCharData = { character = char, humanoid = hum, root = root }
    return true
end

local function disconnectRagdoll()
    for _, conn in ipairs(ANTI_RAGDOLL.Connections) do if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end end
    ANTI_RAGDOLL.Connections = {}
end

local function isRagdolled()
    if not ANTI_RAGDOLL.CachedCharData.humanoid then return false end
    local hum = ANTI_RAGDOLL.CachedCharData.humanoid
    local state = hum:GetState()
    local ragdollStates = { [Enum.HumanoidStateType.Physics] = true, [Enum.HumanoidStateType.Ragdoll] = true, [Enum.HumanoidStateType.FallingDown] = true }
    if ragdollStates[state] then return true end
    local endTime = S.LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime then local now = S.Workspace:GetServerTimeNow(); if (endTime - now) > 0 then return true end end
    return false
end

local function removeRagdollConstraints()
    if not ANTI_RAGDOLL.CachedCharData.character then return end
    local removed = false
    for _, descendant in ipairs(ANTI_RAGDOLL.CachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            pcall(function() descendant:Destroy(); removed = true end)
        end
    end
    return removed
end

local function forceExitRagdoll()
    if not ANTI_RAGDOLL.CachedCharData.humanoid or not ANTI_RAGDOLL.CachedCharData.root then return end
    local hum = ANTI_RAGDOLL.CachedCharData.humanoid
    local root = ANTI_RAGDOLL.CachedCharData.root
    pcall(function() local now = S.Workspace:GetServerTimeNow(); S.LocalPlayer:SetAttribute("RagdollEndTime", now) end)
    if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function antiRagdollLoop()
    while ANTI_RAGDOLL.Enabled and ANTI_RAGDOLL.CachedCharData.humanoid do
        task.wait()
        if isRagdolled() then removeRagdollConstraints(); forceExitRagdoll() end
    end
end

local function setupCameraBinding()
    if not ANTI_RAGDOLL.CachedCharData.humanoid then return end
    local conn = S.RunService.RenderStepped:Connect(function()
        if not ANTI_RAGDOLL.Enabled then return end
        local cam = S.Workspace.CurrentCamera
        if cam and ANTI_RAGDOLL.CachedCharData.humanoid and cam.CameraSubject ~= ANTI_RAGDOLL.CachedCharData.humanoid then cam.CameraSubject = ANTI_RAGDOLL.CachedCharData.humanoid end
    end)
    table.insert(ANTI_RAGDOLL.Connections, conn)
end

local function onCharacterAdded(char)
    task.wait(0.5)
    if not ANTI_RAGDOLL.Enabled then return end
    if cacheCharacterData() then setupCameraBinding(); task.spawn(antiRagdollLoop) end
end

function ANTI_RAGDOLL.Enable()
    if ANTI_RAGDOLL.Enabled then warn("[Anti-Ragdoll] Already enabled!"); return end
    if not cacheCharacterData() then warn("[Anti-Ragdoll] Failed to cache character data"); return end
    ANTI_RAGDOLL.Enabled = true
    local charConn = S.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    table.insert(ANTI_RAGDOLL.Connections, charConn)
    setupCameraBinding(); task.spawn(antiRagdollLoop)
    print("✅ Anti-Ragdoll V2 (Moveable) Enabled")
end

function ANTI_RAGDOLL.Disable()
    if not ANTI_RAGDOLL.Enabled then return end
    ANTI_RAGDOLL.Enabled = false
    disconnectRagdoll()
    ANTI_RAGDOLL.CachedCharData = {}
    print("❌ Anti-Ragdoll V2 Disabled")
end

function ANTI_RAGDOLL.Toggle(state)
    if state then ANTI_RAGDOLL.Enable() else ANTI_RAGDOLL.Disable() end
end

--- [[ MODULE: XRAY BASE ]] ---
local XrayBase = {
    Enabled = false,
    Originals = {},
    Connection = nil
}

local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower(); local parent = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or parent:find("base")
end

local function tryApplyInvisibleWalls()
    if not XrayBase.Enabled then return end
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots or #plots:GetChildren() == 0 then return end
    print("🔍 Applying Xray to base walls..."); local processedCount = 0
    for _, plot in pairs(plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and isBaseWall(obj) then
                if not XrayBase.Originals[obj] then XrayBase.Originals[obj] = obj.LocalTransparencyModifier; obj.LocalTransparencyModifier = 0.85; processedCount = processedCount + 1 end
            end
        end
    end
    print("✅ Applied Xray to " .. processedCount .. " base walls")
end

local function cleanupRemovedParts()
    for obj, _ in pairs(XrayBase.Originals) do if not obj or not obj.Parent then XrayBase.Originals[obj] = nil end end
end

function XrayBase.Enable()
    if XrayBase.Enabled then return end
    XrayBase.Enabled = true; cleanupRemovedParts()
    task.spawn(function() task.wait(0.5); tryApplyInvisibleWalls() end)
    if XrayBase.Connection then XrayBase.Connection:Disconnect() end
    XrayBase.Connection = S.Workspace.DescendantAdded:Connect(function(obj)
        if not XrayBase.Enabled then return end
        task.wait(0.1)
        if isBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
            if not XrayBase.Originals[obj] then XrayBase.Originals[obj] = obj.LocalTransparencyModifier; obj.LocalTransparencyModifier = 0.85 end
        end
    end)
    local cleanupConnection = S.Workspace.DescendantRemoving:Connect(function(obj) if XrayBase.Originals[obj] then XrayBase.Originals[obj] = nil end end)
    print("✅ Xray Base Enabled")
end

function XrayBase.Disable()
    if not XrayBase.Enabled then return end
    XrayBase.Enabled = false
    if XrayBase.Connection then XrayBase.Connection:Disconnect(); XrayBase.Connection = nil end
    local restoredCount = 0
    for obj, value in pairs(XrayBase.Originals) do if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = value; restoredCount = restoredCount + 1 end) end end
    XrayBase.Originals = {}
    print("✅ Restored " .. restoredCount .. " base walls")
    print("❌ Xray Base Disabled")
end

function XrayBase.Toggle(state)
    if state then XrayBase.Enable() else XrayBase.Disable() end
end

--- [[ MODULE: FPS BOOST ]] ---
local FpsBoost = {
    Enabled = false,
    Threads = {},
    Connections = {},
    OriginalSettings = {}
}

local PERFORMANCE_FFLAGS = {
    ["DFIntTaskSchedulerTargetFps"] = 999, ["FFlagDebugGraphicsPreferVulkan"] = true, ["FFlagDebugGraphicsDisableDirect3D11"] = true,
    ["FFlagDebugGraphicsPreferD3D11FL10"] = false, ["DFFlagDebugRenderForceTechnologyVoxel"] = true, ["FFlagDisablePostFx"] = true,
    ["FIntRenderShadowIntensity"] = 0, ["FIntRenderLocalLightUpdatesMax"] = 0, ["FIntRenderLocalLightUpdatesMin"] = 0,
    ["DFIntTextureCompositorActiveJobs"] = 1, ["DFIntDebugFRMQualityLevelOverride"] = 1, ["FFlagFixPlayerCollisionWhenSwimming"] = false,
    ["DFIntMaxInterpolationSubsteps"] = 0, ["DFIntS2PhysicsSenderRate"] = 15, ["DFIntConnectionMTUSize"] = 1492,
    ["DFIntHttpCurlConnectionCacheSize"] = 134217728, ["DFIntCSGLevelOfDetailSwitchingDistance"] = 0, ["FFlagDebugDisableParticleRendering"] = false,
    ["DFIntParticleMaxCount"] = 100, ["FFlagEnableWaterReflections"] = false, ["DFIntWaterReflectionQuality"] = 0,
}

local function applyFFlags()
    local success = 0; local failed = 0
    for flag, value in pairs(PERFORMANCE_FFLAGS) do local ok = pcall(function() setfflag(flag, tostring(value)) end); if ok then success = success + 1 else failed = failed + 1 end end
    print(string.format("Applied %d/%d FFlags", success, success + failed))
end

local function nukeVisualEffects()
    pcall(function()
        for _, obj in ipairs(S.Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") then obj.Enabled = false; obj.Rate = 0; obj:Destroy()
                elseif obj:IsA("Trail") or obj:IsA("Explosion") then obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then obj.Enabled = false; obj.Brightness = 0; obj:Destroy()
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("SpecialMesh") then obj.TextureId = ""
                elseif obj:IsA("Decal") or obj:IsA("Texture") then if not (obj.Name == "face" and obj.Parent and obj.Parent.Name == "Head") then obj.Transparency = 1 end
                elseif obj:IsA("BasePart") then obj.CastShadow = false; obj.Material = Enum.Material.Plastic; if obj.Material == Enum.Material.Glass then obj.Reflectance = 0 end
                end
            end)
        end
    end)
end

local function optimizeCharacter(char)
    if not char then return end
    task.spawn(function()
        task.wait(0.5)
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                pcall(function()
                    if part:IsA("BasePart") then part.CastShadow = false; part.Material = Enum.Material.Plastic; part.Reflectance = 0
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then part:Destroy()
                    elseif part:IsA("PointLight") or part:IsA("SpotLight") or part:IsA("SurfaceLight") then part:Destroy()
                    elseif part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then part:Destroy()
                    end
                end)
            end
        end)
    end)
end

function FpsBoost.Enable()
    if FpsBoost.Enabled then return end
    FpsBoost.Enabled = true
    getgenv().OPTIMIZER_ACTIVE = true
    
    -- Save Settings
    pcall(function()
        FpsBoost.OriginalSettings = {
            streamingEnabled = S.Workspace.StreamingEnabled, streamingMinRadius = S.Workspace.StreamingMinRadius, streamingTargetRadius = S.Workspace.StreamingTargetRadius,
            qualityLevel = settings().Rendering.QualityLevel, meshPartDetailLevel = settings().Rendering.MeshPartDetailLevel,
            globalShadows = S.Lighting.GlobalShadows, brightness = S.Lighting.Brightness, fogEnd = S.Lighting.FogEnd,
            technology = S.Lighting.Technology, environmentDiffuseScale = S.Lighting.EnvironmentDiffuseScale,
            environmentSpecularScale = S.Lighting.EnvironmentSpecularScale, decoration = S.Workspace.Terrain.Decoration,
            waterWaveSize = S.Workspace.Terrain.WaterWaveSize, waterWaveSpeed = S.Workspace.Terrain.WaterWaveSpeed,
            waterReflectance = S.Workspace.Terrain.WaterReflectance, waterTransparency = S.Workspace.Terrain.WaterTransparency,
        }
    end)
    
    pcall(applyFFlags)
    pcall(function()
        S.Workspace.StreamingEnabled = true; S.Workspace.StreamingMinRadius = 64; S.Workspace.StreamingTargetRadius = 256; S.Workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.MinimumRadiusPause
    end)
    pcall(function()
        local renderSettings = settings().Rendering
        renderSettings.QualityLevel = Enum.QualityLevel.Level01; renderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01; renderSettings.EditQualityLevel = Enum.QualityLevel.Level01
        S.Lighting.GlobalShadows = false; S.Lighting.Brightness = 3; S.Lighting.FogEnd = 9e9; S.Lighting.Technology = Enum.Technology.Legacy
        S.Lighting.EnvironmentDiffuseScale = 0; S.Lighting.EnvironmentSpecularScale = 0
        for _, effect in ipairs(S.Lighting:GetChildren()) do if effect:IsA("PostEffect") then pcall(function() effect.Enabled = false; effect:Destroy() end) end end
    end)
    pcall(function()
        local physics = settings().Physics
        physics.AllowSleep = true; physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Skip; physics.ThrottleAdjustTime = 0
    end)
    pcall(function()
        S.Workspace.Terrain.WaterWaveSize = 0; S.Workspace.Terrain.WaterWaveSpeed = 0; S.Workspace.Terrain.WaterReflectance = 0
        S.Workspace.Terrain.WaterTransparency = 1; S.Workspace.Terrain.Decoration = false
    end)
    table.insert(FpsBoost.Threads, task.spawn(function() task.wait(1); nukeVisualEffects() end))
    table.insert(FpsBoost.Connections, S.Workspace.DescendantAdded:Connect(function(obj)
        if not getgenv().OPTIMIZER_ACTIVE then return end
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then obj:Destroy()
            elseif obj:IsA("BasePart") then obj.CastShadow = false; obj.Material = Enum.Material.Plastic end
        end)
    end))
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p.Character then optimizeCharacter(p.Character) end
        table.insert(FpsBoost.Connections, p.CharacterAdded:Connect(function(char) if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end end))
    end
    table.insert(FpsBoost.Connections, S.Players.PlayerAdded:Connect(function(p)
        table.insert(FpsBoost.Connections, p.CharacterAdded:Connect(function(char) if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end end))
    end))
    pcall(function() setfpscap(999) end)
    pcall(function() local cam = S.Workspace.CurrentCamera; cam.FieldOfView = 70 end)
    print("✅ Fps Boost Enabled")
end

function FpsBoost.Disable()
    if not FpsBoost.Enabled then return end
    FpsBoost.Enabled = false; getgenv().OPTIMIZER_ACTIVE = false
    for _, thread in ipairs(FpsBoost.Threads) do pcall(function() task.cancel(thread) end) end; FpsBoost.Threads = {}
    for _, conn in ipairs(FpsBoost.Connections) do pcall(function() conn:Disconnect() end) end; FpsBoost.Connections = {}
    pcall(function()
        S.Workspace.StreamingEnabled = FpsBoost.OriginalSettings.streamingEnabled or true; S.Workspace.StreamingMinRadius = FpsBoost.OriginalSettings.streamingMinRadius or 64
        S.Workspace.StreamingTargetRadius = FpsBoost.OriginalSettings.streamingTargetRadius or 1024; settings().Rendering.QualityLevel = FpsBoost.OriginalSettings.qualityLevel or Enum.QualityLevel.Automatic
        settings().Rendering.MeshPartDetailLevel = FpsBoost.OriginalSettings.meshPartDetailLevel or Enum.MeshPartDetailLevel.DistanceBased
        S.Lighting.GlobalShadows = FpsBoost.OriginalSettings.globalShadows ~= false; S.Lighting.Brightness = FpsBoost.OriginalSettings.brightness or 1
        S.Lighting.FogEnd = FpsBoost.OriginalSettings.fogEnd or 100000; S.Lighting.Technology = FpsBoost.OriginalSettings.technology or Enum.Technology.ShadowMap
        S.Lighting.EnvironmentDiffuseScale = FpsBoost.OriginalSettings.environmentDiffuseScale or 1; S.Lighting.EnvironmentSpecularScale = FpsBoost.OriginalSettings.environmentSpecularScale or 1
        S.Workspace.Terrain.WaterWaveSize = FpsBoost.OriginalSettings.waterWaveSize or 0.15; S.Workspace.Terrain.WaterWaveSpeed = FpsBoost.OriginalSettings.waterWaveSpeed or 10
        S.Workspace.Terrain.WaterReflectance = FpsBoost.OriginalSettings.waterReflectance or 1; S.Workspace.Terrain.WaterTransparency = FpsBoost.OriginalSettings.waterTransparency or 0.3
        S.Workspace.Terrain.Decoration = FpsBoost.OriginalSettings.decoration ~= false
    end)
    print("❌ Fps Boost Disabled")
end

function FpsBoost.Toggle(state)
    if state then FpsBoost.Enable() else FpsBoost.Disable() end
end

--- [[ MODULE: TIMER ESP ]] ---
local TimerEsp = {
    Enabled = false,
    Connections = {}
}

local function updateBillboard(mainPart, contentText, shouldShow, isUnlocked)
    local existing = mainPart:FindFirstChild("RemainingTimeGui")
    if shouldShow then
        if not existing then
            local gui = Instance.new("BillboardGui"); gui.Name = "RemainingTimeGui"; gui.Adornee = mainPart
            gui.Size = UDim2.new(0, 110, 0, 25); gui.StudsOffset = Vector3.new(0, 5, 0); gui.AlwaysOnTop = true; gui.Parent = mainPart
            local label = Instance.new("TextLabel"); label.Name = "Text"; label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
            label.TextScaled = true; label.TextColor3 = isUnlocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.2; label.Font = Enum.Font.GothamBold; label.Text = contentText; label.Parent = gui
        else
            local label = existing:FindFirstChild("Text")
            if label then label.Text = contentText; label.TextColor3 = isUnlocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255) end
        end
    else
        if existing then existing:Destroy() end
    end
end

local function findLowestValidRemainingTime(purchases)
    local lowest = nil; local lowestY = nil
    for _, purchase in pairs(purchases:GetChildren()) do
        local main = purchase:FindFirstChild("Main")
        local gui = main and main:FindFirstChild("BillboardGui")
        local remTime = gui and gui:FindFirstChild("RemainingTime")
        local locked = gui and gui:FindFirstChild("Locked")
        if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") then
            local y = main.Position.Y
            if not lowestY or y < lowestY then lowest = {remTime = remTime, locked = locked, main = main}; lowestY = y end
        end
    end
    return lowest
end

local function scanAndConnect()
    for _, plot in pairs(S.Workspace:FindFirstChild("Plots"):GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if purchases then
            local selected = findLowestValidRemainingTime(purchases)
            for _, purchase in pairs(purchases:GetChildren()) do
                local main = purchase:FindFirstChild("Main")
                local gui = main and main:FindFirstChild("BillboardGui")
                local remTime = gui and gui:FindFirstChild("RemainingTime")
                local locked = gui and gui:FindFirstChild("Locked")
                if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") then
                    local isTarget = selected and remTime == selected.remTime
                    local isUnlocked = not locked.Visible
                    local displayText = isUnlocked and "Unlocked" or remTime.Text
                    updateBillboard(main, displayText, isTarget, isUnlocked)
                    local key = remTime:GetDebugId()
                    if isTarget and not TimerEsp.Connections[key] then
                        local function refresh()
                            local stillTarget = (findLowestValidRemainingTime(purchases) or {}).remTime == remTime
                            local isUnlocked = not locked.Visible
                            local displayText = isUnlocked and "Unlocked" or remTime.Text
                            updateBillboard(main, displayText, stillTarget, isUnlocked)
                        end
                        local conn1 = remTime:GetPropertyChangedSignal("Text"):Connect(refresh)
                        local conn2 = locked:GetPropertyChangedSignal("Visible"):Connect(refresh)
                        TimerEsp.Connections[key] = {conn1, conn2}
                    end
                end
            end
        end
    end
end

function TimerEsp.Enable()
    if TimerEsp.Enabled then return end
    TimerEsp.Enabled = true
    S.StarterGui:SetCore("SendNotification", {Title = "Timer ESP", Text = "Timer ESP: ON", Duration = 2})
    task.spawn(function() while TimerEsp.Enabled do pcall(scanAndConnect); task.wait(5) end end)
    print("✅ Timer ESP enabled")
end

function TimerEsp.Disable()
    if not TimerEsp.Enabled then return end
    TimerEsp.Enabled = false
    S.StarterGui:SetCore("SendNotification", {Title = "Timer ESP", Text = "Timer ESP: OFF", Duration = 2})
    for _, plot in pairs(S.Workspace:FindFirstChild("Plots"):GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if purchases then for _, purchase in pairs(purchases:GetChildren()) do local main = purchase:FindFirstChild("Main"); if main then local gui = main:FindFirstChild("RemainingTimeGui"); if gui then gui:Destroy() end end end end
    end
    for _, connections in pairs(TimerEsp.Connections) do for _, connection in ipairs(connections) do connection:Disconnect() end end
    TimerEsp.Connections = {}
    print("❌ Timer ESP disabled")
end

function TimerEsp.Toggle(state)
    if state then TimerEsp.Enable() else TimerEsp.Disable() end
end

-- ==================== EVENT HANDLERS (GLOBAL SCOPE WRAPPER) ====================

-- Player Events
S.Players.PlayerAdded:Connect(function(targetPlayer)
    targetPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        if ESP_Players.Enabled and targetPlayer ~= S.LocalPlayer then createESP(targetPlayer) end
    end)
end)

S.Players.PlayerRemoving:Connect(function(targetPlayer)
    removeESP(targetPlayer)
end)

for _, targetPlayer in pairs(S.Players:GetPlayers()) do
    if targetPlayer ~= S.LocalPlayer then
        targetPlayer.CharacterAdded:Connect(function(character)
            task.wait(1)
            if ESP_Players.Enabled then createESP(targetPlayer) end
        end)
    end
end

-- Character Respawn Handler
S.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(1)
    if ESP_Players.Enabled then ESP_Players.Disable(); ESP_Players.Enable() end
    if ESP_Best.Enabled then ESP_Best.Disable(); ESP_Best.Enable() end
    if BaseLine.Enabled then BaseLine.Disable(); BaseLine.Enable() end
    if AntiTurret.Enabled then AntiTurret.Disable(); AntiTurret.Enable() end
    if Aimbot.Enabled then Aimbot.Disable(); Aimbot.Enable() end
    if KickSteal.Enabled then KickSteal.Disable(); KickSteal.Enable() end
    if UnwalkAnim.Enabled then setupNoWalkAnimation(newCharacter) end
    if AntiDebuff.Enabled then AntiDebuff.Disable(); AntiDebuff.Enable() end
    -- Anti Ragdoll handles internal respawn
    if XrayBase.Enabled then XrayBase.Disable(); XrayBase.Enable() end
    if FpsBoost.Enabled then
        for _, p in ipairs(S.Players:GetPlayers()) do if p.Character then optimizeCharacter(p.Character) end end
    end
end)

S.LocalPlayer.CharacterRemoving:Connect(function()
    BaseLine.Stop()
end)

-- Auto Scan Loop for AutoSteal
task.spawn(function()
    while true do
        if AutoSteal.Enabled then scanAllPlots() end
        task.wait(5)
    end
end)

-- ==================== UI INTEGRATION ====================
ArcadeUILib:CreateUI()
ArcadeUILib:Notify("Nightmare Hub (Modular)")

ArcadeUILib:AddToggleRow("Esp Players", ESP_Players.Toggle, "Esp Best", ESP_Best.Toggle)
ArcadeUILib:AddToggleRow("Base Line", BaseLine.Toggle, "Anti Turret", AntiTurret.Toggle)
ArcadeUILib:AddToggleRow("Aimbot", Aimbot.Toggle, "Kick Steal", KickSteal.Toggle)
ArcadeUILib:AddToggleRow("Unwalk Anim", UnwalkAnim.Toggle, "Auto Steal", AutoSteal.Toggle)
ArcadeUILib:AddToggleRow("Anti Debuff", AntiDebuff.Toggle, "Anti Rdoll", ANTI_RAGDOLL.Toggle)
ArcadeUILib:AddToggleRow("Xray Base", XrayBase.Toggle, "Fps Boost", FpsBoost.Toggle)
ArcadeUILib:AddToggleRow("Esp Timer", TimerEsp.Toggle, "", nil)

print("🎮 Arcade UI with Modular Structure Loaded Successfully!")
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Sabstealtoolsv1.lua"))()
