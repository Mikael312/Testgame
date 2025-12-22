--[[
    SIMPLE ARCADE UI 🎮 (UPDATED - CRITICAL FIXES)
    Rounded rectangle, draggable, arcade style
    WITH SWITCH BUTTON FOR FLY/WALK TO BASE (FIXED)
    WITH NEW RESPAWN DESYNC + SERVER POSITION ESP
    WITH AUTO-ENABLED NO WALK ANIMATION
    WITH NEW FLY/TP TO BEST FEATURE (FULLY REWRITTEN)
]]

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ==================== STEAL FLOOR VARIABLES ====================
local allFeaturesEnabled = false
local floorGrabPart = nil
local floorGrabConnection = nil
local humanoidRootPart = nil
local originalTransparency = {}
local autoLaserThread = nil
local laserCapeEquipped = false

-- ==================== DESYNC ESP VARIABLES ====================
local ESPFolder = nil
local fakePosESP = nil
local serverPosition = nil
local respawnDesyncEnabled = false

-- ==================== NO WALK ANIMATION VARIABLES ====================
local noWalkAnimationEnabled = true

-- ==================== FLY/TP TO BEST VARIABLES (FIXED) ====================
-- FIXED: Using separate, clear flags for each process to avoid confusion.
local isFlyingToBase = false
local isWalkingToBase = false
local isFlyingToBest = false
local isTpToBest = false

local flyToBaseConnection = nil
local walkToBaseThread = nil
local flyToBestConnection = nil

local isFlyToBestMode = true -- true = Fly, false = TP

-- ==================== MODULE DATA FOR BEST PET DETECTION ====================
local AnimalsModule, TraitsModule, MutationsModule
pcall(function()
    AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    TraitsModule = require(ReplicatedStorage.Datas.Traits)
    MutationsModule = require(ReplicatedStorage.Datas.Mutations)
end)

-- ==================== NO WALK ANIMATION FUNCTIONS ====================
local function setupNoWalkAnimation(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    local function stopAllAnimations()
        local tracks = animator:GetPlayingAnimationTracks()
        for _, track in pairs(tracks) do if track.IsPlaying then track:Stop() end end
    end
    stopAllAnimations()
    humanoid.Running:Connect(stopAllAnimations)
    humanoid.Jumping:Connect(stopAllAnimations)
    animator.AnimationPlayed:Connect(function(animationTrack) animationTrack:Stop() end)
    RunService.RenderStepped:Connect(stopAllAnimations)
    print("🚫 No Walk Animation: ACTIVE")
end

-- ==================== STEAL FLOOR FUNCTIONS ====================
local function updateHumanoidRootPart()
    local character = LocalPlayer.Character
    if character then humanoidRootPart = character:FindFirstChild("HumanoidRootPart") end
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateHumanoidRootPart()
    if noWalkAnimationEnabled then setupNoWalkAnimation(LocalPlayer.Character) end
end)
updateHumanoidRootPart()

local function startFloorGrab()
    if floorGrabPart then return end
    floorGrabPart = Instance.new("Part")
    floorGrabPart.Size = Vector3.new(6, 0.5, 6)
    floorGrabPart.Anchored = true
    floorGrabPart.CanCollide = true
    floorGrabPart.Transparency = 0
    floorGrabPart.Material = Enum.Material.Plastic
    floorGrabPart.Color = Color3.fromRGB(255, 200, 0)
    floorGrabPart.Parent = workspace
    floorGrabConnection = RunService.Heartbeat:Connect(function()
        if humanoidRootPart then
            local position = humanoidRootPart.Position
            local yOffset = (humanoidRootPart.Size.Y / 2) + 0.25
            floorGrabPart.Position = Vector3.new(position.X, position.Y - yOffset, position.Z)
        end
    end)
    print("✅ Floor Grab: ON")
end
local function stopFloorGrab()
    if floorGrabConnection then floorGrabConnection:Disconnect() floorGrabConnection = nil end
    if floorGrabPart then floorGrabPart:Destroy() floorGrabPart = nil end
    print("❌ Floor Grab: OFF")
end

