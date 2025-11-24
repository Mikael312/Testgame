-- Pet Simulator 99 Exploit Script
-- Generated at discord.gg/25ms

-- Wait for game to load
repeat
    task.wait()
until game:IsLoaded()

-- Print to console that script is starting
print("LKZ HUB: Initializing script...")

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

-- Player variables
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Function to show notification in-game
local function showNotification(title, message, duration)
    duration = duration or 5
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = message,
        Duration = duration
    })
end

-- Get hardware ID for authentication
local hwid = get_hwid and get_hwid() or (gethwid and gethwid() or "UNKNOWN_HWID")

-- Authentication system
local authResponse = HttpService:JSONDecode(request({
    ["Url"] = "https://ver.lucasemanuelguimaraes20.workers.dev/",
    ["Method"] = "POST",
    ["Headers"] = {
        ["Content-Type"] = "application/json"
    },
    ["Body"] = HttpService:JSONEncode({
        ["hwid"] = hwid
    })
}).Body)

-- User permissions
local username, hasKeyless, has10to30, has30plus
if authResponse.exists then
    username = authResponse.nome
    hasKeyless = authResponse.perm.Keyless or false
    has10to30 = authResponse.perm["10-30"] or false
    has30plus = authResponse.perm["30+"]
    if not has30plus then
        has30plus = false
    end
    print("LKZ HUB: Authentication successful for user: " .. username)
else
    hasKeyless = false
    has10to30 = false
    has30plus = false
    username = "Unknown"
    print("LKZ HUB: Authentication failed")
end

-- Load key system if user doesn't have keyless access
if not hasKeyless then
    print("LKZ HUB: Loading key system...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LucasggkX/Key/refs/heads/main/KeySystem.lua"))()
end

-- Hide private server message
workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible = false

-- Global variables for script features
_G.activeGuis = {
    ["control"] = false
}
_G.Joiner = {
    ["State"] = false,
    ["Min"] = 10000000,
    ["Max"] = 29999999,
    ["Exec"] = false,
    ["gotoBest"] = false
}
_G.superJump = false
_G.additionalSpeed = false
_G.ativo = false
_G.FloatV1 = false
_G.FloatV2 = false
_G.bestESP = false
_G.upstairs = false
_G.SemiInv = false
_G.PlayerESP = false
_G.BaseESP = false
_G.Fly = false
_G.AntiRag = false
_G.FpsDev = false
_G.KillGui = false
_G.KickOnSteal = false
_G.LaserCape = false
_G.Delivery = false
_G.DestroySentry = false
_G.FlySpeed = 140
_G.LaserRange = 50
_G.PermUsar = true
_G.AutoCollect = false
_G.DelayCollect = 30
_G.AutobuyMin = 0
_G.AutobuyEnable = false
_G.PlayerESPColor = Color3.fromRGB(0, 255, 0)

-- Arrays for storing objects
local collectedItems = {}
local playerESPObjects = {}
local baseESPObjects = {}

-- Function to buy items from shop
function buy(itemName)
    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/CoinsShopService/RequestBuy"):InvokeServer(itemName)
end

