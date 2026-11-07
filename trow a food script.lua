--[[=====================================================
    AUTO POP-UP BONUS (Optimized & Lag-Free)
=====================================================]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env._popupCleanup then pcall(env._popupCleanup) end
env._popupId = (env._popupId or 0) + 1
local myId = env._popupId

env.autoPopup = false

-- ===================== [ UI SETUP ] =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoPopupUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(240, 110)
mainFrame.Position = UDim2.new(0.5, -120, 0.8, -120)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
titleLabel.Text = " Auto Pop-Up Bonus"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

local titleBlock = Instance.new("Frame")
titleBlock.Size = UDim2.new(1, 0, 0, 8)
titleBlock.Position = UDim2.new(0, 0, 1, -8)
titleBlock.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
titleBlock.BorderSizePixel = 0
titleBlock.Parent = titleLabel

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -24, 0, 46)
toggleBtn.Position = UDim2.new(0, 12, 0, 48)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
toggleBtn.Text = "AUTO CLAIM: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- ===================== [ BUTTON LOGIC ] =====================
toggleBtn.MouseButton1Click:Connect(function()
    env.autoPopup = not env.autoPopup
    if env.autoPopup then
        toggleBtn.Text = "AUTO CLAIM: ON"
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    else
        toggleBtn.Text = "AUTO CLAIM: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

-- ===================== [ PHYSICAL UI CLICKER ] =====================
local function forceClickButton(btn)
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    elseif getconnections then
        pcall(function()
            for _, connection in pairs(getconnections(btn.MouseButton1Click)) do connection:Fire() end
            for _, connection in pairs(getconnections(btn.Activated)) do connection:Fire() end
        end)
    end
end

local function checkAndClick(obj)
    if obj:IsA("ImageButton") or obj:IsA("TextButton") then
        local name = string.lower(obj.Name)
        local isTarget = false
        
        if obj:FindFirstAncestorOfClass("BillboardGui") then
            isTarget = true
        end
        
        if name:find("bonus") or name:find("tap") or name:find("popup") then
            isTarget = true
        end
        
        if isTarget and obj.Visible then
            forceClickButton(obj)
            pcall(function() obj.Visible = false end)
        end
    end
end

-- Scan currently existing buttons once
for _, area in ipairs({plr:WaitForChild("PlayerGui"), workspace}) do
    for _, obj in ipairs(area:GetDescendants()) do
        checkAndClick(obj)
    end
end

-- Event-based listener (Zero Lag): Only checks items exactly when they are created
local connections = {}
table.insert(connections, workspace.DescendantAdded:Connect(function(obj)
    if env.autoPopup then checkAndClick(obj) end
end))
table.insert(connections, plr.PlayerGui.DescendantAdded:Connect(function(obj)
    if env.autoPopup then checkAndClick(obj) end
end))

-- ===================== [ DEEP REMOTE SWEEPER ] =====================
task.spawn(function()
    local remote = RS:WaitForChild("Remotes"):WaitForChild("Training_TapBonus")
    local sweepId = 1
    
    while env._popupId == myId do
        if env.autoPopup then
            -- Reduced to 10 IDs per second to prevent network lag/ping spikes
            for i = sweepId, sweepId + 10 do
                task.spawn(function()
                    pcall(function() remote:InvokeServer(i) end)
                end)
            end
            
            sweepId = sweepId + 10
            if sweepId > 5000 then sweepId = 1 end 
        end
        task.wait(1) -- Heavy throttle added here
    end
end)

env._popupCleanup = function()
    env.autoPopup = false
    env._popupId = env._popupId + 1
    for _, conn in ipairs(connections) do conn:Disconnect() end
    screenGui:Destroy()
end

print("Optimized Auto Pop-Up Bonus Loaded.")
