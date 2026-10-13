--[[=====================================================
    MENU HALLOWEEN v10 by Vince (Sidebar & Auto-Dip)
=====================================================]]

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local GameRemotes  = RS:WaitForChild("Remotes"):WaitForChild("Game")
local CollectCandy = GameRemotes:WaitForChild("CollectCandy")

local CANDY_FOLDER = workspace:WaitForChild("HalloweenCandy")
local DROPOFF      = workspace:WaitForChild("CandyDropOff")

-- [ VOLCANO COORDINATES ]
local VOLCANO_COORDS = Vector3.new(-5109.14, 41435.2, -3472.42) 
local FOOD_STALL_COORDS = Vector3.new(125.546, 40322.6, 948.211)

local DepositRemote
for _, r in ipairs(GameRemotes:GetChildren()) do
    if r.Name:lower():find("deposit") then DepositRemote = r break end
end

local env = (getgenv and getgenv()) or _G
if env._menuCleanup then pcall(env._menuCleanup) end
env._menuId = (env._menuId or 0) + 1
local myId = env._menuId
env.auto     = false
env.speed    = 250
env.arc      = 8
env.mode     = "near"
env.moveMode = "fly"
env.autoCave = false
env.autoDip  = false

local function charHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function sendNotification(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 8
        })
    end)
end

-- ===================== EGG PICKUP HOOK =====================
-- Silently listens for the EggPickup remote to trigger Auto Dip
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and tostring(self) == "EggPickup" and env.autoDip then
        task.spawn(function()
            task.wait(0.4) -- Wait for the server to grant the egg
            local hrp = charHRP()
            if hrp then
                -- 1. Teleport to Volcano
                hrp.CFrame = CFrame.new(VOLCANO_COORDS)
                task.wait(0.6) -- Wait for server position sync
                
                -- 2. Fire the dip remote
                local dipRemote = RS:FindFirstChild("packages") 
                    and RS.packages:FindFirstChild("Net") 
                    and RS.packages.Net:FindFirstChild("RE/VolcanoDip")
                
                if dipRemote then 
                    dipRemote:FireServer() 
                    sendNotification("Auto Dip", "Successfully dipped egg in magma!")
                end
            end
        end)
    end
    
    return oldNamecall(self, ...)
end)

-- ===================== GUI =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HalloweenMenu"; screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(400, 360) -- Widened for sidebar
mainFrame.Position = UDim2.new(0, 20, 0, 120)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32); titleLabel.BorderSizePixel = 0
titleLabel.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
titleLabel.Text = "Auto Halloween | by Vince"; titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 15; titleLabel.Parent = mainFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

-- Fix bottom corners for title
local titleBlock = Instance.new("Frame")
titleBlock.Size = UDim2.new(1, 0, 0, 8); titleBlock.Position = UDim2.new(0, 0, 1, -8)
titleBlock.BackgroundColor3 = Color3.fromRGB(255, 130, 0); titleBlock.BorderSizePixel = 0
titleBlock.Parent = titleLabel

-- SIDEBAR
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 110, 1, -32); sidebar.Position = UDim2.new(0, 0, 0, 32)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 38); sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local tabHalloweenBtn = Instance.new("TextButton")
tabHalloweenBtn.Size = UDim2.new(1, 0, 0, 40); tabHalloweenBtn.Position = UDim2.new(0, 0, 0, 10)
tabHalloweenBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75); tabHalloweenBtn.BorderSizePixel = 0
tabHalloweenBtn.Text = "Halloween"; tabHalloweenBtn.TextColor3 = Color3.new(1,1,1)
tabHalloweenBtn.Font = Enum.Font.GothamBold; tabHalloweenBtn.TextSize = 13; tabHalloweenBtn.Parent = sidebar

local tabTeleportBtn = Instance.new("TextButton")
tabTeleportBtn.Size = UDim2.new(1, 0, 0, 40); tabTeleportBtn.Position = UDim2.new(0, 0, 0, 50)
tabTeleportBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38); tabTeleportBtn.BorderSizePixel = 0
tabTeleportBtn.Text = "Teleports"; tabTeleportBtn.TextColor3 = Color3.new(1,1,1)
tabTeleportBtn.Font = Enum.Font.GothamBold; tabTeleportBtn.TextSize = 13; tabTeleportBtn.Parent = sidebar