-- Function to find and go to the best area
function gotoBest()
    local humanoid = nil
    local humanoidRootPart = nil
    local backpack = nil
    
    -- Function to equip grappling hook
    local function equipGrapplingHook()
        humanoid:UnequipTools()
        task.wait(0.1)
        local grapplingHook = backpack:FindFirstChild("Grapple Hook")
        if not grapplingHook then
            return false
        end
        humanoid:EquipTool(grapplingHook)
        task.wait(0.3)
        return true
    end
    
    -- Function to find the best area
    local function findBestArea()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then
            return nil, nil
        end
        
        local bestValue = 0
        local bestPosition = nil
        
        for _, plot in ipairs(plots:GetChildren()) do
            -- Check if plot belongs to the player
            local isPlayerPlot = false
            for _, descendant in ipairs(plot:GetDescendants()) do
                if descendant:IsA("TextLabel") and type(descendant.Text) == "string" and descendant.Text:find(LocalPlayer.DisplayName) then
                    isPlayerPlot = true
                    break
                end
            end
            
            -- Skip if it's the player's plot
            if not isPlayerPlot then
                -- Check animal podiums
                local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    for _, podium in ipairs(animalPodiums:GetChildren()) do
                        local attachment = podium:FindFirstChild("Base") and 
                                         podium.Base:FindFirstChild("Spawn") and 
                                         podium.Base.Spawn:FindFirstChild("Attachment")
                        
                        if attachment then
                            local animalOverhead = attachment:FindFirstChild("AnimalOverhead")
                            if animalOverhead then
                                local generationLabel = nil
                                local stolenLabel = nil
                                
                                for _, child in ipairs(animalOverhead:GetDescendants()) do
                                    if child:IsA("TextLabel") then
                                        if child.Name == "Generation" then
                                            generationLabel = child
                                        end
                                        if child.Name == "Stolen" then
                                            stolenLabel = child
                                        end
                                    end
                                end
                                
                                -- Check if animal is stolen and has generation value
                                if generationLabel and stolenLabel and 
                                   (stolenLabel.Text == "STOLEN" or stolenLabel.Text == "IN FUSE") and 
                                   generationLabel.Text and generationLabel.Text:find("/s") then
                                    
                                    -- Parse generation value
                                    local valueStr, suffix = generationLabel.Text:gsub(",", ""):match("([%d%.]+)([kKmMbB]?)")
                                    local value = tonumber(valueStr) or 0
                                    
                                    -- Convert suffix to multiplier
                                    if suffix then
                                        local suffixLower = suffix:lower()
                                        if suffixLower == "k" then
                                            value = value * 1000
                                        elseif suffixLower == "m" then
                                            value = value * 1000000
                                        elseif suffixLower == "b" then
                                            value = value * 1000000000
                                        end
                                    end
                                    
                                    -- Find the model parent
                                    local model = generationLabel.Parent
                                    while model and not model:IsA("Model") do
                                        model = model.Parent
                                    end
                                    
                                    -- Update best position if this is better
                                    if model and bestValue < value then
                                        local basePart = model:FindFirstChildWhichIsA("BasePart", true)
                                        if basePart then
                                            bestPosition = basePart
                                            bestValue = value
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Check for animals in the plot
                for _, child in ipairs(plot:GetChildren()) do
                    if child:IsA("Model") then
                        for _, descendant in ipairs(child:GetDescendants()) do
                            if descendant.Name == "AnimalOverhead" then
                                local generationLabel = nil
                                local stolenLabel = nil
                                
                                for _, labelChild in ipairs(descendant:GetDescendants()) do
                                    if labelChild:IsA("TextLabel") then
                                        if labelChild.Name == "Generation" then
                                            generationLabel = labelChild
                                        end
                                        if labelChild.Name == "Stolen" then
                                            stolenLabel = labelChild
                                        end
                                    end
                                end
                                
                                -- Check if animal is stolen and has generation value
                                if generationLabel and stolenLabel and 
                                   (stolenLabel.Text == "STOLEN" or stolenLabel.Text == "IN FUSE") and 
                                   generationLabel.Text and generationLabel.Text:find("/s") then
                                    
                                    -- Parse generation value
                                    local valueStr, suffix = generationLabel.Text:gsub(",", ""):match("([%d%.]+)([kKmMbB]?)")
                                    local value = tonumber(valueStr) or 0
                                    
                                    -- Convert suffix to multiplier
                                    if suffix then
                                        local suffixLower = suffix:lower()
                                        if suffixLower == "k" then
                                            value = value * 1000
                                        elseif suffixLower == "m" then
                                            value = value * 1000000
                                        elseif suffixLower == "b" then
                                            value = value * 1000000000
                                        end
                                    end
                                    
                                    -- Find the model parent
                                    local model = generationLabel.Parent
                                    while model and not model:IsA("Model") do
                                        model = model.Parent
                                    end
                                    
                                    -- Update best position if this is better
                                    if model and bestValue < value then
                                        local basePart = model:FindFirstChildWhichIsA("BasePart", true)
                                        if basePart then
                                            bestPosition = basePart
                                            bestValue = value
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.01)
        end
        
        if bestPosition then
            return bestPosition.Position, bestPosition
        else
            return nil, nil
        end
    end
    
    -- Function to use quantum cloner
    local function useQuantumCloner()
        pcall(function()
            setfflag("WorldStepMax", "-99999999999999")
        end)
        
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local quantumCloner = backpack:FindFirstChild("Quantum Cloner") or character:FindFirstChild("Quantum Cloner")
        
        if quantumCloner then
            if character:FindFirstChild(quantumCloner.Name) ~= quantumCloner then
                humanoid:EquipTool(quantumCloner)
            end
            
            local packages = ReplicatedStorage:WaitForChild("Packages", 5)
            if packages then
                packages = packages:FindFirstChild("Net")
            end
            
            if packages then
                local useItemEvent = packages:FindFirstChild("RE/UseItem")
                local teleportEvent = packages:FindFirstChild("RE/QuantumCloner/OnTeleport")
                
                if useItemEvent and teleportEvent then
                    useItemEvent:FireServer()
                    teleportEvent:FireServer()
                end
                
                task.spawn(function()
                    task.wait(3.5)
                    pcall(function()
                        setfflag("WorldStepMax", "0")
                    end)
                end)
            end
        else
            return
        end
    end
    
    -- Function to start grappling
    local function startGrappling()
        local isDone = false
        
        -- Keep grappling hook equipped
        task.spawn(function()
            while not isDone do
                local character = LocalPlayer.Character
                if character and humanoidRootPart and humanoid then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    local grapplingHook = backpack and (not character:FindFirstChild("Grapple Hook") and backpack:FindFirstChild("Grapple Hook"))
                    
                    if grapplingHook then
                        pcall(function()
                            humanoid:EquipTool(grapplingHook)
                        end)
                    end
                end
                task.wait(0.05)
            end
        end)
        
        -- Continuously fire grappling hook
        task.spawn(function()
            while not isDone do
                pcall(function()
                    local packages = ReplicatedStorage:FindFirstChild("Packages")
                    if packages then
                        require(packages:WaitForChild("Net")):RemoteEvent("UseItem"):FireServer(1.9832406361897787)
                    end
                end)
                task.wait(0.05)
            end
        end)
        
        return function()
            isDone = true
        end
    end
    
    -- Main teleport function
    local function teleportToBest()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        task.wait(0.35)
        
        humanoid = character:WaitForChild("Humanoid")
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        backpack = LocalPlayer:WaitForChild("Backpack")
        
        if not equipGrapplingHook() then
            return false
        end
        
        local bestPos, bestObj = findBestArea()
        if not (bestPos and bestObj) then
            return false
        end
        
        -- Find closest X coordinate
        local xPositions = {-465, -353}
        local closestX = xPositions[1]
        local speed = 165
        
        for i = 1, #xPositions do
            if math.abs(bestObj.Position.X - xPositions[i]) < math.abs(bestObj.Position.X - closestX) then
                closestX = xPositions[i]
            end
        end
        
        local targetY = bestObj.Position.Y
        local targetPos = Vector3.new(closestX, targetY, bestPos.Z)
        
        local stopGrappling = startGrappling()
        task.wait(0.15)
        
        -- Move up if too low
        if humanoidRootPart.Position.Y < 10 then
            while humanoidRootPart.Position.Y < 10 do
                humanoidRootPart.Velocity = Vector3.new(0, speed, 0)
                task.wait(0.03)
            end
        end
        
        -- Move to target position
        while (humanoidRootPart.Position - targetPos).Magnitude > 2 do
            humanoidRootPart.Velocity = (targetPos - humanoidRootPart.Position).Unit * speed
            task.wait(0.03)
        end
        
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        
        -- Move to best object
        local startTime = tick()
        while tick() - startTime < 0.2 do
            humanoidRootPart.Velocity = (bestObj.Position - humanoidRootPart.Position).Unit * speed
            task.wait(0.03)
        end
        
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        
        pcall(function()
            humanoid:MoveTo(bestObj.Position)
        end)
        
        task.wait(0.4)
        stopGrappling()
        humanoid:UnequipTools()
        task.wait(0.2)
        
        pcall(function()
            useQuantumCloner()
        end)
        
        task.wait(0.4)
        pcall(function()
            humanoid:MoveTo(bestObj.Position)
        end)
        
        return true
    end
    
    -- Alternative teleport function for flying carpet/broom users
    local function teleportWithFlyTool()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local tasks = {}
        local isDone = false
        
        -- Function to equip grappling hook
        local function equipGrapplingHook()
            humanoid:UnequipTools()
            task.wait(0.1)
            local grapplingHook = backpack:FindFirstChild("Grapple Hook")
            if not grapplingHook then
                return false
            end
            humanoid:EquipTool(grapplingHook)
            task.wait(0.3)
            return true
        end
        
        -- Function to start grappling
        local function startGrappling()
            local equipTask = task.spawn(function()
                while not isDone do
                    local character = LocalPlayer.Character
                    if character and humanoidRootPart and humanoid then
                        local backpack = LocalPlayer:FindFirstChild("Backpack")
                        local grapplingHook = backpack and (not character:FindFirstChild("Grapple Hook") and backpack:FindFirstChild("Grapple Hook"))
                        
                        if grapplingHook then
                            pcall(function()
                                humanoid:EquipTool(grapplingHook)
                            end)
                        end
                    end
                    task.wait(0.05)
                end
            end)
            
            local fireTask = task.spawn(function()
                while not isDone do
                    pcall(function()
                        local packages = ReplicatedStorage:FindFirstChild("Packages")
                        if packages then
                            require(packages:WaitForChild("Net")):RemoteEvent("UseItem"):FireServer(1.9832406361897787)
                        end
                    end)
                    task.wait(0.05)
                end
            end)
            
            table.insert(tasks, equipTask)
            table.insert(tasks, fireTask)
        end
        
        -- Function to stop grappling
        local function stopGrappling()
            isDone = true
            for _, taskId in ipairs(tasks) do
                pcall(function()
                    task.cancel(taskId)
                end)
            end
            tasks = {}
        end
        
        -- Function to use quantum cloner
        local function useQuantumCloner()
            pcall(function()
                setfflag("WorldStepMax", "-99999999999999")
            end)
            
            local backpack = LocalPlayer:WaitForChild("Backpack")
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local quantumCloner = backpack:FindFirstChild("Quantum Cloner") or character:FindFirstChild("Quantum Cloner")
            
            if quantumCloner then
                if character:FindFirstChild(quantumCloner.Name) ~= quantumCloner then
                    humanoid:EquipTool(quantumCloner)
                end
                
                local packages = ReplicatedStorage:WaitForChild("Packages", 5)
                if packages then
                    packages = packages:FindFirstChild("Net")
                end
                
                if packages then
                    local useItemEvent = packages:FindFirstChild("RE/UseItem")
                    local teleportEvent = packages:FindFirstChild("RE/QuantumCloner/OnTeleport")
                    
                    if useItemEvent and teleportEvent then
                        useItemEvent:FireServer()
                        teleportEvent:FireServer()
                    end
                    
                    task.spawn(function()
                        task.wait(3.5)
                        pcall(function()
                            setfflag("WorldStepMax", "0")
                        end)
                    end)
                end
            else
                return
            end
        end
        
        -- Find best area
        local bestPos, bestObj = (function()
            local plots = workspace:FindFirstChild("Plots")
            if not plots then
                return nil
            end
            
            local bestValue = 0
            local bestPosition = nil
            
            for _, plot in ipairs(plots:GetChildren()) do
                -- Check if plot belongs to the player
                local isPlayerPlot = false
                for _, descendant in ipairs(plot:GetDescendants()) do
                    if descendant:IsA("TextLabel") and type(descendant.Text) == "string" and descendant.Text:find(LocalPlayer.DisplayName) then
                        isPlayerPlot = true
                        break
                    end
                end
                
                -- Skip if it's the player's plot
                if not isPlayerPlot then
                    -- Check animal podiums
                    local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                    if animalPodiums then
                        for _, podium in ipairs(animalPodiums:GetChildren()) do
                            local attachment = podium:FindFirstChild("Base") and 
                                             podium.Base:FindFirstChild("Spawn") and 
                                             podium.Base.Spawn:FindFirstChild("Attachment")
                            
                            if attachment then
                                local animalOverhead = attachment:FindFirstChild("AnimalOverhead")
                                if animalOverhead then
                                    local generationLabel = nil
                                    local stolenLabel = nil
                                    
                                    for _, child in ipairs(animalOverhead:GetDescendants()) do
                                        if child:IsA("TextLabel") then
                                            if child.Name == "Generation" then
                                                generationLabel = child
                                            end
                                            if child.Name == "Stolen" then
                                                stolenLabel = child
                                            end
                                        end
                                    end
                                    
                                    -- Check if animal is stolen and has generation value
                                    if generationLabel and stolenLabel and 
                                       (stolenLabel.Text == "STOLEN" or stolenLabel.Text == "IN FUSE") and 
                                       generationLabel.Text and generationLabel.Text:find("/s") then
                                        
                                        -- Parse generation value
                                        local valueStr, suffix = generationLabel.Text:gsub(",", ""):match("([%d%.]+)([kKmMbB]?)")
                                        local value = tonumber(valueStr) or 0
                                        
                                        -- Convert suffix to multiplier
                                        if suffix then
                                            local suffixLower = suffix:lower()
                                            if suffixLower == "k" then
                                                value = value * 1000
                                            elseif suffixLower == "m" then
                                                value = value * 1000000
                                            elseif suffixLower == "b" then
                                                value = value * 1000000000
                                            end
                                        end
                                        
                                        -- Find the model parent
                                        local model = generationLabel.Parent
                                        while model and not model:IsA("Model") do
                                            model = model.Parent
                                        end
                                        
                                        -- Update best position if this is better
                                        if model and bestValue < value then
                                            local basePart = model:FindFirstChildWhichIsA("BasePart", true)
                                            if basePart then
                                                bestPosition = basePart
                                                bestValue = value
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Check for animals in the plot
                    for _, child in ipairs(plot:GetChildren()) do
                        if child:IsA("Model") then
                            for _, descendant in ipairs(child:GetDescendants()) do
                                if descendant.Name == "AnimalOverhead" then
                                    local generationLabel = nil
                                    local stolenLabel = nil
                                    
                                    for _, labelChild in ipairs(descendant:GetDescendants()) do
                                        if labelChild:IsA("TextLabel") then
                                            if labelChild.Name == "Generation" then
                                                generationLabel = labelChild
                                            end
                                            if labelChild.Name == "Stolen" then
                                                stolenLabel = labelChild
                                            end
                                        end
                                    end
                                    
                                    -- Check if animal is stolen and has generation value
                                    if generationLabel and stolenLabel and 
                                       (stolenLabel.Text == "STOLEN" or stolenLabel.Text == "IN FUSE") and 
                                       generationLabel.Text and generationLabel.Text:find("/s") then
                                        
                                        -- Parse generation value
                                        local valueStr, suffix = generationLabel.Text:gsub(",", ""):match("([%d%.]+)([kKmMbB]?)")
                                        local value = tonumber(valueStr) or 0
                                        
                                        -- Convert suffix to multiplier
                                        if suffix then
                                            local suffixLower = suffix:lower()
                                            if suffixLower == "k" then
                                                value = value * 1000
                                            elseif suffixLower == "m" then
                                                value = value * 1000000
                                            elseif suffixLower == "b" then
                                                value = value * 1000000000
                                            end
                                        end
                                        
                                        -- Find the model parent
                                        local model = generationLabel.Parent
                                        while model and not model:IsA("Model") do
                                            model = model.Parent
                                        end
                                        
                                        -- Update best position if this is better
                                        if model and bestValue < value then
                                            local basePart = model:FindFirstChildWhichIsA("BasePart", true)
                                            if basePart then
                                                bestPosition = basePart
                                                bestValue = value
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if bestPosition then
                return bestPosition.Position, bestPosition
            else
                return nil, nil
            end
        end)()
        
        if not (bestPos and bestObj) then
            return false
        end
        
        if not equipGrapplingHook() then
            return false
        end
        
        startGrappling()
        
        -- Move up
        local targetY = bestObj.Position.Y + 15
        local speed = 80
        
        while math.abs(humanoidRootPart.Position.Y - targetY) > 2 do
            local yDiff = targetY - humanoidRootPart.Position.Y
            local yVel = math.clamp(yDiff * 6, -speed, speed)
            humanoidRootPart.Velocity = Vector3.new(0, yVel, 0)
            task.wait(0.03)
        end
        
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        stopGrappling()
        humanoid:UnequipTools()
        
        -- Equip flying tool
        local flyingTool = backpack:FindFirstChild("Flying Carpet") or backpack:FindFirstChild("Witch's Broom")
        if flyingTool then
            humanoid:EquipTool(flyingTool)
        end
        
        task.wait(0.01)
        
        -- Find closest X coordinate
        local xPositions = {-343, -476}
        local closestX = xPositions[1]
        
        for i = 1, #xPositions do
            if math.abs(bestObj.Position.X - xPositions[i]) < math.abs(bestObj.Position.X - closestX) then
                closestX = xPositions[i]
            end
        end
        
        -- Teleport to position
        humanoidRootPart.CFrame = CFrame.new(closestX, bestObj.Position.Y + 15, bestObj.Position.Z)
        task.wait(0.2)
        
        humanoid:MoveTo(bestObj.Position)
        humanoid:UnequipTools()
        task.wait(0.5)
        
        pcall(function()
            useQuantumCloner()
        end)
        
        task.wait(0.4)
        pcall(function()
            humanoid:MoveTo(bestObj.Position)
        end)
        
        return true
    end
    
    -- Check if player has flying tool
    local hasFlyingTool = (function()
        local character = game:GetService("Players").LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()
        local backpack = game:GetService("Players").LocalPlayer:WaitForChild("Backpack")
        return character:FindFirstChild("Flying Carpet") or backpack:FindFirstChild("Flying Carpet") or 
               (character:FindFirstChild("Witch's Broom") or backpack:FindFirstChild("Witch's Broom"))
    end)()
    
    -- Use appropriate teleport method
    if hasFlyingTool then
        return teleportWithFlyTool()
    else
        return teleportToBest()
    end
