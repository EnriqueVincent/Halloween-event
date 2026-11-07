--[[=====================================================
    AUTO THROW (+20 MAX POWER) - 3-STEP HANDSHAKE
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

-- The exact starting line coordinates you provided
local THROW_COORDS = CFrame.new(3, 6.325932025909424, -41)

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
    local completeRemote = remotes:WaitForChild("Throw_Complete")
    
    while env._throwId == myId do
        if env.autoThrow then
            local hrp = charHRP()
            if hrp then
                -- 1. Teleport to the exact throw line
                hrp.CFrame = THROW_COORDS
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.5) -- Give the server half a second to register you are standing in the zone
                
                -- We wrap the InvokeServer sequence in a pcall so if the server lags, it doesn't crash the script
                pcall(function()
                    -- 2. Step 1: Tell server we are starting the throw
                    startRemote:InvokeServer()
                    task.wait(0.2)
                    
                    -- 3. Step 2: Hit the perfect +20 multiplier (1.0 = 100% power)
                    resolveRemote:InvokeServer(1)
                    task.wait(0.2)
                    
                    -- 4. Step 3: Tell server the throw animation has finished
                    completeRemote:InvokeServer()
                end)
                
                -- 5. Wait a few seconds for the game to reset your character before throwing again
                task.wait(4)
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

print("Perfect Auto Throw (+20) Handshake Loaded.")