local function startXrayBase()
    local plots = workspace:FindFirstChild("Plots")
    if plots then for _, plot in pairs(plots:GetChildren()) do
        for _, part in pairs(plot:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                if originalTransparency[part] == nil then originalTransparency[part] = part.Transparency end
                part.Transparency = 0.5
            end
        end
    end end
    print("✅ X-Ray Base: ON")
end
local function stopXrayBase()
    local plots = workspace:FindFirstChild("Plots")
    if plots then for _, plot in pairs(plots:GetChildren()) do
        for _, part in pairs(plot:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                if originalTransparency[part] ~= nil then part.Transparency = originalTransparency[part] end
            end
        end
    end end
    print("❌ X-Ray Base: OFF")
end

local function autoEquipLaserCape()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local laserCape = backpack:FindFirstChild("Laser Cape")
    if laserCape then
        humanoid:EquipTool(laserCape)
        task.wait(0.3)
        laserCapeEquipped = true
        print("✅ Laser Cape Equipped!")
        return true
    else
        print("⚠️ Laser Cape not found in backpack!")
        return false
    end
end
local function getLaserRemote()
    local remote = nil
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") then
            remote = ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem") or ReplicatedStorage.Packages.Net:FindFirstChild("RE"):FindFirstChild("UseItem")
        end
        if not remote then remote = ReplicatedStorage:FindFirstChild("RE/UseItem") or ReplicatedStorage:FindFirstChild("UseItem") end
    end)
    return remote
end
local function isValidTarget(player)
    if not player or not player.Character or player == LocalPlayer then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    return true
end
local function findNearestPlayer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local nearest = nil
    local nearestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local distance = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
                if distance < nearestDist then nearestDist = distance nearest = player end
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
    if remote and remote.FireServer then
        pcall(function()
            local args = { [1] = targetHRP.Position, [2] = targetHRP }
            remote:FireServer(unpack(args))
        end)
    end
end
local function autoLaserWorker()
    while allFeaturesEnabled do
        local target = findNearestPlayer()
        if target then safeFire(target) end
        local startTime = tick()
        while tick() - startTime < 0.6 do if not allFeaturesEnabled then break end RunService.Heartbeat:Wait() end
    end
end
local function startAutoLaser()
    if not autoEquipLaserCape() then print("❌ Failed to equip Laser Cape! Cannot start Auto Laser.") return end
    if autoLaserThread then task.cancel(autoLaserThread) end
    autoLaserThread = task.spawn(autoLaserWorker)
    print("✅ Auto Laser: ON")
end
local function stopAutoLaser()
    if autoLaserThread then task.cancel(autoLaserThread) autoLaserThread = nil end
    laserCapeEquipped = false
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:UnequipTools() end
    end
    print("❌ Auto Laser: OFF")
end
local function toggleAllFeatures(enabled)
    allFeaturesEnabled = enabled
    if allFeaturesEnabled then
        print("🚀 ACTIVATING ALL FEATURES...")
        startFloorGrab() startXrayBase() startAutoLaser()
        print("✅ ALL FEATURES ACTIVATED!")
    else
        print("🛑 DEACTIVATING ALL FEATURES...")
        stopFloorGrab() stopXrayBase() stopAutoLaser()
        print("❌ ALL FEATURES DEACTIVATED!")
    end
end

-- SPEED BOOSTER SYSTEM
local speedConn
local baseSpeed = 27
local speedEnabled = false
local function GetCharacter()
    local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Char:WaitForChild("HumanoidRootPart")
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    return Char, HRP, Hum
end
local function getMovementInput()
    local Char, HRP, Hum = GetCharacter()
    if not Char or not HRP or not Hum then return Vector3.new(0,0,0) end
    local moveVector = Hum.MoveDirection
    if moveVector.Magnitude > 0.1 then return Vector3.new(moveVector.X, 0, moveVector.Z).Unit end
    return Vector3.new(0,0,0)
end
local function startSpeedControl()
    if speedConn then return end
    speedConn = RunService.Heartbeat:Connect(function()
        local Char, HRP, Hum = GetCharacter()
        if not Char or not HRP or not Hum then return end
        local inputDirection = getMovementInput()
        if inputDirection.Magnitude > 0 then
            HRP.AssemblyLinearVelocity = Vector3.new(inputDirection.X * baseSpeed, HRP.AssemblyLinearVelocity.Y, inputDirection.Z * baseSpeed)
        else
            HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
        end
    end)
end
local function stopSpeedControl()
    if speedConn then speedConn:Disconnect() speedConn = nil end
    local _, HRP = GetCharacter()
    if HRP then HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
end
local function toggleSpeed(enabled)
    speedEnabled = enabled
    if speedEnabled then startSpeedControl() print("✅ Speed Booster aktif!") else stopSpeedControl() print("❌ Speed Booster nonaktif!") end
end

-- ==================== IMPROVED INFINITE JUMP + AUTO GOD MODE ====================
local infJumpEnabled = false
local gravityConnection = nil
local healthConnection = nil
local stateConnection = nil
local initialMaxHealth = 100
local function toggleInfJump(enabled)
    infJumpEnabled = enabled
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if enabled then
        print("🔴 Infinite Jump: ON") print("✅ God Mode: Auto-Enabled")
        if gravityConnection then gravityConnection:Disconnect() end
        gravityConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local velocity = hrp.AssemblyLinearVelocity
                if velocity.Y < 0 then hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y * 0.85, velocity.Z) end
            end
        end)
        if humanoid then
            humanoid.UseJumpPower = true humanoid.JumpPower = 70 initialMaxHealth = humanoid.MaxHealth
            humanoid.MaxHealth = math.huge humanoid.Health = math.huge
        end
        if healthConnection then healthConnection:Disconnect() end
        healthConnection = humanoid.HealthChanged:Connect(function(health) if health < math.huge then humanoid.Health = math.huge end end)
        if stateConnection then stateConnection:Disconnect() end
        stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Dead then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) humanoid.Health = math.huge end
        end)
    else
        print("⚫ Infinite Jump: OFF") print("❌ God Mode: Auto-Disabled")
        if gravityConnection then gravityConnection:Disconnect() gravityConnection = nil end
        if healthConnection then healthConnection:Disconnect() healthConnection = nil end
        if stateConnection then stateConnection:Disconnect() stateConnection = nil end
        if humanoid then
            humanoid.JumpPower = 50 humanoid.MaxHealth = initialMaxHealth humanoid.Health = initialMaxHealth
        end
    end