end

-- Setup GUI function
function _G.setupGuis()
    -- Variables for GUI setup
    local isTouchDevice = UserInputService.TouchEnabled
    local isKeybindMode = false
    local currentKeybindButton = nil
    local keybinds = {}
    local keybindFunctions = {}
    local mainGui = nil
    
    -- Configuration system
    local ConfigManager = {
        ["ConfigPath"] = "LKZ_Config_V2.json",
        ["Configs"] = {},
        ["LoadConfig"] = function(self)
            if readfile then
                local success, configData = pcall(function()
                    return readfile(self.ConfigPath)
                end)
                
                if success and configData and configData ~= "" then
                    local success, parsedData = pcall(function()
                        return HttpService:JSONDecode(configData)
                    end)
                    
                    if success then
                        self.Configs = parsedData
                        return self.Configs
                    end
                end
            end
            
            self.Configs = {}
            return self.Configs
        end,
        ["SaveConfig"] = function(self)
            if writefile then
                pcall(function()
                    writefile(self.ConfigPath, HttpService:JSONEncode(self.Configs))
                end)
            end
        end,
        ["ClearConfig"] = function(self)
            self.Configs = {}
            if writefile then
                pcall(function()
                    writefile(self.ConfigPath, "{}")
                end)
            end
        end,
        ["SetValue"] = function(self, category, key, value)
            if not self.Configs[category] then
                self.Configs[category] = {}
            end
            self.Configs[category][key] = value
            self:SaveConfig()
        end,
        ["GetValue"] = function(self, category, key, defaultValue)
            if self.Configs[category] and self.Configs[category][key] ~= nil then
                return self.Configs[category][key]
            else
                return defaultValue
            end
        end
    }
    
    -- Load configuration
    ConfigManager:LoadConfig()
    
    -- Load keybinds from config
    keybinds = ConfigManager:GetValue("Global", "Keybinds", {})
    
    -- Color scheme
    local Colors = {
        ["PRIMARY"] = Color3.fromRGB(70, 130, 255),
        ["SECONDARY"] = Color3.fromRGB(70, 130, 255),
        ["BACKGROUND"] = Color3.fromRGB(20, 20, 30),
        ["FRAME_BG"] = Color3.fromRGB(30, 30, 40),
        ["TEXT"] = Color3.fromRGB(255, 255, 255),
        ["TEXT_DIM"] = Color3.fromRGB(180, 180, 180),
        ["TOGGLE_ON"] = Color3.fromRGB(70, 130, 255),
        ["TOGGLE_OFF"] = Color3.fromRGB(60, 60, 70)
    }
    
    -- Notification system
    local notifications = {}
    
    -- Function to update notification positions
    local function updateNotificationPositions()
        for i, notification in ipairs(notifications) do
            if notification and notification.Parent then
                local position = UDim2.new(1, -330, 1, -20 - i * 90)
                TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    ["Position"] = position
                }):Play()
            end
        end
    end
    
    -- Function to show notification
    local function showNotification(title, message, duration)
        local notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "Notification"
        notificationGui.Parent = PlayerGui
        notificationGui.ResetOnSpawn = false
        notificationGui.DisplayOrder = 999999
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 320, 0, 80)
        frame.Position = UDim2.new(1, 10, 1, -20)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.BorderSizePixel = 0
        frame.Parent = notificationGui
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Thickness = 2
        stroke.Color = Colors.PRIMARY
        
        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.Size = UDim2.new(1, -10, 0, 25)
        titleLabel.Position = UDim2.new(0, 5, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Colors.PRIMARY
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local messageLabel = Instance.new("TextLabel", frame)
        messageLabel.Size = UDim2.new(1, -10, 0, 45)
        messageLabel.Position = UDim2.new(0, 5, 0, 30)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        messageLabel.TextSize = 12
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextWrapped = true
        
        table.insert(notifications, frame)
        updateNotificationPositions()
        
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            ["Position"] = UDim2.new(1, -330, 1, -20 - #notifications * 90)
        }):Play()
        
        task.spawn(function()
            task.wait(duration or 5)
            
            for i, notification in ipairs(notifications) do
                if notification == frame then
                    table.remove(notifications, i)
                    break
                end
            end
            
            local tween = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                ["Position"] = UDim2.new(1, 10, 1, -20)
            })
            tween:Play()
            
            tween.Completed:Connect(function()
                notificationGui:Destroy()
                updateNotificationPositions()
            end)
        end)
    end
    
    -- Handle keybind input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        
        if isKeybindMode and currentKeybindButton and input.KeyCode ~= Enum.KeyCode.Unknown then
            local buttonName = currentKeybindButton.Name
            local keyName = input.KeyCode.Name
            local currentKeybind = keybinds[buttonName]
            
            -- Check if key is already bound to another button
            if keyName ~= "None" then
                for boundButton, boundKey in pairs(keybinds) do
                    if boundKey == keyName and boundButton ~= buttonName then
                        keybinds[boundButton] = "None"
                        if keybindFunctions[boundKey] then
                            keybindFunctions[boundKey] = nil
                        end
                        
                        local keybindButton = mainGui and mainGui:FindFirstChild(boundButton .. "KeybindOuter", true)
                        if keybindButton then
                            local innerButton = keybindButton:FindFirstChild("Inner")
                            if innerButton then
                                local keyLabel = innerButton:FindFirstChild(boundButton)
                                if keyLabel then
                                    keyLabel.Text = "Keybind: -"
                                end
                            end
                        end
                        
                        showNotification("Keybind", "Unbound '" .. keyName .. "' from " .. boundButton, 2)
                        break
                    end
                end
            end
            
            -- Remove existing function for this key
            if currentKeybind and keybindFunctions[currentKeybind] then
                keybindFunctions[currentKeybind] = nil
            end
            
            -- Set new keybind
            if keyName == "None" then
                keybinds[buttonName] = "None"
                currentKeybindButton.Text = "Keybind: -"
            else
                keybinds[buttonName] = keyName
                local buttonFunction = keybindFunctions[buttonName]
                if buttonFunction then
                    keybindFunctions[keyName] = buttonFunction
                end
                currentKeybindButton.Text = "Keybind: " .. keyName
            end
            
            ConfigManager:SetValue("Global", "Keybinds", keybinds)
            isKeybindMode = false
            currentKeybindButton = nil
            showNotification("Keybind", "Key for " .. buttonName .. " set to: " .. keyName, 2)
        elseif not isKeybindMode then
            local keyName = input.KeyCode and input.KeyCode.Name or ""
            if keyName ~= "" and keybindFunctions[keyName] then
                pcall(keybindFunctions[keyName])
            end
        end
    end)
    
    -- Create main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LKZ_HUB_Modern"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    
    if isTouchDevice then
        mainContainer.Size = UDim2.new(0.4, 0, 0.85, 0)
    else
        mainContainer.Size = UDim2.new(0.3, 0, 0.4, 0)
    end
    
    mainContainer.Active = true
    mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    mainContainer.Draggable = true
    mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainContainer.BackgroundColor3 = Colors.BACKGROUND
    mainContainer.BorderSizePixel = 0
    mainContainer.ClipsDescendants = true
    mainContainer.Visible = false
    mainContainer.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainContainer
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.SECONDARY
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = mainContainer
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    })
    gradient.Rotation = 45
    gradient.Parent = mainContainer
    
    -- Toggle button
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 65, 0, 65)
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.Position = UDim2.new(0.5, -275, 0.5, -150)
    toggleButton.Active = true
    toggleButton.Draggable = true
    toggleButton.BorderSizePixel = 0
    toggleButton.Image = "rbxassetid://88557808889639"
    toggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.ScaleType = Enum.ScaleType.Fit
    toggleButton.Parent = screenGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 12)
    toggleCorner.Parent = toggleButton
    
    local isGuiOpen = false
    toggleButton.MouseButton1Click:Connect(function()
        isGuiOpen = not isGuiOpen
        mainContainer.Visible = isGuiOpen
    end)
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Colors.SECONDARY
    header.BorderSizePixel = 0
    header.Parent = mainContainer
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.SECONDARY),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 160, 255))
    })
    headerGradient.Rotation = 90
    headerGradient.Parent = header
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 20)
    headerBottom.Position = UDim2.new(0, 0, 1, -20)
    headerBottom.BackgroundColor3 = Colors.SECONDARY
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = "LKZ HUB"
    titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    
    if isTouchDevice then
        titleLabel.TextSize = 30
    else
        titleLabel.TextSize = 40
    end
    
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    local bestLabel = Instance.new("TextLabel")
    bestLabel.Name = "BestLabel"
    bestLabel.Text = "Best: -"
    bestLabel.Size = UDim2.new(0.48999998, 0, 1, 0)
    bestLabel.Position = UDim2.new(0.5, 0, 0, 0)
    bestLabel.BackgroundTransparency = 1
    bestLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    bestLabel.Font = Enum.Font.Gotham
    bestLabel.TextSize = 22
    bestLabel.TextXAlignment = Enum.TextXAlignment.Right
    bestLabel.TextYAlignment = Enum.TextYAlignment.Center
    bestLabel.Parent = header
    
    -- Tabs frame
    local tabsFrame = Instance.new("ScrollingFrame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, -20, 0, 40)
    tabsFrame.Position = UDim2.new(0, 10, 0, 70)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.ScrollBarThickness = 2
    tabsFrame.ScrollBarImageColor3 = Colors.SECONDARY
    tabsFrame.BorderSizePixel = 0
    tabsFrame.ScrollingDirection = Enum.ScrollingDirection.X
    tabsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabsFrame.Parent = mainContainer
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabsLayout.Padding = UDim.new(0, 5)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = tabsFrame
    
    -- Function to update tabs canvas size
    local function updateTabsCanvasSize()
        local contentSize = tabsLayout.AbsoluteContentSize.X
        local frameSize = tabsFrame.AbsoluteSize.X
        tabsFrame.CanvasSize = UDim2.new(0, math.max(contentSize + 10, math.floor(frameSize)), 0, 0)
    end
    
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabsCanvasSize)
    tabsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTabsCanvasSize)
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -120)
    contentFrame.Position = UDim2.new(0, 10, 0, 120)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainContainer
    
    -- Tab system
    local tabs = {}
    local pages = {}
    local selectedTab = nil
    local tabOrder = 0
    
    -- Function to create a new tab
    local function createTab(tabName, saveConfig)
        tabOrder = tabOrder + 1
        
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Text = tabName
        
        if isTouchDevice then
            tabButton.Size = UDim2.new(0, 90, 0, 32)
        else
            tabButton.Size = UDim2.new(0, 110, 0, 32)
        end
        
        tabButton.BackgroundColor3 = Colors.FRAME_BG
        tabButton.BorderSizePixel = 0
        tabButton.TextColor3 = Colors.TEXT_DIM
        tabButton.Font = Enum.Font.Gotham
        
        if isTouchDevice then
            tabButton.TextSize = 12.5
        else
            tabButton.TextSize = 14
        end
        
        tabButton.LayoutOrder = tabOrder
        tabButton.Parent = tabsFrame
        
        Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)
        
        -- Create page
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Colors.SECONDARY
        page.BorderSizePixel = 0
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Parent = contentFrame
        page.LayoutOrder = tabOrder
        page.ZIndex = 2
        
        local pageLayout = Instance.new("UIListLayout", page)
        pageLayout.FillDirection = Enum.FillDirection.Vertical
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
        end)
        
        table.insert(tabs, tabButton)
        table.insert(pages, page)
        
        -- Tab button click handler
        tabButton.MouseButton1Click:Connect(function()
            -- Hide all pages
            for _, pg in ipairs(pages) do
                pg.Visible = false
            end
            
            -- Reset all tab buttons
            for _, tb in ipairs(tabs) do
                tb.BackgroundColor3 = Colors.FRAME_BG
                tb.TextColor3 = Colors.TEXT_DIM
            end
            
            -- Show selected page and highlight tab button
            page.Visible = true
            tabButton.BackgroundColor3 = Colors.SECONDARY
            tabButton.TextColor3 = Colors.TEXT
            selectedTab = tabButton
        end)
        
        -- Select first tab by default
        if selectedTab == nil then
            tabButton.BackgroundColor3 = Colors.SECONDARY
            tabButton.TextColor3 = Colors.TEXT
            page.Visible = true
            selectedTab = tabButton
        end
        
        -- Set attributes for config saving
        page:SetAttribute("SaveConfigs", saveConfig or false)
        page:SetAttribute("TabName", tabName)
        
        return page
    end
    
    -- Function to create a toggle button
    local function createToggle(parent, label, defaultState, callback)
        local container = Instance.new("Frame")
        container.Name = label .. "Container"
        container.Size = UDim2.new(1, -20, 0, 40)
        container.BackgroundColor3 = Colors.FRAME_BG
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "Label"
        toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        toggleLabel.Position = UDim2.new(0, 15, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Text = label
        toggleLabel.TextColor3 = Colors.TEXT
        toggleLabel.TextSize = 16
        toggleLabel.Font = Enum.Font.Gotham
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = container
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "Toggle"
        toggleButton.Size = UDim2.new(0, 50, 0, 25)
        toggleButton.Position = UDim2.new(1, -65, 0.5, -12.5)
        toggleButton.BackgroundColor3 = defaultState and Colors.TOGGLE_ON or Colors.TOGGLE_OFF
        toggleButton.BorderSizePixel = 0
        toggleButton.Text = ""
        toggleButton.Parent = container
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 12)
        toggleCorner.Parent = toggleButton
        
        local toggleIndicator = Instance.new("Frame")
        toggleIndicator.Name = "Indicator"
        toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
        toggleIndicator.Position = defaultState and UDim2.new(1, -25, 0.5, -10) or UDim2.new(0, 5, 0.5, -10)
        toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleIndicator.BorderSizePixel = 0
        toggleIndicator.Parent = toggleButton
        
        Instance.new("UICorner", toggleIndicator).CornerRadius = UDim.new(0, 10)
        
        -- Animation
        local toggleTween = TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ["BackgroundColor3"] = defaultState and Colors.TOGGLE_ON or Colors.TOGGLE_OFF
        })
        
        local indicatorTween = TweenService:Create(toggleIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ["Position"] = defaultState and UDim2.new(1, -25, 0.5, -10) or UDim2.new(0, 5, 0.5, -10)
        })
        
        -- State
        local state = defaultState
        
        -- Toggle function
        local function toggle()
            state = not state
            toggleTween:Play()
            indicatorTween:Play()
            
            if callback then
                callback(state)
            end
        end
        
        toggleButton.MouseButton1Click:Connect(toggle)
        
        -- Return functions to get/set state
        return {
            ["GetState"] = function()
                return state
            end,
            ["SetState"] = function(newState)
                if state ~= newState then
                    toggle()
                end
            end
        }
    end
    
    -- Function to create a button
    local function createButton(parent, label, callback)
        local button = Instance.new("TextButton")
        button.Name = label .. "Button"
        button.Size = UDim2.new(1, -20, 0, 40)
        button.BackgroundColor3 = Colors.FRAME_BG
        button.BorderSizePixel = 0
        button.Text = label
        button.TextColor3 = Colors.TEXT
        button.TextSize = 16
        button.Font = Enum.Font.Gotham
        button.Parent = parent
        
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
        
        -- Hover effect
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ["BackgroundColor3"] = Colors.SECONDARY
        })
        
        local unhoverTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ["BackgroundColor3"] = Colors.FRAME_BG
        })
        
        button.MouseEnter:Connect(function()
            hoverTween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            unhoverTween:Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)
        
        return button
    end
    
    -- Function to create a slider
    local function createSlider(parent, label, minValue, maxValue, defaultValue, callback)
        local container = Instance.new("Frame")
        container.Name = label .. "Container"
        container.Size = UDim2.new(1, -20, 0, 60)
        container.BackgroundColor3 = Colors.FRAME_BG
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local sliderLabel = Instance.new("TextLabel")
        sliderLabel.Name = "Label"
        sliderLabel.Size = UDim2.new(1, -100, 0, 25)
        sliderLabel.Position = UDim2.new(0, 15, 0, 5)
        sliderLabel.BackgroundTransparency = 1
        sliderLabel.Text = label
        sliderLabel.TextColor3 = Colors.TEXT
        sliderLabel.TextSize = 16
        sliderLabel.Font = Enum.Font.Gotham
        sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        sliderLabel.Parent = container
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0, 80, 0, 25)
        valueLabel.Position = UDim2.new(1, -85, 0, 5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(defaultValue)
        valueLabel.TextColor3 = Colors.TEXT
        valueLabel.TextSize = 16
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = container
        
        local sliderBar = Instance.new("Frame")
        sliderBar.Name = "SliderBar"
        sliderBar.Size = UDim2.new(1, -30, 0, 5)
        sliderBar.Position = UDim2.new(0, 15, 0, 40)
        sliderBar.BackgroundColor3 = Colors.TOGGLE_OFF
        sliderBar.BorderSizePixel = 0
        sliderBar.Parent = container
        
        Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 2.5)
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "SliderFill"
        sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
        sliderFill.Position = UDim2.new(0, 0, 0, 0)
        sliderFill.BackgroundColor3 = Colors.PRIMARY
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBar
        
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 2.5)
        
        local sliderButton = Instance.new("TextButton")
        sliderButton.Name = "SliderButton"
        sliderButton.Size = UDim2.new(0, 15, 0, 15)
        sliderButton.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), -7.5, 0.5, -7.5)
        sliderButton.BackgroundColor3 = Colors.TEXT
        sliderButton.BorderSizePixel = 0
        sliderButton.Text = ""
        sliderButton.Parent = sliderBar
        
        Instance.new("UICorner", sliderButton).CornerRadius = UDim.new(0, 7.5)
        
        -- State
        local value = defaultValue
        local isDragging = false
        
        -- Update slider based on mouse position
        local function updateSlider(input)
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(minValue + (maxValue - minValue) * relativeX)
            
            if value ~= newValue then
                value = newValue
                valueLabel.Text = tostring(value)
                
                local fillRatio = (value - minValue) / (maxValue - minValue)
                sliderFill:TweenSize(UDim2.new(fillRatio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
                sliderButton:TweenPosition(UDim2.new(fillRatio, -7.5, 0.5, -7.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
                
                if callback then
                    callback(value)
                end
            end
        end
        
        -- Input handling
        sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
        
        -- Click on slider bar
        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                updateSlider(input)
            end
        end)
        
        -- Return functions to get/set value
        return {
            ["GetValue"] = function()
                return value
            end,
            ["SetValue"] = function(newValue)
                newValue = math.clamp(newValue, minValue, maxValue)
                if value ~= newValue then
                    value = newValue
                    valueLabel.Text = tostring(value)
                    
                    local fillRatio = (value - minValue) / (maxValue - minValue)
                    sliderFill:TweenSize(UDim2.new(fillRatio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
                    sliderButton:TweenPosition(UDim2.new(fillRatio, -7.5, 0.5, -7.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
                    
                    if callback then
                        callback(value)
                    end
                end
            end
        }
    end
    
    -- Function to create a keybind button
    local function createKeybind(parent, label, defaultKey, callback)
        local container = Instance.new("Frame")
        container.Name = label .. "KeybindOuter"
        container.Size = UDim2.new(1, -20, 0, 40)
        container.BackgroundColor3 = Colors.FRAME_BG
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local keybindLabel = Instance.new("TextLabel")
        keybindLabel.Name = "Label"
        keybindLabel.Size = UDim2.new(0.7, 0, 1, 0)
        keybindLabel.Position = UDim2.new(0, 15, 0, 0)
        keybindLabel.BackgroundTransparency = 1
        keybindLabel.Text = label
        keybindLabel.TextColor3 = Colors.TEXT
        keybindLabel.TextSize = 16
        keybindLabel.Font = Enum.Font.Gotham
        keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
        keybindLabel.Parent = container
        
        local keybindButton = Instance.new("TextButton")
        keybindButton.Name = label
        keybindButton.Size = UDim2.new(0, 120, 0, 25)
        keybindButton.Position = UDim2.new(1, -135, 0.5, -12.5)
        keybindButton.BackgroundColor3 = Colors.TOGGLE_OFF
        keybindButton.BorderSizePixel = 0
        keybindButton.Text = "Keybind: " .. (defaultKey or "-")
        keybindButton.TextColor3 = Colors.TEXT
        keybindButton.TextSize = 14
        keybindButton.Font = Enum.Font.Gotham
        keybindButton.Parent = container
        
        Instance.new("UICorner", keybindButton).CornerRadius = UDim.new(0, 6)
        
        -- State
        local key = defaultKey or "None"
        
        -- Click handler
        keybindButton.MouseButton1Click:Connect(function()
            isKeybindMode = true
            currentKeybindButton = keybindButton
            keybindButton.Text = "Press a key..."
            keybindButton.BackgroundColor3 = Colors.PRIMARY
        end)
        
        -- Register keybind function
        if key ~= "None" then
            keybindFunctions[key] = callback
        end
        keybindFunctions[label] = callback
        
        -- Return functions to get/set key
        return {
            ["GetKey"] = function()
                return key
            end,
            ["SetKey"] = function(newKey)
                key = newKey or "None"
                keybindButton.Text = "Keybind: " .. (key == "None" and "-" or key)
                
                -- Update keybind functions
                for k, v in pairs(keybindFunctions) do
                    if v == callback then
                        keybindFunctions[k] = nil
                    end
                end
                
                if key ~= "None" then
                    keybindFunctions[key] = callback
                end
            end
        }
    end
    
    -- Function to create a text box
    local function createTextBox(parent, label, placeholderText, defaultText, callback)
        local container = Instance.new("Frame")
        container.Name = label .. "Container"
        container.Size = UDim2.new(1, -20, 0, 60)
        container.BackgroundColor3 = Colors.FRAME_BG
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local textBoxLabel = Instance.new("TextLabel")
        textBoxLabel.Name = "Label"
        textBoxLabel.Size = UDim2.new(1, -20, 0, 25)
        textBoxLabel.Position = UDim2.new(0, 10, 0, 5)
        textBoxLabel.BackgroundTransparency = 1
        textBoxLabel.Text = label
        textBoxLabel.TextColor3 = Colors.TEXT
        textBoxLabel.TextSize = 16
        textBoxLabel.Font = Enum.Font.Gotham
        textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
        textBoxLabel.Parent = container
        
        local textBox = Instance.new("TextBox")
        textBox.Name = "TextBox"
        textBox.Size = UDim2.new(1, -20, 0, 25)
        textBox.Position = UDim2.new(0, 10, 0, 30)
        textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        textBox.BorderSizePixel = 0
        textBox.Text = defaultText or ""
        textBox.PlaceholderText = placeholderText or ""
        textBox.PlaceholderColor3 = Colors.TEXT_DIM
        textBox.TextColor3 = Colors.TEXT
        textBox.TextSize = 14
        textBox.Font = Enum.Font.Gotham
        textBox.Parent = container
        
        Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)
        
        -- Focus lost handler
        textBox.FocusLost:Connect(function(enterPressed)
            if callback then
                callback(textBox.Text, enterPressed)
            end
        end)
        
        return textBox
    end
    
    -- Function to create a dropdown
    local function createDropdown(parent, label, options, defaultOption, callback)
        local container = Instance.new("Frame")
        container.Name = label .. "Container"
        container.Size = UDim2.new(1, -20, 0, 40)
        container.BackgroundColor3 = Colors.FRAME_BG
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local dropdownLabel = Instance.new("TextLabel")
        dropdownLabel.Name = "Label"
        dropdownLabel.Size = UDim2.new(0.7, 0, 1, 0)
        dropdownLabel.Position = UDim2.new(0, 15, 0, 0)
        dropdownLabel.BackgroundTransparency = 1
        dropdownLabel.Text = label
        dropdownLabel.TextColor3 = Colors.TEXT
        dropdownLabel.TextSize = 16
        dropdownLabel.Font = Enum.Font.Gotham
        dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
        dropdownLabel.Parent = container
        
        local dropdownButton = Instance.new("TextButton")
        dropdownButton.Name = "DropdownButton"
        dropdownButton.Size = UDim2.new(0, 150, 0, 25)
        dropdownButton.Position = UDim2.new(1, -165, 0.5, -12.5)
        dropdownButton.BackgroundColor3 = Colors.TOGGLE_OFF
        dropdownButton.BorderSizePixel = 0
        dropdownButton.Text = defaultOption or options[1] or ""
        dropdownButton.TextColor3 = Colors.TEXT
        dropdownButton.TextSize = 14
        dropdownButton.Font = Enum.Font.Gotham
        dropdownButton.Parent = container
        
        Instance.new("UICorner", dropdownButton).CornerRadius = UDim.new(0, 6)
        
        local dropdownArrow = Instance.new("ImageLabel")
        dropdownArrow.Name = "Arrow"
        dropdownArrow.Size = UDim2.new(0, 15, 0, 10)
        dropdownArrow.Position = UDim2.new(1, -20, 0.5, -5)
        dropdownArrow.BackgroundTransparency = 1
        dropdownArrow.Image = "rbxassetid://6031090990"
        dropdownArrow.ImageColor3 = Colors.TEXT
        dropdownArrow.Parent = dropdownButton
        
        -- Dropdown list
        local dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Name = "DropdownList"
        dropdownList.Size = UDim2.new(0, 150, 0, 0)
        dropdownList.Position = UDim2.new(1, -165, 1, 5)
        dropdownList.BackgroundColor3 = Colors.FRAME_BG
        dropdownList.BorderSizePixel = 0
        dropdownList.ScrollBarThickness = 2
        dropdownList.ScrollBarImageColor3 = Colors.SECONDARY
        dropdownList.Visible = false
        dropdownList.ZIndex = 10
        dropdownList.Parent = container
        
        Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 6)
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = dropdownList
        
        -- State
        local isOpen = false
        local selectedOption = defaultOption or options[1] or ""
        
        -- Create option buttons
        for i, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option" .. i
            optionButton.Size = UDim2.new(1, 0, 0, 25)
            optionButton.BackgroundColor3 = Colors.FRAME_BG
            optionButton.BorderSizePixel = 0
            optionButton.Text = option
            optionButton.TextColor3 = Colors.TEXT
            optionButton.TextSize = 14
            optionButton.Font = Enum.Font.Gotham
            optionButton.LayoutOrder = i
            optionButton.Parent = dropdownList
            
            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundColor3 = Colors.SECONDARY
            end)
            
            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundColor3 = Colors.FRAME_BG
            end)
            
            optionButton.MouseButton1Click:Connect(function()
                selectedOption = option
                dropdownButton.Text = option
                isOpen = false
                dropdownList.Visible = false
                
                if callback then
                    callback(option)
                end
            end)
        end
        
        -- Update list size
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            dropdownList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end)
        
        -- Toggle dropdown
        dropdownButton.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropdownList.Visible = isOpen
            
            if isOpen then
                dropdownList:TweenSize(UDim2.new(0, 150, 0, math.min(#options * 25, 150)), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            else
                dropdownList:TweenSize(UDim2.new(0, 150, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            end
        end)
        
        -- Close dropdown when clicking outside
        UserInputService.InputBegan:Connect(function(input)
            if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                local dropdownPos = dropdownList.AbsolutePosition
                local dropdownSize = dropdownList.AbsoluteSize
                
                if mousePos.X < dropdownPos.X or mousePos.X > dropdownPos.X + dropdownSize.X or
                   mousePos.Y < dropdownPos.Y or mousePos.Y > dropdownPos.Y + dropdownSize.Y then
                    isOpen = false
                    dropdownList.Visible = false
                    dropdownList:TweenSize(UDim2.new(0, 150, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
                end
            end
        end)
        
        -- Return functions to get/set selected option
        return {
            ["GetSelected"] = function()
                return selectedOption
            end,
            ["SetSelected"] = function(option)
                for i, opt in ipairs(options) do
                    if opt == option then
                        selectedOption = option
                        dropdownButton.Text = option
                        
                        if callback then
                            callback(option)
                        end
                        
                        return true
                    end
                end
                return false
            end
        }
    end
    
    -- Set main GUI reference for keybind system
    mainGui = mainContainer
    
    -- Create tabs
    local mainTab = createTab("Main", true)
    local teleportTab = createTab("Teleport", true)
    local visualTab = createTab("Visual", true)
    local miscTab = createTab("Misc", true)
    local settingsTab = createTab("Settings", true)
    
    -- Main tab content
    do
        -- Auto collect toggle
        local autoCollectToggle = createToggle(mainTab, "Auto Collect", _G.AutoCollect, function(state)
            _G.AutoCollect = state
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "AutoCollect", state)
            end
        end)
        
        -- Auto collect delay slider
        local collectDelaySlider = createSlider(mainTab, "Collect Delay", 1, 60, _G.DelayCollect, function(value)
            _G.DelayCollect = value
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "DelayCollect", value)
            end
        end)
        
        -- Auto buy toggle
        local autoBuyToggle = createToggle(mainTab, "Auto Buy", _G.AutobuyEnable, function(state)
            _G.AutobuyEnable = state
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "AutobuyEnable", state)
            end
        end)
        
        -- Auto buy minimum slider
        local autoBuyMinSlider = createSlider(mainTab, "Auto Buy Min", 0, 10000000, _G.AutobuyMin, function(value)
            _G.AutobuyMin = value
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "AutobuyMin", value)
            end
        end)
        
        -- Goto best button
        createButton(mainTab, "Goto Best", function()
            gotoBest()
        end)
        
        -- Joiner toggle
        local joinerToggle = createToggle(mainTab, "Joiner", _G.Joiner.State, function(state)
            _G.Joiner.State = state
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "JoinerState", state)
            end
        end)
        
        -- Joiner min slider
        local joinerMinSlider = createSlider(mainTab, "Joiner Min", 1000000, 100000000, _G.Joiner.Min, function(value)
            _G.Joiner.Min = value
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "JoinerMin", value)
            end
        end)
        
        -- Joiner max slider
        local joinerMaxSlider = createSlider(mainTab, "Joiner Max", 1000000, 100000000, _G.Joiner.Max, function(value)
            _G.Joiner.Max = value
            if mainTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MainTab", "JoinerMax", value)
            end
        end)
        
        -- Load saved settings
        if mainTab:GetAttribute("SaveConfigs") then
            autoCollectToggle.SetState(ConfigManager:GetValue("MainTab", "AutoCollect", _G.AutoCollect))
            collectDelaySlider.SetValue(ConfigManager:GetValue("MainTab", "DelayCollect", _G.DelayCollect))
            autoBuyToggle.SetState(ConfigManager:GetValue("MainTab", "AutobuyEnable", _G.AutobuyEnable))
            autoBuyMinSlider.SetValue(ConfigManager:GetValue("MainTab", "AutobuyMin", _G.AutobuyMin))
            joinerToggle.SetState(ConfigManager:GetValue("MainTab", "JoinerState", _G.Joiner.State))
            joinerMinSlider.SetValue(ConfigManager:GetValue("MainTab", "JoinerMin", _G.Joiner.Min))
            joinerMaxSlider.SetValue(ConfigManager:GetValue("MainTab", "JoinerMax", _G.Joiner.Max))
        end
    end
    
    -- Teleport tab content
    do
        -- Super jump toggle
        local superJumpToggle = createToggle(teleportTab, "Super Jump", _G.superJump, function(state)
            _G.superJump = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "SuperJump", state)
            end
        end)
        
        -- Additional speed toggle
        local additionalSpeedToggle = createToggle(teleportTab, "Additional Speed", _G.additionalSpeed, function(state)
            _G.additionalSpeed = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "AdditionalSpeed", state)
            end
        end)
        
        -- Float V1 toggle
        local floatV1Toggle = createToggle(teleportTab, "Float V1", _G.FloatV1, function(state)
            _G.FloatV1 = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "FloatV1", state)
            end
        end)
        
        -- Float V2 toggle
        local floatV2Toggle = createToggle(teleportTab, "Float V2", _G.FloatV2, function(state)
            _G.FloatV2 = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "FloatV2", state)
            end
        end)
        
        -- Upstairs toggle
        local upstairsToggle = createToggle(teleportTab, "Upstairs", _G.upstairs, function(state)
            _G.upstairs = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "Upstairs", state)
            end
        end)
        
        -- Fly toggle
        local flyToggle = createToggle(teleportTab, "Fly", _G.Fly, function(state)
            _G.Fly = state
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "Fly", state)
            end
        end)
        
        -- Fly speed slider
        local flySpeedSlider = createSlider(teleportTab, "Fly Speed", 50, 300, _G.FlySpeed, function(value)
            _G.FlySpeed = value
            if teleportTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("TeleportTab", "FlySpeed", value)
            end
        end)
        
        -- Load saved settings
        if teleportTab:GetAttribute("SaveConfigs") then
            superJumpToggle.SetState(ConfigManager:GetValue("TeleportTab", "SuperJump", _G.superJump))
            additionalSpeedToggle.SetState(ConfigManager:GetValue("TeleportTab", "AdditionalSpeed", _G.additionalSpeed))
            floatV1Toggle.SetState(ConfigManager:GetValue("TeleportTab", "FloatV1", _G.FloatV1))
            floatV2Toggle.SetState(ConfigManager:GetValue("TeleportTab", "FloatV2", _G.FloatV2))
            upstairsToggle.SetState(ConfigManager:GetValue("TeleportTab", "Upstairs", _G.upstairs))
            flyToggle.SetState(ConfigManager:GetValue("TeleportTab", "Fly", _G.Fly))
            flySpeedSlider.SetValue(ConfigManager:GetValue("TeleportTab", "FlySpeed", _G.FlySpeed))
        end
    end
    
    -- Visual tab content
    do
        -- Best ESP toggle
        local bestESPToggle = createToggle(visualTab, "Best ESP", _G.bestESP, function(state)
            _G.bestESP = state
            if visualTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("VisualTab", "BestESP", state)
            end
        end)
        
        -- Player ESP toggle
        local playerESPToggle = createToggle(visualTab, "Player ESP", _G.PlayerESP, function(state)
            _G.PlayerESP = state
            if visualTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("VisualTab", "PlayerESP", state)
            end
        end)
        
                -- Base ESP toggle
        local baseESPToggle = createToggle(visualTab, "Base ESP", _G.BaseESP, function(state)
            _G.BaseESP = state
            if visualTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("VisualTab", "BaseESP", state)
            end
        end)
        
        -- Load saved settings
        if visualTab:GetAttribute("SaveConfigs") then
            bestESPToggle.SetState(ConfigManager:GetValue("VisualTab", "BestESP", _G.bestESP))
            playerESPToggle.SetState(ConfigManager:GetValue("VisualTab", "PlayerESP", _G.PlayerESP))
            baseESPToggle.SetState(ConfigManager:GetValue("VisualTab", "BaseESP", _G.BaseESP))
        end
    end
    
    -- Misc tab content
    do
        -- Semi invincible toggle
        local semiInvToggle = createToggle(miscTab, "Semi Invincible", _G.SemiInv, function(state)
            _G.SemiInv = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "SemiInv", state)
            end
            
            -- Enable or disable semi invincibility
            if state then
                local connection = nil
                
                local function enableSemiInvincible()
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                    
                    connection = RunService.Heartbeat:Connect(function()
                        if _G.SemiInv and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                            local humanoid = LocalPlayer.Character.Humanoid
                            -- If health drops below 50%, restore it to 80%
                            if humanoid.Health < humanoid.MaxHealth * 0.5 then
                                humanoid.Health = humanoid.MaxHealth * 0.8
                            end
                        end
                    end)
                    
                    showNotification("Semi Invincible", "Enabled - You'll resist most damage!", 3)
                end
                
                local function disableSemiInvincible()
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                    
                    showNotification("Semi Invincible", "Disabled", 3)
                end
                
                enableSemiInvincible()
                
                -- Store the disable function for later use
                _G.disableSemiInv = disableSemiInvincible
            else
                -- Disable semi invincibility
                if _G.disableSemiInv then
                    _G.disableSemiInv()
                    _G.disableSemiInv = nil
                end
            end
        end)
        
        -- Anti ragdoll toggle
        local antiRagToggle = createToggle(miscTab, "Anti Ragdoll", _G.AntiRag, function(state)
            _G.AntiRag = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "AntiRag", state)
            end
            
            -- Enable or disable anti ragdoll
            if state then
                local connection = nil
                
                local function enableAntiRagdoll()
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                    
                    connection = LocalPlayer.CharacterAdded:Connect(function(character)
                        local humanoid = character:WaitForChild("Humanoid")
                        
                        -- Prevent ragdolling
                        humanoid.StateChanged:Connect(function(oldState, newState)
                            if newState == Enum.HumanoidStateType.Ragdoll then
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        end)
                    end)
                    
                    -- Apply to current character if it exists
                    if LocalPlayer.Character then
                        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.StateChanged:Connect(function(oldState, newState)
                                if newState == Enum.HumanoidStateType.Ragdoll then
                                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                end
                            end)
                        end
                    end
                    
                    showNotification("Anti Ragdoll", "Enabled", 3)
                end
                
                local function disableAntiRagdoll()
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                    
                    showNotification("Anti Ragdoll", "Disabled", 3)
                end
                
                enableAntiRagdoll()
                
                -- Store the disable function for later use
                _G.disableAntiRagdoll = disableAntiRagdoll
            else
                -- Disable anti ragdoll
                if _G.disableAntiRagdoll then
                    _G.disableAntiRagdoll()
                    _G.disableAntiRagdoll = nil
                end
            end
        end)
        
        -- FPS Dev toggle
        local fpsDevToggle = createToggle(miscTab, "FPS Dev", _G.FpsDev, function(state)
            _G.FpsDev = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "FpsDev", state)
            end
            
            -- Enable or disable FPS counter
            if state then
                local fpsGui = Instance.new("ScreenGui")
                fpsGui.Name = "FPSCounter"
                fpsGui.Parent = game.CoreGui
                fpsGui.ResetOnSpawn = false
                fpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                
                local fpsLabel = Instance.new("TextLabel")
                fpsLabel.Size = UDim2.new(0, 100, 0, 30)
                fpsLabel.Position = UDim2.new(0, 10, 0, 10)
                fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                fpsLabel.BackgroundTransparency = 0.3
                fpsLabel.BorderSizePixel = 0
                fpsLabel.Text = "FPS: 0"
                fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                fpsLabel.TextSize = 16
                fpsLabel.Font = Enum.Font.SourceSansBold
                fpsLabel.Parent = fpsGui
                
                Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 5)
                
                local lastTime = tick()
                local fps = 0
                
                local connection
                connection = RunService.Heartbeat:Connect(function()
                    local currentTime = tick()
                    local deltaTime = currentTime - lastTime
                    fps = math.floor(1 / deltaTime)
                    lastTime = currentTime
                    
                    fpsLabel.Text = "FPS: " .. fps
                end)
                
                -- Store the GUI and connection for later use
                _G.fpsGui = fpsGui
                _G.fpsConnection = connection
                
                showNotification("FPS Dev", "Enabled", 3)
            else
                -- Disable FPS counter
                if _G.fpsGui then
                    _G.fpsGui:Destroy()
                    _G.fpsGui = nil
                end
                
                if _G.fpsConnection then
                    _G.fpsConnection:Disconnect()
                    _G.fpsConnection = nil
                end
                
                showNotification("FPS Dev", "Disabled", 3)
            end
        end)
        
        -- Kill GUI toggle
        local killGuiToggle = createToggle(miscTab, "Kill GUI", _G.KillGui, function(state)
            _G.KillGui = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "KillGui", state)
            end
            
            if state then
                -- Kill all GUIs except our own
                for _, gui in ipairs(PlayerGui:GetChildren()) do
                    if gui.Name ~= "LKZ_HUB_Modern" and gui.Name ~= "Notification" then
                        gui:Destroy()
                    end
                end
                
                showNotification("Kill GUI", "All GUIs removed!", 3)
            else
                showNotification("Kill GUI", "Disabled", 3)
            end
        end)
        
        -- Kick on steal toggle
        local kickOnStealToggle = createToggle(miscTab, "Kick On Steal", _G.KickOnSteal, function(state)
            _G.KickOnSteal = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "KickOnSteal", state)
            end
            
            if state then
                showNotification("Kick On Steal", "Enabled - You'll be kicked if someone steals from you!", 3)
            else
                showNotification("Kick On Steal", "Disabled", 3)
            end
        end)
        
        -- Laser cape toggle
        local laserCapeToggle = createToggle(miscTab, "Laser Cape", _G.LaserCape, function(state)
            _G.LaserCape = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "LaserCape", state)
            end
            
            if state then
                showNotification("Laser Cape", "Enabled", 3)
            else
                showNotification("Laser Cape", "Disabled", 3)
            end
        end)
        
        -- Laser range slider
        local laserRangeSlider = createSlider(miscTab, "Laser Range", 10, 100, _G.LaserRange, function(value)
            _G.LaserRange = value
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "LaserRange", value)
            end
        end)
        
        -- Delivery toggle
        local deliveryToggle = createToggle(miscTab, "Delivery", _G.Delivery, function(state)
            _G.Delivery = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "Delivery", state)
            end
            
            if state then
                showNotification("Delivery", "Enabled", 3)
            else
                showNotification("Delivery", "Disabled", 3)
            end
        end)
        
        -- Destroy sentry toggle
        local destroySentryToggle = createToggle(miscTab, "Destroy Sentry", _G.DestroySentry, function(state)
            _G.DestroySentry = state
            if miscTab:GetAttribute("SaveConfigs") then
                ConfigManager:SetValue("MiscTab", "DestroySentry", state)
            end
            
            if state then
                showNotification("Destroy Sentry", "Enabled", 3)
            else
                showNotification("Destroy Sentry", "Disabled", 3)
            end
        end)
        
        -- Load saved settings
        if miscTab:GetAttribute("SaveConfigs") then
            semiInvToggle.SetState(ConfigManager:GetValue("MiscTab", "SemiInv", _G.SemiInv))
            antiRagToggle.SetState(ConfigManager:GetValue("MiscTab", "AntiRag", _G.AntiRag))
            fpsDevToggle.SetState(ConfigManager:GetValue("MiscTab", "FpsDev", _G.FpsDev))
            killGuiToggle.SetState(ConfigManager:GetValue("MiscTab", "KillGui", _G.KillGui))
            kickOnStealToggle.SetState(ConfigManager:GetValue("MiscTab", "KickOnSteal", _G.KickOnSteal))
            laserCapeToggle.SetState(ConfigManager:GetValue("MiscTab", "LaserCape", _G.LaserCape))
            laserRangeSlider.SetValue(ConfigManager:GetValue("MiscTab", "LaserRange", _G.LaserRange))
            deliveryToggle.SetState(ConfigManager:GetValue("MiscTab", "Delivery", _G.Delivery))
            destroySentryToggle.SetState(ConfigManager:GetValue("MiscTab", "DestroySentry", _G.DestroySentry))
        end
    end
    
    -- Settings tab content
    do
        -- Clear config button
        createButton(settingsTab, "Clear Config", function()
            ConfigManager:ClearConfig()
            showNotification("Settings", "Configuration cleared successfully!", 3)
        end)
        
        -- Save config button
        createButton(settingsTab, "Save Config", function()
            ConfigManager:SaveConfig()
            showNotification("Settings", "Configuration saved successfully!", 3)
        end)
        
        -- Destroy GUI button
        createButton(settingsTab, "Destroy GUI", function()
            screenGui:Destroy()
            _G.activeGuis.control = false
            
            -- Clean up any running connections
            if _G.disableSemiInv then
                _G.disableSemiInv()
                _G.disableSemiInv = nil
            end
            
            if _G.disableAntiRagdoll then
                _G.disableAntiRagdoll()
                _G.disableAntiRagdoll = nil
            end
            
            if _G.fpsGui then
                _G.fpsGui:Destroy()
                _G.fpsGui = nil
            end
            
            if _G.fpsConnection then
                _G.fpsConnection:Disconnect()
                _G.fpsConnection = nil
            end
            
            showNotification("Settings", "GUI destroyed successfully!", 3)
        end)
        
        -- Rejoin button
        createButton(settingsTab, "Rejoin", function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
    
    -- Store reference to GUI
    _G.activeGuis.control = screenGui
    
    -- Show notification that GUI is ready
    showNotification("LKZ HUB", "Script loaded successfully! Click the button in the corner to open the GUI.", 5)
end

-- Setup the GUI
_G.setupGuis()

-- Print to console that script has finished loading
print("LKZ HUB: Script loaded successfully!")        