-- CONTENT AREA
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -110, 1, -32); contentArea.Position = UDim2.new(0, 110, 0, 32)
contentArea.BackgroundTransparency = 1; contentArea.Parent = mainFrame

-- ===================== TAB 1: HALLOWEEN =====================
local halloweenFrame = Instance.new("Frame")
halloweenFrame.Size = UDim2.new(1, 0, 1, 0); halloweenFrame.BackgroundTransparency = 1
halloweenFrame.Parent = contentArea

local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.new(1, -20, 0, 44); autoButton.Position = UDim2.new(0, 10, 0, 10)
autoButton.BorderSizePixel = 0; autoButton.TextColor3 = Color3.new(1,1,1)
autoButton.Font = Enum.Font.GothamBold; autoButton.TextSize = 17
autoButton.Text = "AUTO: OFF"; autoButton.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
autoButton.Parent = halloweenFrame
Instance.new("UICorner", autoButton).CornerRadius = UDim.new(0, 8)

local modeButton = Instance.new("TextButton")
modeButton.Size = UDim2.new(1, -20, 0, 30); modeButton.Position = UDim2.new(0, 10, 0, 60)
modeButton.BorderSizePixel = 0; modeButton.TextColor3 = Color3.new(1,1,1)
modeButton.Font = Enum.Font.GothamBold; modeButton.TextSize = 11
modeButton.Text = "ORDER: NEAREST TO DROPOFF"; modeButton.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
modeButton.Parent = halloweenFrame
Instance.new("UICorner", modeButton).CornerRadius = UDim.new(0, 8)

local moveButton = Instance.new("TextButton")
moveButton.Size = UDim2.new(1, -20, 0, 30); moveButton.Position = UDim2.new(0, 10, 0, 95)
moveButton.BorderSizePixel = 0; moveButton.TextColor3 = Color3.new(1,1,1)
moveButton.Font = Enum.Font.GothamBold; moveButton.TextSize = 11
moveButton.Text = "MOVEMENT: FLY"; moveButton.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
moveButton.Parent = halloweenFrame
Instance.new("UICorner", moveButton).CornerRadius = UDim.new(0, 8)

local caveButton = Instance.new("TextButton")
caveButton.Size = UDim2.new(1, -20, 0, 30); caveButton.Position = UDim2.new(0, 10, 0, 130)
caveButton.BorderSizePixel = 0; caveButton.TextColor3 = Color3.new(1,1,1)
caveButton.Font = Enum.Font.GothamBold; caveButton.TextSize = 11
caveButton.Text = "OPEN CAVE: OFF"; caveButton.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
caveButton.Parent = halloweenFrame
Instance.new("UICorner", caveButton).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 16); speedLabel.Position = UDim2.new(0, 10, 0, 165)
speedLabel.BackgroundTransparency = 1; speedLabel.TextColor3 = Color3.fromRGB(220,220,220)
speedLabel.Font = Enum.Font.Gotham; speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left; speedLabel.Text = "Speed: 250"; speedLabel.Parent = halloweenFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -20, 0, 10); sliderTrack.Position = UDim2.new(0, 10, 0, 185)
sliderTrack.BackgroundColor3 = Color3.fromRGB(55,55,65); sliderTrack.BorderSizePixel = 0; sliderTrack.Parent = halloweenFrame
Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1,0)

local sliderFill = Instance.new("Frame")
sliderFill.BackgroundColor3 = Color3.fromRGB(255,130,0); sliderFill.BorderSizePixel = 0
sliderFill.Size = UDim2.new(0,0,1,0); sliderFill.Parent = sliderTrack
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1,0)

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 18, 0, 18); sliderKnob.AnchorPoint = Vector2.new(0.5,0.5)
sliderKnob.Position = UDim2.new(0,0,0.5,0); sliderKnob.BackgroundColor3 = Color3.new(1,1,1)
sliderKnob.Text = ""; sliderKnob.Parent = sliderTrack
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1,0)