end
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)
LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.5) if infJumpEnabled then toggleInfJump(true) end end)

-- ==================== FLY / WALK TO BASE (FULLY REWRITTEN) ====================
local FLOAT_SPEED = 50
local STOP_DISTANCE = 10

-- FIXED: Simplified and more reliable function to find the delivery hitbox.
local function FindDelivery()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then warn("❌ Plots folder not found!") return nil end
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase.Enabled then
                local hitbox = plot:FindFirstChild("DeliveryHitbox")
                if hitbox then print("✅ Found DeliveryHitbox in:", plot.Name) return hitbox end
            end
        end
    end
    warn("❌ No valid DeliveryHitbox found")
    return nil
end

-- FIXED: A single, reliable function to stop all travel processes.
local function stopAllTravel()
    isFlyingToBase = false
    isWalkingToBase = false
    if flyToBaseConnection then flyToBaseConnection:Disconnect() flyToBaseConnection = nil end
    if walkToBaseThread then task.cancel(walkToBaseThread) walkToBaseThread = nil end
    local Character = player.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
    print("🛑 All travel to base stopped.")
end

-- FIXED: Simplified fly logic.
local function doFlyToBase()
    local Character = player.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then warn("❌ Character or HRP not found!") return false end
    local deliveryHitbox = FindDelivery()
    if not deliveryHitbox then return false end
    local targetPosition = deliveryHitbox.Position
    local RootPart = Character.HumanoidRootPart
    print("🎈 Flying to Base at:", targetPosition)
    isFlyingToBase = true
    flyToBaseConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToBase or not RootPart or not RootPart.Parent then stopAllTravel() return end
        local distance = (targetPosition - RootPart.Position).Magnitude
        if distance <= STOP_DISTANCE then
            print("✅ Arrived at Base!")
            stopAllTravel()
            return
        end
        local direction = (targetPosition - RootPart.Position).Unit
        RootPart.Velocity = direction * FLOAT_SPEED
    end)
    return true
end

