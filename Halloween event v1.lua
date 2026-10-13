--[[=====================================================
    MENU HALLOWEEN v17 by Vince (Dynamic Ranch Finder)
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

-- [ FIXED COORDINATES ]
local VOLCANO_COORDS    = Vector3.new(-5109.14, 41435.2, -3472.42) 
local FOOD_STALL_COORDS = Vector3.new(125.546, 40322.6, 948.211)

local DepositRemote
for _, r in ipairs(GameRemotes:GetChildren()) do
    if r.Name:lower():find("deposit") then DepositRemote = r break end
end

local env = (getgenv and getgenv()) or _G
if env._menuCleanup then pcall(env._menuCleanup) end
env._menuId = (env._menuId or 0) + 1
local myId = env._menuId

-- STATE VARIABLES
env.auto       = false
env.arc        = 8
env.mode       = "near"
env.moveMode   = "fly"
env.autoCave   = false
env.autoDip    = false
env.autoEgg    = false
env.autoBuyEgg = false
env.targetEgg  = nil 

-- SPEED SETTINGS
local speeds = {
    {name = "NORMAL", value = 150},
    {name = "FAST", value = 300},
    {name = "SUPER FAST", value = 600},
    {name = "SPEED OF LIGHT", value = 1000}
}
local currentSpeedIdx = 1
env.speed = speeds[currentSpeedIdx].value

-- UI COLORS (Modern Theme)
local C_BG = Color3.fromRGB(20, 20, 25)
local C_SIDEBAR = Color3.fromRGB(28, 28, 35)
local C_ACCENT = Color3.fromRGB(255, 120, 0)
local C_BTN_OFF = Color3.fromRGB(45, 45, 55)
local C_BTN_ON = C_ACCENT
local C_TEXT = Color3.fromRGB(240, 240, 240)

local function charHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function sendNotification(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 5
        })
    end)
end

-- ===================== DYNAMIC RANCH FINDER =====================
local function getPlayerRanchCoords()
    -- Scans the entire workspace for the Data -> Owner structure
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Data" and obj.Parent then
            local ownerVal = obj:FindFirstChild("Owner")
            if ownerVal and tostring(ownerVal.Value) == plr.Name then
                local plot = obj.Parent
                if plot:IsA("Model") then
                    return plot:GetPivot().Position
                else
                    local firstPart = plot:FindFirstChildWhichIsA("BasePart", true)
                    if firstPart then return firstPart.Position end
                end
            end
        end
    end
    return nil
end

-- ===================== SLOW FLY TO RANCH =====================
local function slowFlyTo(dest)
    local hrp = charHRP()
    if not hrp then return end
    hrp.Anchored = true
    local start = hrp.Position
    local total = (dest - start).Magnitude
    if total >= 2 then
        local travelled, guard = 0, 0
        local slowSpeed = 45 -- Slow, cinematic speed
        while env._menuId == myId and guard < 5000 do
            local dt = RunService.Heartbeat:Wait()
            guard += 1
            travelled = math.min(travelled + slowSpeed * dt, total)
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
end

-- ===================== EGG PICKUP HOOK =====================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and typeof(self) == "Instance" and self.Name == "EggPickup" and env.autoDip then
        task.spawn(function()
            task.wait(0.4) 
            local hrp = charHRP()
            if hrp then
                -- 1. Teleport to Volcano & Dip
                hrp.CFrame = CFrame.new(VOLCANO_COORDS)
                task.wait(0.6) 
                local dipRemote = RS:FindFirstChild("packages") 
                    and RS.packages:FindFirstChild("Net") 
                    and RS.packages.Net:FindFirstChild("RE/VolcanoDip")
                if dipRemote then 
                    dipRemote:FireServer() 
                    sendNotification("Auto Dip", "Egg dipped in magma! Waiting...")
                end
                
                -- 2. Wait 3.5 seconds
                task.wait(3.5)
                
                -- 3. Teleport to Food Stalls
                hrp = charHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(FOOD_STALL_COORDS)
                    task.wait(0.6)
                    
                    -- 4. Dynamically find ranch and fly to it
                    local ranchPos = getPlayerRanchCoords()
                    if ranchPos then
                        sendNotification("Auto Dip Sequence", "Flying back to your Ranch!")
                        -- Add +15 to Y-axis so you don't glitch into the ground
                        slowFlyTo(ranchPos + Vector3.new(0, 15, 0)) 
                    else
                        sendNotification("Auto Dip Sequence", "Could not find your ranch! Staying at food stalls.")
                    end
                end
            end
        end)
    end
    return oldNamecall(self, ...)
