--[[=====================================================
    MENU HALLOWEEN v26 by Vince (Ghost TP Buy & Safe TP)
=====================================================]]

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VirtualUser  = game:GetService("VirtualUser")

local plr = Players.LocalPlayer
local GameRemotes  = RS:WaitForChild("Remotes"):WaitForChild("Game")
local CollectCandy = GameRemotes:WaitForChild("CollectCandy")

local CANDY_FOLDER = workspace:WaitForChild("HalloweenCandy")
local DROPOFF      = workspace:WaitForChild("CandyDropOff")

-- [ FIXED COORDINATES ]
local VOLCANO_COORDS    = Vector3.new(-5109.14, 41435.2, -3472.42) 
local FOOD_STALL_COORDS = Vector3.new(125.546, 40322.6, 948.211)
local HALLOWEEN_COORDS  = CFrame.new(-46026.58984375, 40384.05859375, -20304.263671875)

-- [ VOLCANIC CAVE COORDINATES ]
local CAVE_OUTSIDE_COORDS = Vector3.new(-4879.784, 41282.800, -3745.737)
local CAVE_INSIDE_COORDS  = Vector3.new(-4985.543, 41287.269, -3623.517)

local DepositRemote
for _, r in ipairs(GameRemotes:GetChildren()) do
    if r.Name:lower():find("deposit") then DepositRemote = r break end
end

local env = (getgenv and getgenv()) or _G
if env._menuCleanup then pcall(env._menuCleanup) end
env._menuId = (env._menuId or 0) + 1
local myId = env._menuId

-- STATE VARIABLES
env.auto            = false
env.arc             = 8
env.mode            = "near"
env.moveMode        = "fly"
env.autoCave        = false
env.autoDip         = false
env.autoEggMacro    = false
env.autoFarmEggs    = false
env.autoVolcanicEgg = false
env.autoBuyEgg      = false
env.targetEggs      = {} 
env.espEnabled      = false
env.espTarget       = "All"
env.tpTargetEggName = nil
env.isDipping       = false
env.suppressDipHook = false 

-- ALL KNOWN EGGS (Master Target List)
local KNOWN_EGGS = {
    "Asteroid Egg", "Brown Egg", "Cherub Egg", "Halloween Egg", 
    "Solaris Egg", "Volcanic Egg", "Blue Egg", "Green Egg", "Red Egg"
}

-- SPEED SETTINGS
local speeds = {
    {name = "NORMAL", value = 150},
    {name = "FAST", value = 300},
    {name = "SUPER FAST", value = 600},
    {name = "SPEED OF LIGHT", value = 1000}
}
local currentSpeedIdx = 1
env.speed = speeds[currentSpeedIdx].value

-- UI COLORS
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
        game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
end

-- ===================== ANTI-AFK SYSTEM =====================
plr.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local idleSeconds = 0
UIS.InputBegan:Connect(function() idleSeconds = 0 end)
UIS.InputChanged:Connect(function() idleSeconds = 0 end)
task.spawn(function()
    while env._menuId == myId do
        task.wait(1)
        idleSeconds = idleSeconds + 1
        if idleSeconds >= 600 then
            local cam = workspace.CurrentCamera
            if cam then
                local midX, midY = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                VirtualUser:Button1Down(Vector2.new(midX, midY))
                task.wait(0.05)
                VirtualUser:Button1Up(Vector2.new(midX, midY))
            end
        end
    end
end)

-- ===================== GET EGG KG HELPER =====================
local function getEggKg(egg)
    local kg = nil
    pcall(function()
        for k, v in pairs(egg:GetAttributes()) do
            if string.lower(tostring(k)):find("kg") or string.lower(tostring(k)):find("weight") or string.lower(tostring(k)):find("mass") then
                kg = tonumber(v)
            end
        end
        if not kg then
            for _, c in ipairs(egg:GetChildren()) do
                if (c:IsA("NumberValue") or c:IsA("IntValue") or c:IsA("StringValue")) and 
                   (string.lower(c.Name):find("kg") or string.lower(c.Name):find("weight") or string.lower(c.Name):find("mass")) then
                    kg = tonumber(c.Value)
                end
            end
        end
    end)
    return kg