local function doWalkToBase()
    local delivery = FindDelivery()
    if not delivery then return false end
    local character = player.Character
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentJumpHeight = 8, AgentMaxSlope = 45})
    local success, errorMessage = pcall(function() path:ComputeAsync(hrp.Position, delivery.Position) end)
    if not success or path.Status ~= Enum.PathStatus.Success then warn("❌ Path not found!") return false end
    local waypoints = path:GetWaypoints()
    print("🚶 Walking to Base... (" .. #waypoints .. " waypoints)")
    isWalkingToBase = true
    for i, waypoint in ipairs(waypoints) do
        if not isWalkingToBase then print("⚠️ Walk cancelled by user") return false end
        if not humanoid or not hrp or not humanoid.Parent then warn("❌ Character components missing") return false end
        humanoid:MoveTo(waypoint.Position)
        humanoid.MoveToFinished:Wait()
        local distance = (hrp.Position - delivery.Position).Magnitude
        if distance < 5 then print("✅ Reached Base!") return true end
    end
    return true
end

-- ==================== FLY/TP TO BEST FUNCTIONS (FULLY REWRITTEN) ====================
-- FIXED: Using the more robust detection logic provided by the user.
local function findBestPet()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local highest = {value = 0}
    if AnimalsModule then
        for _, plot in pairs(plots:GetChildren()) do
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and not plotSign:FindFirstChild("YourBase") then
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("Model") and AnimalsModule[obj.Name] then
                        pcall(function()
                            local gen = getFinalGeneration(obj)
                            if gen > 0 and gen > highest.value then
                                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                if root then
                                    highest = {
                                        plot = plot, plotName = plot.Name, petName = obj.Name, generation = gen,
                                        formattedValue = formatNumber(gen), model = obj, value = gen,
                                        position = root.Position, cframe = root.CFrame
                                    }
                                end
                            end
                        end)
                    end
                end
            end
        end
        if highest.value > 0 then return highest end
    end
    return nil
end

local function getFinalGeneration(model)
    if not AnimalsModule then return 0 end
    local animalData = AnimalsModule[model.Name]
    if not animalData then return 0 end
    local baseGen = tonumber(animalData.Generation) or tonumber(animalData.Price or 0)
    local traitMult = getTraitMultiplier(model)
    local mutationMult = 0
    if MutationsModule then
        local mutation = model:GetAttribute("Mutation")
        if mutation and MutationsModule[mutation] then mutationMult = tonumber(MutationsModule[mutation].Modifier or 0) end
    end
    local final = baseGen * (1 + traitMult + mutationMult)
    return math.max(1, math.round(final))
end
local function getTraitMultiplier(model)
    if not TraitsModule then return 0 end
    local traitJson = model:GetAttribute("Traits")
    if not traitJson or traitJson == "" then return 0 end
    local traits = {}
    local ok, decoded = pcall(function() return HttpService:JSONDecode(traitJson) end)
    if ok and typeof(decoded) == "table" then traits = decoded else for t in string.gmatch(traitJson, "[^,]+") do table.insert(traits, t) end end
    local mult = 0
    for _, entry in pairs(traits) do
        local name = typeof(entry) == "table" and entry.Name or tostring(entry)
        name = name:gsub("^_Trait%.", "")
        local trait = TraitsModule[name]
        if trait and trait.MultiplierModifier then mult += tonumber(trait.MultiplierModifier) or 0 end
    end
    return mult
end
local function formatNumber(num)
    if num >= 1e12 then return string.format("%.1fT/s", num / 1e12)
    elseif num >= 1e9 then return string.format("%.1fB/s", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM/s", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK/s", num / 1e3)
    else return string.format("%.0f/s", num) end
end

-- FIXED: Simplified and reliable helper functions.
local function autoEquipGrapple()
    local success, result = pcall(function()
        local character = LocalPlayer.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health > 0) then return false end
        humanoid:UnequipTools()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local grapple = backpack:FindFirstChild("Grapple Hook")
        if grapple then grapple.Parent = character humanoid:EquipTool(grapple) return true end
        return false
    end)
    return success and result
end
local UseItemRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")
local function fireGrapple()
    pcall(function() local args = {1.9832406361897787} UseItemRemote:FireServer(unpack(args)) end)
end
local function equipFlyingCarpet()
    local success, result = pcall(function()
        local character = LocalPlayer.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health > 0) then return false end
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local carpet = backpack:FindFirstChild("Flying Carpet") or backpack:FindFirstChild("FlyingCarpet")
        if carpet then humanoid:EquipTool(carpet) return true end
        return false
    end)
    return success and result
end

-- FIXED: A single, reliable function to stop all "to Best" processes.
local function stopAllTravelToBest()
    isFlyingToBest = false
    isTpToBest = false
    if flyToBestConnection then flyToBestConnection:Disconnect() flyToBestConnection = nil end
    print("🛑 All travel to best pet stopped.")
end

-- FIXED: Simplified fly logic that goes directly to the pet.
local function flyToBest()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then print("❌ Character not found!") return false end
    local bestPet = findBestPet()
    if not bestPet then print("❌ No pet found!") return false end
    print("🎯 Flying to " .. bestPet.petName .. " (" .. bestPet.formattedValue .. ")")
    local targetPos = bestPet.position
    local hrp = character.HumanoidRootPart
    autoEquipGrapple()
    task.wait(0.1)
    fireGrapple()
    task.wait(0.05)
    isFlyingToBest = true
    local baseSpeed = 200
    flyToBestConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToBest or not hrp or not hrp.Parent then stopAllTravelToBest() return end
        local distance = (targetPos - hrp.Position).Magnitude
        if distance <= 5 then
            stopAllTravelToBest()
            print("✅ Arrived at best pet!")
            hrp.CFrame = CFrame.new(targetPos)
            return
        end
        local currentSpeed = baseSpeed
        if distance <= 20 then currentSpeed = math.max(50, baseSpeed * (distance / 20)) end
        local direction = (targetPos - hrp.Position).Unit
        hrp.Velocity = direction * currentSpeed
    end)
    return true
