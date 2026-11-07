--[[=====================================================
    SMART POP-UP SCANNER & AUTO CLAIM
=====================================================]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env._smartPopupCleanup then pcall(env._smartPopupCleanup) end
env._smartPopupId = (env._smartPopupId or 0) + 1
local myId = env._smartPopupId

env.autoPopup = false

-- ===================== [ UI SETUP ] =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmartPopupUI"
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

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Cyan Accent
titleLabel.Text = " Auto Pop-Up Bonus"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

-- Bottom flat edge for the title to blend with the frame
local titleBlock = Instance.new("Frame")
titleBlock.Size = UDim2.new(1, 0, 0, 8)
titleBlock.Position = UDim2.new(0, 0, 1, -8)
titleBlock.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
titleBlock.BorderSizePixel = 0
titleBlock.Parent = titleLabel

-- Toggle Button
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
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80) -- Green
    else
        toggleBtn.Text = "AUTO CLAIM: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55) -- Gray
    end
end)

-- ===================== [ SMART UI SCANNER ] =====================
task.spawn(function()
    local remote = RS:WaitForChild("Remotes"):WaitForChild("Training_TapBonus")
    local claimedIds = {} -- Prevents spamming the same ID over and over
    
    while env._smartPopupId == myId do
        if env.autoPopup then
            -- Scan the player's screen for active UI elements
            for _, obj in ipairs(plr.PlayerGui:GetDescendants()) do
                
                -- We only care about visible Buttons or Frames
                if (obj:IsA("ImageButton") or obj:IsA("TextButton") or obj:IsA("Frame")) and obj.Visible then
                    
                    local id = nil
                    
                    -- Method 1: The game names the GUI object after the ID (e.g., "19")
                    if tonumber(obj.Name) then
                        id = tonumber(obj.Name)
                    end
                    
                    -- Method 2: The ID is stored in an attribute or Value inside the object
                    if not id then
                        local val = obj:FindFirstChildWhichIsA("IntValue") or obj:FindFirstChildWhichIsA("NumberValue")
                        if val then id = val.Value end
                    end
                    
                    -- If we found an ID and haven't claimed it recently
                    if id and id > 0 and not claimedIds[id] then
                        claimedIds[id] = true
                        
                        -- Run the claim in the background so it doesn't lag the loop
                        task.spawn(function()
                            pcall(function()
                                remote:InvokeServer(id)
                                -- Instantly hide the popup so it doesn't clutter your screen
                                obj.Visible = false 
                            end)
                        end)
                        
                        -- Forget the ID after 5 seconds so it can be claimed again if it respawns
                        task.delay(5, function()
                            claimedIds[id] = nil
                        end)
                    end
                    
                end
            end
        end
        -- Scans the screen every 0.2 seconds (extremely fast, zero lag)
        task.wait(0.2) 
    end
end)

env._smartPopupCleanup = function()
    env.autoPopup = false
    env._smartPopupId = env._smartPopupId + 1
    screenGui:Destroy()
end

print("Smart Pop-Up Scanner Loaded.")