end)

-- ===================== GUI MAIN =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HalloweenMenu"; screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(45, 45)
toggleBtn.Position = UDim2.new(0, 20, 0, 20)
toggleBtn.BackgroundColor3 = C_SIDEBAR
toggleBtn.Text = "🎃"
toggleBtn.TextSize = 25
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(420, 340)
mainFrame.Position = UDim2.new(0, 20, 0, 80)
mainFrame.BackgroundColor3 = C_BG
mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 36); titleLabel.BorderSizePixel = 0
titleLabel.BackgroundColor3 = C_ACCENT
titleLabel.Text = " Auto Halloween | by Vince"; titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame
Instance.new("UIPadding", titleLabel).PaddingLeft = UDim.new(0, 15)
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 10)

local titleBlock = Instance.new("Frame")
titleBlock.Size = UDim2.new(1, 0, 0, 10); titleBlock.Position = UDim2.new(0, 0, 1, -10)
titleBlock.BackgroundColor3 = C_ACCENT; titleBlock.BorderSizePixel = 0
titleBlock.Parent = titleLabel

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -36); sidebar.Position = UDim2.new(0, 0, 0, 36)
sidebar.BackgroundColor3 = C_SIDEBAR; sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local function createTabButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 45); btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = C_SIDEBAR; btn.BorderSizePixel = 0
    btn.Text = text; btn.TextColor3 = C_TEXT
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.Parent = sidebar
    return btn
end

local tabHalloweenBtn = createTabButton("Halloween", 10)
local tabTeleportBtn = createTabButton("Teleports", 55)
local tabEggBtn = createTabButton("Auto Egg", 100)

tabHalloweenBtn.BackgroundColor3 = C_BTN_OFF 

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -120, 1, -36); contentArea.Position = UDim2.new(0, 120, 0, 36)
contentArea.BackgroundTransparency = 1; contentArea.Parent = mainFrame

local function createButton(parent, text, yPos, height, fontSize)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, height or 35); btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BorderSizePixel = 0; btn.TextColor3 = C_TEXT
    btn.Font = Enum.Font.GothamBold; btn.TextSize = fontSize or 12
    btn.Text = text; btn.BackgroundColor3 = C_BTN_OFF
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- ===================== TAB 1: HALLOWEEN =====================
local halloweenFrame = Instance.new("Frame")
halloweenFrame.Size = UDim2.new(1, 0, 1, 0); halloweenFrame.BackgroundTransparency = 1
halloweenFrame.Parent = contentArea

local autoButton = createButton(halloweenFrame, "AUTO FARM: OFF", 15, 45, 14)
local modeButton = createButton(halloweenFrame, "ORDER: NEAREST", 70, 32, 11)
local moveButton = createButton(halloweenFrame, "MOVEMENT: FLY", 110, 32, 11)
local caveButton = createButton(halloweenFrame, "OPEN CAVE: OFF", 150, 32, 11)
local speedButton = createButton(halloweenFrame, "SPEED: NORMAL", 190, 32, 11)
speedButton.BackgroundColor3 = Color3.fromRGB(55, 65, 85) 

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40); statusLabel.Position = UDim2.new(0, 10, 0, 235)
statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = Color3.fromRGB(180,180,180)
statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left; statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Status: Ready."; statusLabel.Parent = halloweenFrame