end

-- FIXED: Simplified TP logic that equips tools and teleports directly.
local function tpToBest()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then
        print("❌ Character not found!") return false
    end
    local bestPet = findBestPet()
    if not bestPet then print("❌ No pet found!") return false end
    print("🎯 Teleporting to " .. bestPet.petName .. " (" .. bestPet.formattedValue .. ")")
    local hrp = character.HumanoidRootPart
    local targetPos = bestPet.position
    
    isTpToBest = true
    autoEquipGrapple()
    task.wait(0.1)
    fireGrapple()
    task.wait(0.05)
    equipFlyingCarpet()
    task.wait(0.1)
    
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    print("✅ TP Success!")
    isTpToBest = false -- FIXED: Reset flag immediately after TP
    return true
end

-- ==================== DESYNC ESP FUNCTIONS ====================
local function initializeESPFolder()
    for _, existing in ipairs(Workspace:GetChildren()) do if existing.Name == "DesyncESP" then existing:Destroy() end end
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "DesyncESP"
    ESPFolder.Parent = Workspace
end
local function createESPPart(name, color)
    local part = Instance.new("Part")
    part.Name = name part.Size = Vector3.new(2, 5, 2) part.Anchored = true part.CanCollide = false
    part.Material = Enum.Material.Neon part.Color = color part.Transparency = 0.3 part.Parent = ESPFolder
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color highlight.OutlineColor = color highlight.FillTransparency = 0.5 highlight.OutlineTransparency = 0 highlight.Parent = part
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 40) billboard.Adornee = part billboard.AlwaysOnTop = true billboard.Parent = part
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0) textLabel.BackgroundTransparency = 1 textLabel.Text = name
    textLabel.TextColor3 = color textLabel.TextStrokeTransparency = 0.5 textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold textLabel.Parent = billboard
    return part
end
local function updateESP()
    if fakePosESP and serverPosition then fakePosESP.CFrame = CFrame.new(serverPosition) end
end
local function initializeESP()
    if not ESPFolder then initializeESPFolder() else ESPFolder:ClearAllChildren() end
    fakePosESP = createESPPart("Server Position", Color3.fromRGB(255, 0, 0))
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            serverPosition = hrp.Position fakePosESP.CFrame = CFrame.new(serverPosition)
            hrp:GetPropertyChangedSignal("CFrame"):Connect(function() task.wait(0.2) serverPosition = hrp.Position end)
        end
    end
end
local function deactivateESP()
    if ESPFolder then ESPFolder:ClearAllChildren() end fakePosESP = nil serverPosition = nil