end

-- ===================== DYNAMIC RANCH FINDER =====================
local function getPlayerRanchCoords()
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

-- ===================== SLOW FLY =====================
local function slowFlyTo(dest)
    local hrp = charHRP()
    if not hrp then return end
    hrp.Anchored = true
    local start = hrp.Position
    local total = (dest - start).Magnitude
    if total >= 2 then
        local travelled, guard = 0, 0
        local slowSpeed = 45
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
    if method == "FireServer" and typeof(self) == "Instance" and self.Name == "EggPickup" and env.autoDip and not env.suppressDipHook then
        env.isDipping = true
        task.spawn(function()
            task.wait(0.4) 
            local hrp = charHRP()
            if hrp then
                hrp.CFrame = CFrame.new(VOLCANO_COORDS)
                task.wait(1.6) 
                
                local dipRemote = RS:FindFirstChild("packages") and RS.packages:FindFirstChild("Net") and RS.packages.Net:FindFirstChild("RE/VolcanoDip")
                if dipRemote then dipRemote:FireServer() end
                
                task.wait(10)
                
                hrp = charHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(FOOD_STALL_COORDS)
                    task.wait(5)
                    
                    local ranchPos = getPlayerRanchCoords()
                    if ranchPos then
                        slowFlyTo(ranchPos + Vector3.new(0, 15, 0)) 
                        task.wait(1)
                    end
                end
            end
            env.isDipping = false
        end)
    end
    return oldNamecall(self, ...)
end)

-- ===================== GUI MAIN =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HalloweenMenu"; screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

if env._espFolder then pcall(function() env._espFolder:Destroy() end) end
local espFolder = Instance.new("Folder")
espFolder.Name = "HalloweenESP"
espFolder.Parent = screenGui
env._espFolder = espFolder

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
mainFrame.Size = UDim2.fromOffset(420, 460)
mainFrame.Position = UDim2.new(0, 20, 0, 80)
mainFrame.BackgroundColor3 = C_BG
mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

toggleBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)

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

local autoButton = createButton(halloweenFrame, "AUTO FARM: OFF", 10, 40, 14)
local autoBuyBtn = createButton(halloweenFrame, "BUY SHOP EGG: OFF", 55, 40, 12)
local modeButton = createButton(halloweenFrame, "ORDER: NEAREST", 100, 30, 11)
local moveButton = createButton(halloweenFrame, "MOVEMENT: FLY", 135, 30, 11)
local caveButton = createButton(halloweenFrame, "OPEN CAVE: OFF", 170, 30, 11)
local speedButton = createButton(halloweenFrame, "SPEED: NORMAL", 205, 30, 11)
speedButton.BackgroundColor3 = Color3.fromRGB(55, 65, 85) 

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40); statusLabel.Position = UDim2.new(0, 10, 0, 240)
statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = Color3.fromRGB(180,180,180)
statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left; statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Status: Ready."; statusLabel.Parent = halloweenFrame

-- ===================== TAB 2: TELEPORTS =====================
local teleportFrame = Instance.new("Frame")
teleportFrame.Size = UDim2.new(1, 0, 1, 0); teleportFrame.BackgroundTransparency = 1
teleportFrame.Visible = false; teleportFrame.Parent = contentArea

local foodStallBtn = createButton(teleportFrame, "TP: FOOD STALLS", 10, 35, 12)
local volcanoBtn = createButton(teleportFrame, "TP: VOLCANO", 50, 35, 12)
local autoDipBtn = createButton(teleportFrame, "AUTO DIP: OFF", 90, 35, 14)

