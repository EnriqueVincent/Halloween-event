--[[=====================================================
    AUTO THROW (+20 MAX) - LEGIT CINEMATIC SYNC
=====================================================]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env._throwCleanup then pcall(env._throwCleanup) end
env._throwId = (env._throwId or 0) + 1
local myId = env._throwId

env.autoThrow = false

local function charHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ===================== [ UI SETUP ] =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoThrowUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(240, 130) -- Expanded to fit Status text
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
titleLabel.Text = " Perfect Throw (+20)"
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
toggleBtn.Size = UDim2.new(1, -24, 0, 46)
toggleBtn.Position = UDim2.new(0, 12, 0, 48)
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
statusLabel.Position = UDim2.new(0, 12, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Text = "Status: Idle"
statusLabel.Parent = mainFrame

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

-- ===================== [ AUTO THROW LOGIC ] =====================
task.spawn(function()
    local remotes = RS:WaitForChild("Remotes")
    local startRemote = remotes:WaitForChild("Throw_Start")
    local resolveRemote = remotes:WaitForChild("Throw_Resolve")
    
    while env._throwId == myId do
        if env.autoThrow then
            local hrp = charHRP()
            if hrp then
                -- 1. Tell game we are starting. The game will naturally move your character to the line.
                statusLabel.Text = "Status: Readying Throw..."
                task.spawn(function() pcall(function() startRemote:InvokeServer() end) end)
                
                -- Wait for the client to fully transition the camera and display the +20 meter
                task.wait(2.0) 
                if not env.autoThrow then break end
                
                -- 2. Hit the perfect +20 multiplier (1.0 = 100% power)
                statusLabel.Text = "Status: Hitting MAX (+20)..."
                task.spawn(function() pcall(function() resolveRemote:InvokeServer(1) end) end)
                
                -- 3. Wait for the natural cinematic to play out. 
                -- We let the game's native LocalScripts fire 'Throw_Complete' when the item hits the ground.
                statusLabel.Text = "Status: Waiting for landing..."
                task.wait(7.0)
            end
        else
            statusLabel.Text = "Status: Idle"
            task.wait(0.2)
        end
    end
end)

env._throwCleanup = function()
    env.autoThrow = false
    env._throwId = env._throwId + 1
    screenGui:Destroy()
end

print("Perfect Auto Throw (+20) Legit Sync Loaded.")