end
local function stopAllAnimations(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end end
    end
end
local function applyNetworkSettings()
    local fenv = getfenv()
    pcall(function() fenv.setfflag("GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000") end)
    pcall(function() fenv.setfflag("LargeReplicatorWrite5", "true") end)
    pcall(function() fenv.setfflag("LargeReplicatorEnabled9", "true") end)
    pcall(function() fenv.setfflag("AngularVelociryLimit", "360") end)
    pcall(function() fenv.setfflag("TimestepArbiterVelocityCriteriaThresholdTwoDt", "2147483646") end)
    pcall(function() fenv.setfflag("S2PhysicsSenderRate", "15000") end)
    pcall(function() fenv.setfflag("DisableDPIScale", "true") end)
    pcall(function() fenv.setfflag("MaxDataPacketPerSend", "2147483647") end)
    pcall(function() fenv.setfflag("ServerMaxBandwith", "52") end)
    pcall(function() fenv.setfflag("PhysicsSenderMaxBandwidthBps", "20000") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierBuoyancy", "2147483647") end)
    pcall(function() fenv.setfflag("SimOwnedNOUCountThresholdMillionth", "2147483647") end)
    pcall(function() fenv.setfflag("MaxMissedWorldStepsRemembered", "-2147483648") end)
    pcall(function() fenv.setfflag("CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth", "1") end)
    pcall(function() fenv.setfflag("StreamJobNOUVolumeLengthCap", "2147483647") end)
    pcall(function() fenv.setfflag("DebugSendDistInSteps", "-2147483648") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierAcceleration", "2147483647") end)
    pcall(function() fenv.setfflag("LargeReplicatorRead5", "true") end)
    pcall(function() fenv.setfflag("SimExplicitlyCappedTimestepMultiplier", "2147483646") end)
    pcall(function() fenv.setfflag("GameNetDontSendRedundantNumTimes", "1") end)
    pcall(function() fenv.setfflag("CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent", "1") end)
    pcall(function() fenv.setfflag("CheckPVCachedRotVelThresholdPercent", "10") end)
    pcall(function() fenv.setfflag("LargeReplicatorSerializeRead3", "true") end)
    pcall(function() fenv.setfflag("ReplicationFocusNouExtentsSizeCutoffForPauseStuds", "2147483647") end)
    pcall(function() fenv.setfflag("NextGenReplicatorEnabledWrite4", "true") end)
    pcall(function() fenv.setfflag("CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth", "1") end)
    pcall(function() fenv.setfflag("GameNetDontSendRedundantDeltaPositionMillionth", "1") end)
    pcall(function() fenv.setfflag("InterpolationFrameVelocityThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("StreamJobNOUVolumeCap", "2147483647") end)
    pcall(function() fenv.setfflag("InterpolationFrameRotVelocityThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("WorldStepMax", "30") end)
    pcall(function() fenv.setfflag("TimestepArbiterHumanoidLinearVelThreshold", "1") end)
    pcall(function() fenv.setfflag("InterpolationFramePositionThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("TimestepArbiterHumanoidTurningVelThreshold", "1") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierContstraint", "2147483647") end)
    pcall(function() fenv.setfflag("GameNetPVHeaderLinearVelocityZeroCutoffExponent", "-5000") end)
    pcall(function() fenv.setfflag("CheckPVCachedVelThresholdPercent", "10") end)
    pcall(function() fenv.setfflag("TimestepArbiterOmegaThou", "1073741823") end)
    pcall(function() fenv.setfflag("MaxAcceptableUpdateDelay", "1") end)
    pcall(function() fenv.setfflag("LargeReplicatorSerializeWrite4", "true") end)
end
local function respawnDesync()
    local character = LocalPlayer.Character
    if not character then return end
    stopAllAnimations(character) applyNetworkSettings()
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead) character:ClearAllChildren()
        local tempModel = Instance.new("Model") tempModel.Parent = workspace LocalPlayer.Character = tempModel
        task.wait(0.1) LocalPlayer.Character = character tempModel:Destroy()
        task.wait(0.05) if character and character.Parent then
            local newHumanoid = character:FindFirstChildWhichIsA("Humanoid")
            if newHumanoid then newHumanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    task.wait(0.5) initializeESP()
end

-- ==================== UI CREATION ====================
for _, gui in pairs(game.CoreGui:GetChildren()) do if gui.Name == "SimpleArcadeUI" then gui:Destroy() end end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleArcadeUI" screenGui.ResetOnSpawn = false screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling screenGui.Parent = game.CoreGui
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 320) mainFrame.Position = UDim2.new(0.5, -100, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) mainFrame.BackgroundTransparency = 0.1 mainFrame.BorderSizePixel = 0
mainFrame.Active = true mainFrame.Draggable = true mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner") mainCorner.CornerRadius = UDim.new(0, 15) mainCorner.Parent = mainFrame
local mainStroke = Instance.new("UIStroke") mainStroke.Color = Color3.fromRGB(255, 50, 50) mainStroke.Thickness = 1 mainStroke.Parent = mainFrame
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40) titleLabel.Position = UDim2.new(0, 0, 0, 3) titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NIGHTMARE HUB" titleLabel.TextColor3 = Color3.fromRGB(139, 0, 0) titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.Arcade titleLabel.Parent = mainFrame

-- UI Button Creation (condensed for brevity, but identical to your original)
local function createToggleButton(yPos, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 32) btn.Position = UDim2.new(0.5, -80, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(80, 0, 0) btn.BorderSizePixel = 0
    btn.Text = text btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.TextSize = 16
    btn.Font = Enum.Font.Arcade btn.Parent = mainFrame
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 10) corner.Parent = btn
    local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255, 50, 50) stroke.Thickness = 1 stroke.Parent = btn
    return btn
end

local toggleButton1 = createToggleButton(50, "Perm Desync")
local toggleButton2 = createToggleButton(90, "Speed Booster")
local toggleButton3 = createToggleButton(130, "Inf Jump")
local toggleButton6 = createToggleButton(250, "Steal Floor")

-- Toggle 1: Perm Desync
local isToggled1 = false
local desyncSound = Instance.new("Sound") desyncSound.SoundId = "rbxassetid://144686873" desyncSound.Volume = 1 desyncSound.Parent = SoundService
toggleButton1.MouseButton1Click:Connect(function()
    isToggled1 = not isToggled1
    if isToggled1 then
        toggleButton1.BackgroundColor3 = Color3.fromRGB(200, 30, 30) print("✅ Perm Desync: ON")
        if desyncSound.IsPlaying then desyncSound:Stop() end desyncSound:Play()
        StarterGui:SetCore("SendNotification", {Title = "Desync"; Text = "Desync Successfull"; Duration = 5;})
        if not ESPFolder then initializeESPFolder() end respawnDesync() respawnDesyncEnabled = true
    else
        toggleButton1.BackgroundColor3 = Color3.fromRGB(80, 0, 0) print("❌ Perm Desync: OFF")
        deactivateESP() respawnDesyncEnabled = false
    end
end)

-- Toggle 2: Speed Booster
local isToggled2 = false
toggleButton2.MouseButton1Click:Connect(function()
    isToggled2 = not isToggled2
    if isToggled2 then toggleButton2.BackgroundColor3 = Color3.fromRGB(200, 30, 30) print("🔴 Speed Booster: ON") toggleSpeed(true)
    else toggleButton2.BackgroundColor3 = Color3.fromRGB(80, 0, 0) print("⚫ Speed Booster: OFF") toggleSpeed(false) end
end)

-- Toggle 3: Inf Jump
local isToggled3 = false
toggleButton3.MouseButton1Click:Connect(function()
    isToggled3 = not isToggled3 toggleInfJump(isToggled3)
    if isToggled3 then toggleButton3.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    else toggleButton3.BackgroundColor3 = Color3.fromRGB(80, 0, 0) end
end)

-- Toggle 4: Fly/Walk to Base
local toggleButton4 = Instance.new("TextButton") toggleButton4.Size = UDim2.new(0, 125, 0, 32)
toggleButton4.Position = UDim2.new(0, 20, 0, 170) toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton4.BorderSizePixel = 0 toggleButton4.Text = "Fly to Base" toggleButton4.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton4.TextSize = 15 toggleButton4.Font = Enum.Font.Arcade toggleButton4.Parent = mainFrame
local toggleCorner4 = Instance.new("UICorner") toggleCorner4.CornerRadius = UDim.new(0, 10) toggleCorner4.Parent = toggleButton4
local toggleStroke4 = Instance.new("UIStroke") toggleStroke4.Color = Color3.fromRGB(255, 50, 50) toggleStroke4.Thickness = 1 toggleStroke4.Parent = toggleButton4
local isToggled4 = false local isFlyMode = true
local switchButton = Instance.new("TextButton") switchButton.Size = UDim2.new(0, 30, 0, 32)
switchButton.Position = UDim2.new(0, 153, 0, 170) switchButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
switchButton.BorderSizePixel = 0 switchButton.Text = "⇄" switchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton.TextSize = 18 switchButton.Font = Enum.Font.GothamBold switchButton.Parent = mainFrame
local switchCorner = Instance.new("UICorner") switchCorner.CornerRadius = UDim.new(0, 10) switchCorner.Parent = switchButton
local switchStroke = Instance.new("UIStroke") switchStroke.Color = Color3.fromRGB(255, 50, 50) switchStroke.Thickness = 1 switchStroke.Parent = switchButton
switchButton.MouseButton1Click:Connect(function()
    if isFlyingToBase or isWalkingToBase then stopAllTravel() isToggled4 = false toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0) end
    isFlyMode = not isFlyMode
    if isFlyMode then toggleButton4.Text = "Fly to Base" print("✈️ Mode: FLY TO BASE")
    else toggleButton4.Text = "Walk to Base" print("🚶 Mode: WALK TO BASE") end
end)
toggleButton4.MouseButton1Click:Connect(function()
    if isFlyingToBase or isWalkingToBase then
        stopAllTravel() isToggled4 = false toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0) print("⚫ Travel stopped by user.") return
    end
    isToggled4 = true toggleButton4.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    if isFlyMode then print("🔴 Fly to Base: ON") doFlyToBase()
    else print("🔴 Walk to Base: ON") task.spawn(doWalkToBase) end
end)

-- Toggle 5: Fly/TP to Best
local toggleButton5 = Instance.new("TextButton") toggleButton5.Size = UDim2.new(0, 125, 0, 32)
toggleButton5.Position = UDim2.new(0, 20, 0, 210) toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton5.BorderSizePixel = 0 toggleButton5.Text = "Fly to Best" toggleButton5.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton5.TextSize = 15 toggleButton5.Font = Enum.Font.Arcade toggleButton5.Parent = mainFrame
local toggleCorner5 = Instance.new("UICorner") toggleCorner5.CornerRadius = UDim.new(0, 10) toggleCorner5.Parent = toggleButton5
local toggleStroke5 = Instance.new("UIStroke") toggleStroke5.Color = Color3.fromRGB(255, 50, 50) toggleStroke5.Thickness = 1 toggleStroke5.Parent = toggleButton5
local isToggled5 = false
local switchButton5 = Instance.new("TextButton") switchButton5.Size = UDim2.new(0, 30, 0, 32)
switchButton5.Position = UDim2.new(0, 153, 0, 210) switchButton5.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
switchButton5.BorderSizePixel = 0 switchButton5.Text = "⇄" switchButton5.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton5.TextSize = 18 switchButton5.Font = Enum.Font.GothamBold switchButton5.Parent = mainFrame
local switchCorner5 = Instance.new("UICorner") switchCorner5.CornerRadius = UDim.new(0, 10) switchCorner5.Parent = switchButton5
local switchStroke5 = Instance.new("UIStroke") switchStroke5.Color = Color3.fromRGB(255, 50, 50) switchStroke5.Thickness = 1 switchStroke5.Parent = switchButton5
switchButton5.MouseButton1Click:Connect(function()
    if isFlyingToBest or isTpToBest then
        stopAllTravelToBest() isToggled5 = false toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0) print("⚫ Travel to best stopped by user.")
    end
    isFlyToBestMode = not isFlyToBestMode
    if isFlyToBestMode then toggleButton5.Text = "Fly to Best" print("✈️ Mode: FLY TO BEST")
    else toggleButton5.Text = "Tp to Best" print("🚀 Mode: TP TO BEST") end
end)