local tpToEggBtn = createButton(teleportFrame, "TP TO SELECTED EGG", 130, 35, 12)
local tpScanBtn = createButton(teleportFrame, "SCAN MAP FOR SPAWNED EGGS", 170, 25, 11)
tpScanBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
local tpSpawnedDropdownBtn = createButton(teleportFrame, "Select Spawned Egg ▼", 200, 25, 11)
tpSpawnedDropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)

local tpSpawnedScrollList = Instance.new("ScrollingFrame")
tpSpawnedScrollList.Size = UDim2.new(1, -20, 0, 150); tpSpawnedScrollList.Position = UDim2.new(0, 10, 0, 230)
tpSpawnedScrollList.BackgroundColor3 = C_SIDEBAR; tpSpawnedScrollList.BorderSizePixel = 0
tpSpawnedScrollList.ScrollBarThickness = 4; tpSpawnedScrollList.Visible = false; tpSpawnedScrollList.ZIndex = 15
tpSpawnedScrollList.Parent = teleportFrame
Instance.new("UICorner", tpSpawnedScrollList).CornerRadius = UDim.new(0, 6)
local tpSpawnedLayout = Instance.new("UIListLayout")
tpSpawnedLayout.Parent = tpSpawnedScrollList; tpSpawnedLayout.SortOrder = Enum.SortOrder.LayoutOrder; tpSpawnedLayout.Padding = UDim.new(0, 2)

-- ===================== TAB 3: AUTO EGG =====================
local eggFrame = Instance.new("Frame")
eggFrame.Size = UDim2.new(1, 0, 1, 0); eggFrame.BackgroundTransparency = 1
eggFrame.Visible = false; eggFrame.Parent = contentArea

local autoFarmEggBtn = createButton(eggFrame, "AUTO FARM EGGS: OFF", 10, 35, 12)
local autoEggMacroBtn = createButton(eggFrame, "CLAIM MAP EGG (ONCE)", 50, 35, 12)
local autoVolcanicBtn = createButton(eggFrame, "AUTO VOLCANIC EGG: OFF", 90, 35, 12)

local targetDropdownBtn = createButton(eggFrame, "Select Best Eggs ▼", 130, 25, 11)
targetDropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)

local espEggBtn = createButton(eggFrame, "ESP EGG: OFF", 160, 35, 14)
local espDropdownBtn = createButton(eggFrame, "ESP Target: All ▼", 200, 25, 11)
espDropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)

local refreshEggsBtn = createButton(eggFrame, "REFRESH EGG LISTS", 230, 25, 11)
refreshEggsBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)

local targetScrollList = Instance.new("ScrollingFrame")
targetScrollList.Size = UDim2.new(1, -20, 0, 150); targetScrollList.Position = UDim2.new(0, 10, 0, 160)
targetScrollList.BackgroundColor3 = C_SIDEBAR; targetScrollList.BorderSizePixel = 0
targetScrollList.ScrollBarThickness = 4; targetScrollList.Visible = false; targetScrollList.ZIndex = 15
targetScrollList.Parent = eggFrame
Instance.new("UICorner", targetScrollList).CornerRadius = UDim.new(0, 6)
local targetLayout = Instance.new("UIListLayout"); targetLayout.Parent = targetScrollList; targetLayout.SortOrder = Enum.SortOrder.LayoutOrder; targetLayout.Padding = UDim.new(0, 2)

local espScrollList = Instance.new("ScrollingFrame")
espScrollList.Size = UDim2.new(1, -20, 0, 150); espScrollList.Position = UDim2.new(0, 10, 0, 230)
espScrollList.BackgroundColor3 = C_SIDEBAR; espScrollList.BorderSizePixel = 0
espScrollList.ScrollBarThickness = 4; espScrollList.Visible = false; espScrollList.ZIndex = 15
espScrollList.Parent = eggFrame
Instance.new("UICorner", espScrollList).CornerRadius = UDim.new(0, 6)
local espLayout = Instance.new("UIListLayout"); espLayout.Parent = espScrollList; espLayout.SortOrder = Enum.SortOrder.LayoutOrder; espLayout.Padding = UDim.new(0, 2)