local warnLabel = Instance.new("TextLabel")
warnLabel.Size = UDim2.new(1, -20, 0, 32); warnLabel.Position = UDim2.new(0, 10, 0, 200)
warnLabel.BackgroundTransparency = 1; warnLabel.TextColor3 = Color3.fromRGB(255, 200, 90)
warnLabel.Font = Enum.Font.Gotham; warnLabel.TextSize = 10; warnLabel.TextWrapped = true
warnLabel.TextXAlignment = Enum.TextXAlignment.Left; warnLabel.TextYAlignment = Enum.TextYAlignment.Top
warnLabel.Text = "Warning: you need a fast enough animal equipped to move this fast."; warnLabel.Parent = halloweenFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 78); statusLabel.Position = UDim2.new(0, 10, 0, 240)
statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left; statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Ready."; statusLabel.Parent = halloweenFrame

-- ===================== TAB 2: TELEPORTS =====================
local teleportFrame = Instance.new("Frame")
teleportFrame.Size = UDim2.new(1, 0, 1, 0); teleportFrame.BackgroundTransparency = 1
teleportFrame.Visible = false; teleportFrame.Parent = contentArea

local foodStallBtn = Instance.new("TextButton")
foodStallBtn.Size = UDim2.new(1, -20, 0, 35); foodStallBtn.Position = UDim2.new(0, 10, 0, 10)
foodStallBtn.BorderSizePixel = 0; foodStallBtn.TextColor3 = Color3.new(1,1,1)
foodStallBtn.Font = Enum.Font.GothamBold; foodStallBtn.TextSize = 13
foodStallBtn.Text = "TP: FOOD STALLS"; foodStallBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
foodStallBtn.Parent = teleportFrame
Instance.new("UICorner", foodStallBtn).CornerRadius = UDim.new(0, 8)

local volcanoBtn = Instance.new("TextButton")
volcanoBtn.Size = UDim2.new(1, -20, 0, 35); volcanoBtn.Position = UDim2.new(0, 10, 0, 55)
volcanoBtn.BorderSizePixel = 0; volcanoBtn.TextColor3 = Color3.new(1,1,1)
volcanoBtn.Font = Enum.Font.GothamBold; volcanoBtn.TextSize = 13
volcanoBtn.Text = "TP: VOLCANO"; volcanoBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
volcanoBtn.Parent = teleportFrame
Instance.new("UICorner", volcanoBtn).CornerRadius = UDim.new(0, 8)

local autoDipBtn = Instance.new("TextButton")
autoDipBtn.Size = UDim2.new(1, -20, 0, 44); autoDipBtn.Position = UDim2.new(0, 10, 0, 120)
autoDipBtn.BorderSizePixel = 0; autoDipBtn.TextColor3 = Color3.new(1,1,1)
autoDipBtn.Font = Enum.Font.GothamBold; autoDipBtn.TextSize = 16
autoDipBtn.Text = "AUTO DIP: OFF"; autoDipBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
autoDipBtn.Parent = teleportFrame
Instance.new("UICorner", autoDipBtn).CornerRadius = UDim.new(0, 8)

-- Tab Switching Logic
tabHalloweenBtn.MouseButton1Click:Connect(function()
    halloweenFrame.Visible = true; teleportFrame.Visible = false
    tabHalloweenBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    tabTeleportBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
end)

tabTeleportBtn.MouseButton1Click:Connect(function()
    halloweenFrame.Visible = false; teleportFrame.Visible = true
    tabTeleportBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    tabHalloweenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
end)

-- Teleport Button Logic
foodStallBtn.MouseButton1Click:Connect(function()
    local hrp = charHRP()
    if hrp then hrp.CFrame = CFrame.new(FOOD_STALL_COORDS) end
end)

volcanoBtn.MouseButton1Click:Connect(function()
    local hrp = charHRP()
    if hrp then hrp.CFrame = CFrame.new(VOLCANO_COORDS) end
end)