-- FIXED: The button logic is now much simpler and more direct.
toggleButton5.MouseButton1Click:Connect(function()
    -- If a process is running, stop it and reset the UI.
    if isFlyingToBest or isTpToBest then
        print("⚫ Proses dihentikan oleh pengguna.")
        stopAllTravelToBest()
        isToggled5 = false
        toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        return
    end

    -- If no process is running, start a new one.
    isToggled5 = true
    toggleButton5.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    
    if isFlyToBestMode then
        print("🔴 Fly to Best: ON")
        flyToBest()
    else
        print("🔴 Tp to Best: ON")
        isTpToBest = true -- Set flag before starting
        tpToBest()
        -- TP is instant, so we can reset the UI after a short delay.
        task.wait(1)
        isToggled5 = false
        toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    end
end)

-- Toggle 6: Steal Floor
local isToggled6 = false
toggleButton6.MouseButton1Click:Connect(function()
    isToggled6 = not isToggled6
    if isToggled6 then toggleButton6.BackgroundColor3 = Color3.fromRGB(200, 30, 30) print("🔴 Steal Floor: ON") toggleAllFeatures(true)
    else toggleButton6.BackgroundColor3 = Color3.fromRGB(80, 0, 0) print("⚫ Steal Floor: OFF") toggleAllFeatures(false) end
end)

