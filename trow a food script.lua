--[[=====================================================
    PHASE 2: NATURAL WALK, TAP TO THROW, & SYNCED TIMING
=====================================================]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env._throwCleanup then pcall(env._throwCleanup) end
env._throwId = (env._throwId or 0) + 1
local myId = env._throwId

env.autoThrow = false

-- The exact starting line coordinates
local TARGET_POS = Vector3.new(3, 6.325932025909424, -41)

-- ===================== [ UI SETUP (FORCE PROTECTED) ] =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoThrowUI_Phase2"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999999 -- Forces it above cinematic black bars
screenGui.IgnoreGuiInset = true

-- Places UI in protected CoreGui if executor supports it
local get_hui = gethui or function() return plr:WaitForChild("PlayerGui") end
screenGui.Parent = get_hui()

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(240, 110)
mainFrame.Position = UDim2.new(0.5, -120, 0.7, -120)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
titleLabel.Text = " Perfect Walk & Throw"
titleLabel.TextColor3 = Color3.new(0, 0, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

local titleBlock = Instance.new("Frame")
titleBlock.Size = UDim2.new(1, 0, 0, 8)
titleBlock.Position = UDim2.new(0, 0, 1, -8)
titleBlock.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
titleBlock.BorderSizePixel = 0
titleBlock.Parent = titleLabel

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -24, 0, 40)
toggleBtn.Position = UDim2.new(0, 12, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
toggleBtn.Text = "AUTO THROW: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 20)
statusLabel.Position = UDim2.new(0, 12, 1, -22)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Text = "Status: Idle"
statusLabel.Parent = mainFrame

-- ===================== [ UI FORCE-LOCK LOOP ] =====================
RunService.RenderStepped:Connect(function()
    if env._throwId == myId then
        if screenGui and not screenGui.Enabled then screenGui.Enabled = true end
        if mainFrame and not mainFrame.Visible then mainFrame.Visible = true end
    end
end)

-- ===================== [ BUTTON LOGIC ] =====================
toggleBtn.MouseButton1Click:Connect(function()
    env.autoThrow = not env.autoThrow
    if env.autoThrow then
        toggleBtn.Text = "AUTO THROW: ON"
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    else
        toggleBtn.Text = "AUTO THROW: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        statusLabel.Text = "Status: Idle"
        
        -- Stop moving if canceled
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end
end)

-- ===================== [ ANTI-AFK SYSTEM ] =====================
plr.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local idleSeconds = 0
UIS.InputBegan:Connect(function() idleSeconds = 0 end)
UIS.InputChanged:Connect(function() idleSeconds = 0 end)

task.spawn(function()
    while env._throwId == myId do
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

-- ===================== [ PHYSICAL SCREEN TAP HELPER ] =====================
local function simulateScreenTap()
    local cam = workspace.CurrentCamera
    if cam then
        local midX, midY = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
        VirtualUser:Button1Down(Vector2.new(midX, midY))
        task.wait(0.1)
        VirtualUser:Button1Up(Vector2.new(midX, midY))
    end
end

-- ===================== [ SMART WALK & THROW LOOP ] =====================
task.spawn(function()
    local remotes = RS:WaitForChild("Remotes")
    local startRemote = remotes:WaitForChild("Throw_Start")
    local resolveRemote = remotes:WaitForChild("Throw_Resolve")
    local completeRemote = remotes:WaitForChild("Throw_Complete")

    while env._throwId == myId do
        if env.autoThrow then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and hrp then
                -- Check distance to the throwing line (ignoring height)
                local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(TARGET_POS.X, 0, TARGET_POS.Z)).Magnitude
                
                if dist > 3 then
                    -- If we are far away, walk to the line
                    statusLabel.Text = "Status: Walking to line..."
                    hum:MoveTo(TARGET_POS)
                    task.wait(0.2)
                else
                    -- We are on the line, execute the throw!
                    hum:MoveTo(hrp.Position) -- Stop walking
                    
                    -- Step 1: Start Throw
                    statusLabel.Text = "Status: Readying Throw..."
                    task.spawn(function() pcall(function() startRemote:InvokeServer() end) end)
                    
                    -- INCREASED WAIT: Wait for the cinematic meter to pop up and settle
                    task.wait(2.5) 
                    
                    if not env.autoThrow then break end
                    
                    -- Force a physical screen tap to trigger the animation
                    simulateScreenTap()
                    task.wait(0.5)
                    
                    -- Step 2: Resolve with 1.0 (100% Power / +20)
                    statusLabel.Text = "Status: Hitting MAX (+20)..."
                    task.spawn(function() pcall(function() resolveRemote:InvokeServer(1) end) end)
                    
                    -- INCREASED WAIT: Wait for the food to fly through the air and land
                    -- If your throws are very far, you may need to increase this 5.5 to 7.0 or higher.
                    task.wait(5.5) 
                    
                    if not env.autoThrow then break end
                    
                    -- Step 3: Complete the throw (this resets your character/cinematic)
                    statusLabel.Text = "Status: Completing throw..."
                    task.spawn(function() pcall(function() completeRemote:InvokeServer() end) end)
                    
                    -- INCREASED WAIT: Wait for the game to fully respawn/reset your character before looping
                    task.wait(3.0) 
                end
            end
        else
            task.wait(0.2)
        end
    end
end)

env._throwCleanup = function()
    env.autoThrow = false
    env._throwId = env._throwId + 1
    screenGui:Destroy()
end

print("Phase 2: Natural Walk, Physical Tap, & Synced Timing Loaded.")