targetDropdownBtn.MouseButton1Click:Connect(function() 
    targetScrollList.Visible = not targetScrollList.Visible; espScrollList.Visible = false 
end)
espDropdownBtn.MouseButton1Click:Connect(function() 
    espScrollList.Visible = not espScrollList.Visible; targetScrollList.Visible = false 
end)
tpSpawnedDropdownBtn.MouseButton1Click:Connect(function()
    tpSpawnedScrollList.Visible = not tpSpawnedScrollList.Visible
end)

-- ===================== LIST BUILDERS =====================
local function updateKnownEggs()
    local renderedEggs = workspace:FindFirstChild("RenderedEggs")
    if renderedEggs then
        for _, egg in ipairs(renderedEggs:GetChildren()) do
            if egg:IsA("Model") and not table.find(KNOWN_EGGS, egg.Name) then
                table.insert(KNOWN_EGGS, egg.Name)
            end
        end
    end
    table.sort(KNOWN_EGGS)
end

local function refreshTargetAndEspLists()
    updateKnownEggs()
    for _, c in ipairs(targetScrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, c in ipairs(espScrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    
    local btnAll = Instance.new("TextButton")
    btnAll.Size = UDim2.new(1, -8, 0, 25); btnAll.BackgroundColor3 = (env.espTarget == "All") and C_BTN_ON or C_SIDEBAR
    btnAll.BorderSizePixel = 0; btnAll.TextColor3 = C_TEXT; btnAll.Font = Enum.Font.Gotham; btnAll.TextSize = 11; btnAll.Text = "All Spawned Eggs"
    btnAll.Parent = espScrollList
    Instance.new("UICorner", btnAll).CornerRadius = UDim.new(0, 4)
    btnAll.MouseButton1Click:Connect(function()
        env.espTarget = "All"; espDropdownBtn.Text = "ESP Target: All ▼"
        espScrollList.Visible = false; refreshTargetAndEspLists()
    end)

    for _, eggName in ipairs(KNOWN_EGGS) do
        local tBtn = Instance.new("TextButton")
        tBtn.Size = UDim2.new(1, -8, 0, 25); tBtn.BackgroundColor3 = table.find(env.targetEggs, eggName) and C_BTN_ON or C_SIDEBAR
        tBtn.BorderSizePixel = 0; tBtn.TextColor3 = C_TEXT; tBtn.Font = Enum.Font.Gotham; tBtn.TextSize = 11; tBtn.Text = eggName
        tBtn.Parent = targetScrollList
        Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 4)
        tBtn.MouseButton1Click:Connect(function()
            local idx = table.find(env.targetEggs, eggName)
            if idx then table.remove(env.targetEggs, idx) else table.insert(env.targetEggs, eggName) end
            targetDropdownBtn.Text = "Targets: " .. #env.targetEggs .. " Selected ▼"
            refreshTargetAndEspLists()
        end)
        
        local eBtn = Instance.new("TextButton")
        eBtn.Size = UDim2.new(1, -8, 0, 25); eBtn.BackgroundColor3 = (env.espTarget == eggName) and C_BTN_ON or C_SIDEBAR
        eBtn.BorderSizePixel = 0; eBtn.TextColor3 = C_TEXT; eBtn.Font = Enum.Font.Gotham; eBtn.TextSize = 11; eBtn.Text = eggName
        eBtn.Parent = espScrollList
        Instance.new("UICorner", eBtn).CornerRadius = UDim.new(0, 4)
        eBtn.MouseButton1Click:Connect(function()
            env.espTarget = eggName; espDropdownBtn.Text = "ESP Target: " .. eggName .. " ▼"
            espScrollList.Visible = false; refreshTargetAndEspLists()
        end)
    end
    targetScrollList.CanvasSize = UDim2.new(0, 0, 0, #KNOWN_EGGS * 27)
    espScrollList.CanvasSize = UDim2.new(0, 0, 0, (#KNOWN_EGGS + 1) * 27)
end

local function refreshTpSpawnedList()
    for _, c in ipairs(tpSpawnedScrollList:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    
    local foundEggs = {}
    local renderedEggs = workspace:FindFirstChild("RenderedEggs")
    if renderedEggs then
        for _, egg in ipairs(renderedEggs:GetChildren()) do
            if egg:IsA("Model") and not table.find(foundEggs, egg.Name) then
                table.insert(foundEggs, egg.Name)
            end
        end
    end
    
    if #foundEggs == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 0, 25); lbl.BackgroundColor3 = C_SIDEBAR; lbl.BorderSizePixel = 0
        lbl.TextColor3 = C_TEXT; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.Text = "No Eggs on Map"
        lbl.Parent = tpSpawnedScrollList
        tpSpawnedDropdownBtn.Text = "Spawned: 0 ▼"
        tpSpawnedScrollList.CanvasSize = UDim2.new(0, 0, 0, 27)
        return
    end
    
    tpSpawnedDropdownBtn.Text = "Spawned: " .. #foundEggs .. " ▼"
    
    for _, eggName in ipairs(foundEggs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 25); btn.BackgroundColor3 = (env.tpTargetEggName == eggName) and C_BTN_ON or C_SIDEBAR
        btn.BorderSizePixel = 0; btn.TextColor3 = C_TEXT; btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.Text = eggName
        btn.Parent = tpSpawnedScrollList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            env.tpTargetEggName = eggName
            tpSpawnedDropdownBtn.Text = "TP Target: " .. eggName .. " ▼"
            tpSpawnedScrollList.Visible = false
            refreshTpSpawnedList()
        end)
    end
    tpSpawnedScrollList.CanvasSize = UDim2.new(0, 0, 0, #foundEggs * 27)
end

refreshEggsBtn.MouseButton1Click:Connect(function()
    refreshTargetAndEspLists()
    refreshTpSpawnedList()
end)
tpScanBtn.MouseButton1Click:Connect(function() refreshTpSpawnedList() end)

refreshTargetAndEspLists()
refreshTpSpawnedList()

-- ===================== TAB SWITCHING =====================
local function switchTab(tabName)
    halloweenFrame.Visible = (tabName == "Halloween")
    teleportFrame.Visible = (tabName == "Teleports")
    eggFrame.Visible = (tabName == "Auto Egg")
    
    tabHalloweenBtn.BackgroundColor3 = (tabName == "Halloween") and C_BTN_OFF or C_SIDEBAR
    tabTeleportBtn.BackgroundColor3 = (tabName == "Teleports") and C_BTN_OFF or C_SIDEBAR
    tabEggBtn.BackgroundColor3 = (tabName == "Auto Egg") and C_BTN_OFF or C_SIDEBAR
    
    targetScrollList.Visible = false
    espScrollList.Visible = false
    tpSpawnedScrollList.Visible = false
end

tabHalloweenBtn.MouseButton1Click:Connect(function() switchTab("Halloween") end)
tabTeleportBtn.MouseButton1Click:Connect(function() switchTab("Teleports") end)
tabEggBtn.MouseButton1Click:Connect(function() switchTab("Auto Egg") end)

-- ===================== FLYING & PROMPT UTIL =====================
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
    local oldLOS = prompt.RequiresLineOfSight
    prompt.RequiresLineOfSight = false
    if fireproximityprompt then pcall(function() fireproximityprompt(prompt, 1, true) end) end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.05) + 0.05)
        prompt:InputHoldEnd()
    end)
    prompt.RequiresLineOfSight = oldLOS
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

-- TP TO SELECTED EGG (Strict Teleport)
tpToEggBtn.MouseButton1Click:Connect(function()
    if not env.tpTargetEggName then
        sendNotification("Teleport", "Select an egg from the scanner first!")
        return
    end
    local renderedEggs = workspace:FindFirstChild("RenderedEggs")
    local found = false
    if renderedEggs then
        for _, egg in ipairs(renderedEggs:GetChildren()) do
            if egg:IsA("Model") and egg.Name == env.tpTargetEggName then
                local hrp = charHRP()
                if hrp then
                    hrp.Anchored = false
                    -- Added Y+5 offset to prevent getting stuck in the ground or the egg model
                    hrp.CFrame = egg:GetPivot() + Vector3.new(0, 5, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    found = true
                    sendNotification("Teleport", "Teleported to " .. egg.Name)
                    break
                end
            end
        end
    end
    if not found then sendNotification("Teleport", "Egg is no longer on the map!") end
end)

autoBuyBtn.MouseButton1Click:Connect(function()
    env.autoBuyEgg = not env.autoBuyEgg
    autoBuyBtn.Text = "BUY SHOP EGG: " .. (env.autoBuyEgg and "ON" or "OFF")
    autoBuyBtn.BackgroundColor3 = env.autoBuyEgg and C_BTN_ON or C_BTN_OFF
end)

autoFarmEggBtn.MouseButton1Click:Connect(function()
    env.autoFarmEggs = not env.autoFarmEggs
    autoFarmEggBtn.Text = "AUTO FARM EGGS: " .. (env.autoFarmEggs and "ON" or "OFF")
    autoFarmEggBtn.BackgroundColor3 = env.autoFarmEggs and C_BTN_ON or C_BTN_OFF
end)

autoVolcanicBtn.MouseButton1Click:Connect(function()
    env.autoVolcanicEgg = not env.autoVolcanicEgg
    autoVolcanicBtn.Text = "AUTO VOLCANIC EGG: " .. (env.autoVolcanicEgg and "ON" or "OFF")
    autoVolcanicBtn.BackgroundColor3 = env.autoVolcanicEgg and C_BTN_ON or C_BTN_OFF
end)

autoEggMacroBtn.MouseButton1Click:Connect(function()
    if #env.targetEggs == 0 then
        autoEggMacroBtn.Text = "SELECT TARGETS FIRST!"
        task.wait(1.5)
        autoEggMacroBtn.Text = "CLAIM MAP EGG (ONCE)"
        return
    end
    env.autoEggMacro = true
    autoEggMacroBtn.Text = "CLAIMING..."
    autoEggMacroBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
end)

espEggBtn.MouseButton1Click:Connect(function()
    env.espEnabled = not env.espEnabled
    espEggBtn.Text = "ESP EGG: " .. (env.espEnabled and "ON" or "OFF")
    espEggBtn.BackgroundColor3 = env.espEnabled and C_BTN_ON or C_BTN_OFF
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

-- ===================== ESP RENDER LOOP =====================
task.spawn(function()
    while env._menuId == myId do
        espFolder:ClearAllChildren()
        if env.espEnabled then
            local renderedEggs = workspace:FindFirstChild("RenderedEggs")
            if renderedEggs then
                for _, egg in ipairs(renderedEggs:GetChildren()) do
                    if egg:IsA("Model") and (env.espTarget == "All" or egg.Name == env.espTarget) then
                        local bb = Instance.new("BillboardGui")
                        bb.Adornee = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart") or egg
                        bb.Size = UDim2.new(0, 150, 0, 40)
                        bb.StudsOffset = Vector3.new(0, 2, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = espFolder
                        
                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 12
                        txt.TextColor3 = Color3.fromRGB(0, 255, 128)
                        txt.TextStrokeTransparency = 0.2
                        
                        local kg = getEggKg(egg)
                        if kg then
                            txt.Text = egg.Name .. "\n[" .. tostring(kg) .. " kg]"
                        else
                            txt.Text = egg.Name
                        end
                        txt.Parent = bb
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- ===================== AUTO BUY LOOP (GHOST TP) =====================
task.spawn(function()
    while env._menuId == myId do
        if env.autoBuyEgg then
            local remote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Game") and RS.Remotes.Game:FindFirstChild("BuyHalloweenEgg")
            if remote then 
                pcall(function() 
                    local hrp = charHRP()
                    if hrp then
                        -- Check distance. If too far, Ghost TP to the Halloween shop area to bypass server checks
                        local dist = (hrp.Position - HALLOWEEN_COORDS.Position).Magnitude
                        if dist > 50 then
                            local oldPos = hrp.CFrame
                            hrp.CFrame = HALLOWEEN_COORDS
                            task.wait(0.2)
                            remote:InvokeServer("Halloween Egg")
                            task.wait(0.2)
                            hrp.CFrame = oldPos -- Instantly teleport back
                        else
                            remote:InvokeServer("Halloween Egg")
                        end
                    end
                end) 
            end
        end
        task.wait(1)
    end
end)

-- ===================== MAIN CYCLE =====================
task.spawn(function()
    while env._menuId == myId do
        
        if env.isDipping then
            statusLabel.Text = "Status: Executing Sequence..."
            task.wait(0.5)
            continue
        end

        local processedEgg = false

        -- [0] AUTO VOLCANIC EGG
        if env.autoVolcanicEgg then
            local vEgg = nil
            local renderedEggs = workspace:FindFirstChild("RenderedEggs")
            if renderedEggs then
                for _, egg in ipairs(renderedEggs:GetChildren()) do
                    if egg:IsA("Model") and egg.Name == "Volcanic Egg" then
                        vEgg = egg
                        break
                    end
                end
            end
            
            if vEgg then
                processedEgg = true
                env.isDipping = true
                env.suppressDipHook = true 
                
                local hrp = charHRP()
                if hrp then
                    statusLabel.Text = "Status: Infiltrating Volcano..."
                    hrp.Anchored = false
                    
                    hrp.CFrame = CFrame.new(CAVE_OUTSIDE_COORDS)
                    task.wait(0.5)
                    
                    slowFlyTo(CAVE_INSIDE_COORDS)
                    task.wait(0.5)
                    
                    hrp.CFrame = CFrame.new(vEgg:GetPivot().Position)
                    task.wait(0.5)
                    
                    local prompt = vEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    triggerPrompt(prompt)
                    
                    local timeout = 0
                    while vEgg.Parent and timeout < 30 do
                        task.wait(0.1)
                        timeout = timeout + 1
                    end
                    
                    hrp.CFrame = CFrame.new(CAVE_INSIDE_COORDS)
                    task.wait(0.5)
                    
                    statusLabel.Text = "Status: Exiting Volcano..."
                    slowFlyTo(CAVE_OUTSIDE_COORDS)
                    task.wait(0.5)
                    
                    if env.autoDip then
                        statusLabel.Text = "Status: Dipping Volcanic Egg..."
                        hrp.CFrame = CFrame.new(VOLCANO_COORDS)
                        task.wait(1.6) 
                        
                        local dipRemote = RS:FindFirstChild("packages") and RS.packages:FindFirstChild("Net") and RS.packages.Net:FindFirstChild("RE/VolcanoDip")
                        if dipRemote then dipRemote:FireServer() end
                        
                        task.wait(10)
                        
                        hrp = charHRP()
                        if hrp then
                            hrp.CFrame = CFrame.new(FOOD_STALL_COORDS)
                            task.wait(5)
                            
                            local ranchPos = getPlayerRanchCoords()
                            if ranchPos then
                                slowFlyTo(ranchPos + Vector3.new(0, 15, 0))
                                task.wait(1)
                            end
                        end
                    end
                    
                    if env.auto then
                        hrp = charHRP()
                        if hrp then hrp.CFrame = HALLOWEEN_COORDS; task.wait(0.5) end
                    end
                end
                
                env.suppressDipHook = false
                env.isDipping = false
            end
        end

        if processedEgg then
            task.wait(0.1)
            continue
        end

        -- [1] AUTO EGG MACRO / TARGET EGGS
        if (env.autoFarmEggs or env.autoEggMacro) and #env.targetEggs > 0 then
            local renderedEggs = workspace:FindFirstChild("RenderedEggs")
            
            if renderedEggs then
                for _, egg in ipairs(renderedEggs:GetChildren()) do
                    if env._menuId ~= myId then break end
                    
                    if egg:IsA("Model") and egg.Name ~= "Volcanic Egg" and table.find(env.targetEggs, egg.Name) then
                        processedEgg = true
                        local targetPos = egg:GetPivot().Position
                        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                        
                        if prompt and targetPos then
                            statusLabel.Text = "Status: Loading Terrain for " .. egg.Name
                            
                            local hrp = charHRP()
                            if hrp then 
                                hrp.Anchored = false
                                hrp.CFrame = CFrame.new(FOOD_STALL_COORDS)
                                task.wait(0.4)
                                hrp.CFrame = CFrame.new(VOLCANO_COORDS)
                                task.wait(0.4)
                                
                                hrp.CFrame = CFrame.new(targetPos) 
                                hrp.AssemblyLinearVelocity = Vector3.zero
                            end
                            task.wait(0.5)
                            
                            statusLabel.Text = "Status: Triggering " .. egg.Name
                            triggerPrompt(prompt)
                            
                            local timeout = 0
                            while egg.Parent and timeout < 30 do
                                task.wait(0.1)
                                timeout = timeout + 1
                            end
                            
                            task.wait(0.5)
                            while env.isDipping do task.wait(0.5) end
                            
                            if env.auto then
                                statusLabel.Text = "Status: Returning to Halloween Area"
                                hrp = charHRP()
                                if hrp then hrp.CFrame = HALLOWEEN_COORDS; task.wait(0.5) end
                            end
                        end
                        break 
                    end
                end
            end
            
            if env.autoEggMacro then
                env.autoEggMacro = false
                autoEggMacroBtn.Text = "CLAIM MAP EGG (ONCE)"
                autoEggMacroBtn.BackgroundColor3 = C_BTN_OFF
                if not processedEgg then
                    statusLabel.Text = "Status: Selected Egg(s) not found!"
                    task.wait(2)
                end
            end
        end

        if processedEgg then
            task.wait(0.1)
            continue
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
                    if (env.autoFarmEggs and #env.targetEggs > 0) or env.autoVolcanicEgg then
                        local renderedEggs = workspace:FindFirstChild("RenderedEggs")
                        local shouldBreak = false
                        if renderedEggs then
                            for _, egg in ipairs(renderedEggs:GetChildren()) do
                                if egg:IsA("Model") then
                                    if env.autoVolcanicEgg and egg.Name == "Volcanic Egg" then shouldBreak = true break end
                                    if env.autoFarmEggs and table.find(env.targetEggs, egg.Name) then shouldBreak = true break end
                                end
                            end
                        end
                        if shouldBreak then break end
                    end

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
            if not env.autoFarmEggs and not env.autoEggMacro and not env.autoVolcanicEgg then 
                statusLabel.Text = "Status: Idle." 
            elseif env.autoFarmEggs or env.autoVolcanicEgg then
                statusLabel.Text = "Status: Waiting for target eggs to spawn..."
            end
        end
        
        task.wait(0.1)
    end
end)

env._menuCleanup = function()
    setAuto(false)
    env.autoFarmEggs = false
    env.autoEggMacro = false
    env.autoVolcanicEgg = false
    env.autoBuyEgg = false
    env.espEnabled = false
    if env._espFolder then pcall(function() env._espFolder:Destroy() end) end
    updateFlyingState()
    env._menuId = env._menuId + 1
    screenGui:Destroy()
end

print("[Menu Halloween v26 | Ghost TP Buy & Safe TP] loaded.")