autoDipBtn.MouseButton1Click:Connect(function()
    env.autoDip = not env.autoDip
    autoDipBtn.Text = "AUTO DIP: " .. (env.autoDip and "ON" or "OFF")
    autoDipBtn.BackgroundColor3 = env.autoDip and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(70, 40, 40)
end)

-- ===================== UI Button Logic =====================
moveButton.MouseButton1Click:Connect(function()
    if env.moveMode == "fly" then
        env.moveMode = "teleport"; moveButton.Text = "MOVEMENT: TELEPORT"
    else
        env.moveMode = "fly"; moveButton.Text = "MOVEMENT: FLY"
    end
end)

caveButton.MouseButton1Click:Connect(function()
    env.autoCave = not env.autoCave
    caveButton.Text = "OPEN CAVE: " .. (env.autoCave and "ON" or "OFF")
    caveButton.BackgroundColor3 = env.autoCave and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(45, 55, 75)
end)

local MIN_SPEED, MAX_SPEED = 133, 700
local isDragging = false
local function updateFromX(x)
    local rel = math.clamp((x - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
    local v = math.floor(MIN_SPEED + (MAX_SPEED - MIN_SPEED) * rel)
    env.speed = v
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
    speedLabel.Text = "Speed: " .. v
end
sliderTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = true; updateFromX(i.Position.X)
    end
end)
UIS.InputChanged:Connect(function(i)
    if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        updateFromX(i.Position.X)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)
task.spawn(function()
    task.wait(0.1)
    local rel = (250 - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    sliderFill.Size = UDim2.new(rel,0,1,0); sliderKnob.Position = UDim2.new(rel,0,0.5,0)
end)

-- ===================== util =====================
local function setCollide(collide)
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if collide then
                p.CanCollide = (p.Name ~= "HumanoidRootPart")
            else
                p.CanCollide = false
            end
        end
    end
end

local function setFlying(state)
    local char = plr.Character
    local hrp = charHRP()
    if hrp then hrp.Anchored = state end
    setCollide(not state)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if state then
            env._origWalk = hum.WalkSpeed
            hum.WalkSpeed = 0
        else
            hum.WalkSpeed = env._origWalk or 16
        end
    end
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    prompt:InputHoldBegin()
    task.wait(math.max(prompt.HoldDuration, 0.05) + 0.05)
    prompt:InputHoldEnd()
    return true
end

local function triggerPromptsNear(pos, radius)
    local any = false
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local parent = d.Parent
            if parent and parent:IsA("BasePart") and (parent.Position - pos).Magnitude <= radius then
                if triggerPrompt(d) then any = true end
            end
        end
    end
    return any
end

local function flyTo(dest)
    local hrp = charHRP()
    if not hrp then return end
    
    if env.moveMode == "teleport" then
        hrp.Anchored = false 
        hrp.CFrame = CFrame.new(dest)
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(.5) 
        if env.auto and env._menuId == myId then hrp.Anchored = true end
    else
        hrp.Anchored = true
        local start = hrp.Position
        local total = (dest - start).Magnitude
        if total >= 2 then
            local travelled, guard = 0, 0
            while env.auto and env._menuId == myId and guard < 5000 do
                local dt = RunService.Heartbeat:Wait()
                guard += 1
                travelled = math.min(travelled + env.speed * dt, total)
                local prog = travelled / total
                local base = start:Lerp(dest, prog)
                local arc  = math.sin(prog * math.pi) * env.arc
                hrp.CFrame = CFrame.new(base + Vector3.new(0, arc, 0))
                if prog >= 1 then break end
            end
        end
        hrp.CFrame = CFrame.new(dest)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.Anchored = false
        task.wait(0.15)
        if env.auto and env._menuId == myId then hrp.Anchored = true end
        task.wait(0.05)
    end
end

local function candyId(part, idx)
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("ValueBase") then return tostring(c.Value) end
    end
    for _, a in ipairs({"Id","CandyId","Index","Number","ID"}) do
        local v = part:GetAttribute(a); if v then return tostring(v) end
    end
    local n = part.Name:match("(%d+)")
    if n then return "Candy1_" .. tonumber(n) end
    return "Candy1_" .. idx
end

local function candyValue(part)
    for _, a in ipairs({"Value","Worth","Price","CandyValue","Rarity","Points","Amount","Cost","Tier"}) do
        local v = part:GetAttribute(a)
        if type(v) == "number" then return v end
    end
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then return c.Value end
    end
    local n = part.Name:match("(%d+)")
    if n then return tonumber(n) end
    return 0
end

local function dropoffPad()
    return DROPOFF:IsA("BasePart") and DROPOFF or DROPOFF:FindFirstChildWhichIsA("BasePart")
end

local function setAuto(v)
    env.auto = v
    autoButton.Text = "AUTO: " .. (v and "ON" or "OFF")
    autoButton.BackgroundColor3 = v and Color3.fromRGB(0,150,80) or Color3.fromRGB(70,40,40)
    setFlying(v)
    if not v then
        task.spawn(function()
            task.wait(0.4)
            if not env.auto then
                local hrp = charHRP()
                if hrp then hrp.Anchored = false end
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = env._origWalk or 16 end
            end
        end)
    end
end
autoButton.MouseButton1Click:Connect(function() setAuto(not env.auto) end)

local function refreshModeButton()
    modeButton.Text = (env.mode == "value") and "ORDER: MOST VALUABLE" or "ORDER: NEAREST TO DROPOFF"
end
modeButton.MouseButton1Click:Connect(function()
    env.mode = (env.mode == "value") and "near" or "value"
    refreshModeButton()
end)

plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    if env.auto then setFlying(true) end
end)

-- ===================== ciclo =====================
task.spawn(function()
    while env._menuId == myId do
        if env.auto then
            
            if env.autoCave then
                local caveDoor
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and (p.Name:lower():find("cavedoor") or p.Name:lower():find("ritual")) then
                        if p:FindFirstChildWhichIsA("ProximityPrompt", true) then
                            caveDoor = p
   Mode == "teleport" then
        hrp.Anchored = false 
        hrp.CFrame = CFrame.new(dest)
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(.5) 
        if env.auto and env._menuId == myId then hrp.Anchored = true end
    else
        hrp.Anchored = true
        local start = hrp.Position
        local total = (dest - start).Magnitude
        if total >= 2 then
            local travelled, guard = 0, 0
            while env.auto and env._menuId == myId and guard < 5000 do
                local dt = RunService.Heartbeat:Wait()
                guard += 1
                travelled = math.min(travelled + env.speed * dt, total)
                local prog = travelled / total
                local base = start:Lerp(dest, prog)
                local arc  = math.sin(prog * math.pi) * env.arc
                hrp.CFrame = CFrame.new(base + Vector3.new(0, arc, 0))
                if prog >= 1 then break end
            end
        end
        hrp.CFrame = CFrame.new(dest)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.Anchored = false
        task.wait(0.15)
        if env.auto and env._menuId == myId then hrp.Anchored = true end
        task.wait(0.05)
    end
end

local function candyId(part, idx)
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("ValueBase") then return tostring(c.Value) end
    end
    for _, a in ipairs({"Id","CandyId","Index","Number","ID"}) do
        local v = part:GetAttribute(a); if v then return tostring(v) end
    end
    local n = part.Name:match("(%d+)")
    if n then return "Candy1_" .. tonumber(n) end
    return "Candy1_" .. idx
end

local function candyValue(part)
    for _, a in ipairs({"Value","Worth","Price","CandyValue","Rarity","Points","Amount","Cost","Tier"}) do
        local v = part:GetAttribute(a)
        if type(v) == "number" then return v end
    end
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then return c.Value end
    end
    local n = part.Name:match("(%d+)")
    if n then return tonumber(n) end
    return 0
end

local function dropoffPad()
    return DROPOFF:IsA("BasePart") and DROPOFF or DROPOFF:FindFirstChildWhichIsA("BasePart")
end

local function setAuto(v)
    env.auto = v
    autoButton.Text = "AUTO: " .. (v and "ON" or "OFF")
    autoButton.BackgroundColor3 = v and Color3.fromRGB(0,150,80) or Color3.fromRGB(70,40,40)
    setFlying(v)
    if not v then
        task.spawn(function()
            task.wait(0.4)
            if not env.auto then
                local hrp = charHRP()
                if hrp then hrp.Anchored = false end
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = env._origWalk or 16 end
            end
        end)
    end
end
autoButton.MouseButton1Click:Connect(function() setAuto(not env.auto) end)

local function refreshModeButton()
    modeButton.Text = (env.mode == "value") and "ORDER: MOST VALUABLE" or "ORDER: NEAREST TO DROPOFF"
end
modeButton.MouseButton1Click:Connect(function()
    env.mode = (env.mode == "value") and "near" or "value"
    refreshModeButton()
end)

plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    if env.auto then setFlying(true) end
end)

-- ===================== ciclo =====================
task.spawn(function()
    while env._menuId == myId do
        if env.auto then
            
            if env.autoCave then
                local caveDoor
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and (p.Name:lower():find("cavedoor") or p.Name:lower():find("ritual")) then
                        if p:FindFirstChildWhichIsA("ProximityPrompt", true) then
                            caveDoor = p
                            break
                        end
                    end
                end

                if caveDoor then
                    statusLabel.Text = "→ checking secret cave"
                    flyTo(caveDoor.Position)
                    task.wait(0.2)
                    triggerPromptsNear(caveDoor.Position, 12)
                    task.wait(0.3)
                end
            end
            
            local candies = {}
            for _, p in ipairs(CANDY_FOLDER:GetChildren()) do
                if p:IsA("BasePart") then candies[#candies+1] = p end
            end
            
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and (p.Name == "Yin" or p.Name == "Yang") then
                    candies[#candies+1] = p
                end
            end

            if #candies == 0 then
                statusLabel.Text = "No candy, waiting..."
                task.wait(0.5)
            else
                if env.mode == "value" then
                    table.sort(candies, function(a, b)
                        local function getVal(part)
                            if part.Name == "Yin" or part.Name == "Yang" then return 9999999 end
                            return candyValue(part)
                        end
                        return getVal(a) > getVal(b)
                    end)
                else
                    local pad = dropoffPad()
                    if pad then
                        table.sort(candies, function(a, b)
                            return (a.Position - pad.Position).Magnitude
                                 < (b.Position - pad.Position).Magnitude
                        end)
                    end
                end

                for i, part in ipairs(candies) do
                    if not env.auto or env._menuId ~= myId then break end

                    local id = part.Name == "Yin" and "Yin" or part.Name == "Yang" and "Yang" or candyId(part, i)                    

                    statusLabel.Text = "→ flying to " .. id
                    flyTo(part.Position)
                    task.wait(0.15)

                    for attempt = 1, 4 do
                        if not env.auto or env._menuId ~= myId then break end

                        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if not triggerPrompt(prompt) then
                            triggerPromptsNear(part.Position, 8)
                        end
                        
                        -- Fire the remote for normal candies
                        if id ~= "Yin" and id ~= "Yang" then
                            CollectCandy:FireServer(id)
                        else
                            -- If it IS a sigil, send a pop-up notification to your screen
                            if attempt == 1 then
                                sendNotification("🔮 Sigil Sniper", "Successfully collected the " .. id .. " sigil!")
                            end
                        end
                        
                        task.wait(0.3)

                        if part.Parent ~= CANDY_FOLDER and part.Parent ~= workspace then break end
                    end

                    if env.auto and id ~= "Yin" and id ~= "Yang" then
                        local pad = dropoffPad()
                        if pad then
                            statusLabel.Text = "→ flying to dropoff"
                            flyTo(pad.Position)
                            task.wait(0.2)
                            triggerPromptsNear(pad.Position, 8)
                            if DepositRemote then DepositRemote:FireServer() end
                            task.wait(0.4)
                        end
                    end
                end
                
                task.wait(0.1)
            end
        else
            statusLabel.Text = "Idle."
            task.wait(0.3)
        end
    end
end)

env._menuCleanup = function()
    setAuto(false)
    env._menuId = env._menuId + 1
    screenGui:Destroy()
end

print("Halloween event | by Vince loaded.")