-- ===================== TAB 2: TELEPORTS =====================
local teleportFrame = Instance.new("Frame")
teleportFrame.Size = UDim2.new(1, 0, 1, 0); teleportFrame.BackgroundTransparency = 1
teleportFrame.Visible = false; teleportFrame.Parent = contentArea

local foodStallBtn = createButton(teleportFrame, "TP: FOOD STALLS", 15, 40, 12)
local volcanoBtn = createButton(teleportFrame, "TP: VOLCANO", 65, 40, 12)
local autoDipBtn = createButton(teleportFrame, "AUTO DIP: OFF", 115, 45, 14)

-- ===================== TAB 3: AUTO EGG =====================
local eggFrame = Instance.new("Frame")
eggFrame.Size = UDim2.new(1, 0, 1, 0); eggFrame.BackgroundTransparency = 1
eggFrame.Visible = false; eggFrame.Parent = contentArea

local autoBuyBtn = createButton(eggFrame, "BUY SHOP EGG: OFF", 15, 40, 12)
local autoEggBtn = createButton(eggFrame, "CLAIM MAP EGG", 65, 40, 12)
local refreshEggsBtn = createButton(eggFrame, "SCAN FOR EGGS", 115, 30, 11)
refreshEggsBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
local dropdownBtn = createButton(eggFrame, "Target: None ▼", 155, 30, 11)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)

local eggScrollList = Instance.new("ScrollingFrame")
eggScrollList.Size = UDim2.new(1, -20, 0, 110); eggScrollList.Position = UDim2.new(0, 10, 0, 185)
eggScrollList.BackgroundColor3 = C_SIDEBAR; eggScrollList.BorderSizePixel = 0
eggScrollList.ScrollBarThickness = 4; eggScrollList.Visible = false
eggScrollList.Parent = eggFrame
Instance.new("UICorner", eggScrollList).CornerRadius = UDim.new(0, 6)

local eggListLayout = Instance.new("UIListLayout")
eggListLayout.Parent = eggScrollList
eggListLayout.SortOrder = Enum.SortOrder.LayoutOrder
eggListLayout.Padding = UDim.new(0, 2)

dropdownBtn.MouseButton1Click:Connect(function() eggScrollList.Visible = not eggScrollList.Visible end)

local function populateEggList()
    for _, child in ipairs(eggScrollList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local foundEggs = {}
    local renderedEggs = workspace:FindFirstChild("RenderedEggs")
    
    if renderedEggs then
        for _, egg in ipairs(renderedEggs:GetChildren()) do
            if egg:IsA("Model") and not table.find(foundEggs, egg.Name) then
                table.insert(foundEggs, egg.Name)
            end
        end
    end
    
    if #foundEggs == 0 then table.insert(foundEggs, "No Eggs Spawned") end
    
    for _, eggName in ipairs(foundEggs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 25); btn.BackgroundColor3 = C_SIDEBAR
        btn.BorderSizePixel = 0; btn.TextColor3 = C_TEXT
        btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.Text = eggName
        btn.Parent = eggScrollList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            if eggName ~= "No Eggs Spawned" then
                env.targetEgg = eggName
                dropdownBtn.Text = "Target: " .. eggName .. " ▼"
            end
            eggScrollList.Visible = false
        end)
    end
    eggScrollList.CanvasSize = UDim2.new(0, 0, 0, #foundEggs * 27)
end

refreshEggsBtn.MouseButton1Click:Connect(function()
    dropdownBtn.Text = "Scanning..."
    populateEggList()
    task.wait(0.2)
    dropdownBtn.Text = env.targetEgg and ("Target: " .. env.targetEgg .. " ▼") or "Target: None ▼"
end)
populateEggList()

-- ===================== TAB SWITCHING =====================
local function switchTab(tabName)
    halloweenFrame.Visible = (tabName == "Halloween")
    teleportFrame.Visible = (tabName == "Teleports")
    eggFrame.Visible = (tabName == "Auto Egg")
    
    tabHalloweenBtn.BackgroundColor3 = (tabName == "Halloween") and C_BTN_OFF or C_SIDEBAR
    tabTeleportBtn.BackgroundColor3 = (tabName == "Teleports") and C_BTN_OFF or C_SIDEBAR
    tabEggBtn.BackgroundColor3 = (tabName == "Auto Egg") and C_BTN_OFF or C_SIDEBAR
end

tabHalloweenBtn.MouseButton1Click:Connect(function() switchTab("Halloween") end)
tabTeleportBtn.MouseButton1Click:Connect(function() switchTab("Teleports") end)
tabEggBtn.MouseButton1Click:Connect(function() switchTab("Auto Egg") end)

-- ===================== FLYING & MOVEMENT =====================
local function setCollide(collide)
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = collide and (p.Name ~= "HumanoidRootPart") or false
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

local function updateFlyingState()
    local shouldFly = env.auto
    setFlying(shouldFly)
    if not shouldFly then
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
        task.wait(0.5) 
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

-- ===================== UI BUTTON LOGIC =====================
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
    autoDipBtn.BackgroundColor3 = env.autoDip and C_BTN_ON or C_BTN_OFF
end)