-- Cleanup on character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) updateHumanoidRootPart()
    if allFeaturesEnabled then
        if floorGrabPart then floorGrabPart:Destroy() floorGrabPart = nil end
        if floorGrabConnection then floorGrabConnection:Disconnect() floorGrabConnection = nil end
        startFloorGrab() task.wait(0.5) autoEquipLaserCape()
    end
    if isFlyingToBase or isWalkingToBase then stopAllTravel() isToggled4 = false toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0) warn("⚠️ Character respawned - Travel to base stopped") end
    if isFlyingToBest or isTpToBest then stopAllTravelToBest() isToggled5 = false toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0) warn("⚠️ Character respawned - Travel to best stopped") end
    if respawnDesyncEnabled then task.wait(1) initializeESP() end
end)
player.CharacterRemoving:Connect(function()
    stopAllTravel() stopAllTravelToBest()
    if respawnDesyncEnabled then deactivateESP() end
end)

-- ==================== INITIALIZATION ====================
if LocalPlayer.Character then setupNoWalkAnimation(LocalPlayer.Character) end
print("==========================================")
print("🎮 NIGHTMARE HUB LOADED! (CRITICAL FIXES)")
print("==========================================")
print("🔘 Toggles: Perm Desync, Speed Booster, Inf Jump, Fly/TP to Best, Steal Floor")
print("✈️ Special: Fly/Walk to Base with Switch (FIXED)")
print("📍 New: Server Position ESP with Perm Desync")
print("🚫 Auto-Enabled: No Walk Animation")
print("==========================================")