autoBuyBtn.MouseButton1Click:Connect(function()
    env.autoBuyEgg = not env.autoBuyEgg
    autoBuyBtn.Text = "BUY SHOP EGG: " .. (env.autoBuyEgg and "ON" or "OFF")
    autoBuyBtn.BackgroundColor3 = env.autoBuyEgg and C_BTN_ON or C_BTN_OFF
end)

autoEggBtn.MouseButton1Click:Connect(function()
    if not env.targetEgg or env.targetEgg == "No Eggs Spawned" then
        autoEggBtn.Text = "SELECT TARGET ▼ FIRST!"
        task.wait(1.5)
        autoEggBtn.Text = "CLAIM MAP EGG"
        return
    end
    
    env.autoEgg = true
    autoEggBtn.Text = "CLAIMING..."
    autoEggBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
end)

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
    caveButton.BackgroundColor3 = env.autoCave and C_BTN_ON or C_BTN_OFF
end)

speedButton.MouseButton1Click:Connect(function()
    currentSpeedIdx = (currentSpeedIdx % #speeds) + 1
    env.speed = speeds[currentSpeedIdx].value
    speedButton.Text = "SPEED: " .. speeds[currentSpeedIdx].name
end)

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
    autoButton.Text = "AUTO FARM: " .. (v and "ON" or "OFF")
    autoButton.BackgroundColor3 = v and C_BTN_ON or C_BTN_OFF
    updateFlyingState()
end
autoButton.MouseButton1Click:Connect(function() setAuto(not env.auto) end)

modeButton.MouseButton1Click:Connect(function()
    env.mode = (env.mode == "value") and "near" or "value"
    modeButton.Text = (env.mode == "value") and "ORDER: MOST VALUABLE" or "ORDER: NEAREST"
end)

plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateFlyingState()
end)

-- ===================== AUTO BUY LOOP =====================
task.spawn(function()
    while env._menuId == myId do
        if env.autoBuyEgg then
            local remote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Game") and RS.Remotes.Game:FindFirstChild("BuyHalloweenEgg")
            if remote then pcall(function() remote:InvokeServer("Halloween Egg") end) end
        end
        task.wait(1)
    end
end)

-- ===================== MAIN CYCLE =====================
task.spawn(function()
    while env._menuId == myId do
        
        -- [1] AUTO EGG MACRO (ONE TIME TRIGGER)
        if env.autoEgg and env.targetEgg then
            local renderedEggs = workspace:FindFirstChild("RenderedEggs")
            local eggFound = false
            
            if renderedEggs then
                for _, egg in ipairs(renderedEggs:GetChildren()) do
                    if not env.autoEgg or env._menuId ~= myId then break end
                    
                    if egg:IsA("Model") and egg.Name == env.targetEgg then
                        eggFound = true
                        local targetPos = egg:GetPivot().Position
                        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                        
                        if prompt and targetPos then
                            statusLabel.Text = "Status: Teleporting to " .. egg.Name
                            
                            local hrp = charHRP()
                            if hrp then 
                                hrp.Anchored = false
                                hrp.CFrame = CFrame.new(targetPos) 
                                hrp.AssemblyLinearVelocity = Vector3.zero
                            end
                            task.wait(0.5)
                            
                            triggerPrompt(prompt)
                            
                            local timeout = 0
                            while egg.Parent and timeout < 30 do
                                task.wait(0.1)
                                timeout = timeout + 1
                            end
                        end
                        break
                    end
                end
            end
            
            env.autoEgg = false
            autoEggBtn.Text = "CLAIM MAP EGG"
            autoEggBtn.BackgroundColor3 = C_BTN_OFF
            
            if not eggFound then
                statusLabel.Text = "Status: Egg not found!"
                task.wait(2)
            end
        end

        -- [2] AUTO CANDY FARMING
        if env.auto then
            
            if env.autoCave then
                local caveDoor
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and (p.Name:lower():find("cavedoor") or p.Name:lower():find("ritual")) then
                        if p:FindFirstChildWhichIsA("ProximityPrompt", true) then caveDoor = p; break end
                    end
                end

                if caveDoor then
                    statusLabel.Text = "Status: Checking secret cave..."
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
                if p:IsA("BasePart") and (p.Name == "Yin" or p.Name == "Yang") then candies[#candies+1] = p end
            end

            if #candies == 0 then
                statusLabel.Text = "Status: No candy, waiting..."
                task.wait(0.5)
            else
                if env.mode == "value" then
                    table.sort(candies, function(a, b)
                        local function getVal(part) return (part.Name == "Yin" or part.Name == "Yang") and 9999999 or candyValue(part) end
                        return getVal(a) > getVal(b)
                    end)
                else
                    local pad = dropoffPad()
                    if pad then
                        table.sort(candies, function(a, b) return (a.Position - pad.Position).Magnitude < (b.Position - pad.Position).Magnitude end)
                    end
                end

                for i, part in ipairs(candies) do
                    if not env.auto or env._menuId ~= myId then break end

                    local id = part.Name == "Yin" and "Yin" or part.Name == "Yang" and "Yang" or candyId(part, i)                    
                    statusLabel.Text = "Status: Flying to " .. id
                    flyTo(part.Position)
                    task.wait(0.15)

                    for attempt = 1, 4 do
                        if not env.auto or env._menuId ~= myId then break end
                        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if not triggerPrompt(prompt) then triggerPromptsNear(part.Position, 8) end
                        
                        if id ~= "Yin" and id ~= "Yang" then CollectCandy:FireServer(id)
                        else if attempt == 1 then sendNotification("🔮 Sigil Sniper", "Successfully collected the " .. id .. " sigil!") end end
                        
                        task.wait(0.3)
                        if part.Parent ~= CANDY_FOLDER and part.Parent ~= workspace then break end
                    end

                    if env.auto and id ~= "Yin" and id ~= "Yang" then
                        local pad = dropoffPad()
                        if pad then
                            statusLabel.Text = "Status: Returning to dropoff"
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
            if not env.autoEgg then statusLabel.Text = "Status: Idle." end
        end
        
        task.wait(0.1)
    end
end)

env._menuCleanup = function()
    setAuto(false)
    env.autoEgg = false
    env.autoBuyEgg = false
    updateFlyingState()
    env._menuId = env._menuId + 1
    screenGui:Destroy()
end

print("[Menu Halloween v17 | Dynamic Ranch Finder] loaded.")
