local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local sounds = {
    -- 14 Loud Memes, Cartoon Screams & Chaos Effects
    {name = "Metal Pipe Falling", id = 6729922069, category = "Meme"},
    {name = "Flapjack Scream", id = 115363025942222, category = "Meme"},
    {name = "TORNADOS FAVORITE", id = 105075685614415, category = "Chaotic"},
    {name = "Tom & Jerry Scream", id = 130768299, category = "Meme"},
    {name = "Wilhelm Scream", id = 130833677, category = "Meme"},
    {name = "Goofy Yell", id = 131060205, category = "Meme"},
    {name = "Vine Boom", id = 5153845327, category = "Meme"},
    {name = "Very Loud Bomb", id = 131801546383853, category = "Meme"},
    {name = "ENRIQUE (Loud)", id = 129084748747846, category = "Meme"},
    {name = "Loud Microwave", id = 4575953237, category = "Meme"},
    {name = "Emotional Damage", id = 8362816791, category = "Meme"},
    {name = "MLG Air Horn", id = 9120386436, category = "Meme"},
    {name = "Bruh Sound Effect", id = 5986471213, category = "Meme"},
    {name = "Windows XP Error", id = 1626996526, category = "Meme"},
    {name = "Taco Bell Bong", id = 4810729995, category = "Meme"},
    -- 10 Loud Jumpscares & Horror Stingers
    {name = "Loud Jumpscare", id = 8819324666, category = "Scary"},
    {name = "Horror Jumpscare 2", id = 6754147732, category = "Scary"},
    {name = "Blood Curdling Scream", id = 132560717714270, category = "Scary"},
    {name = "DOORS Entity Close", id = 5993515228, category = "Scary"},
    {name = "DOORS Far Screech", id = 9072301639, category = "Scary"},
    {name = "FNAF Jumpscare", id = 130855606, category = "Scary"},
    {name = "I Will Kill You", id = 408554237, category = "Scary"},
    {name = "Scream Cream", id = 1835335562, category = "Scary"},
    {name = "Night Owl Stalker", id = 1843391637, category = "Scary"},
    {name = "Left For Dead", id = 1835370806, category = "Scary"}
}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrookhavenFESoundboard24"
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then
    screenGui.Parent = PlayerGui
end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 320, 0, 480)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, -70, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.Text = "  Brookhaven FE Soundboard (24)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 35, 0, 35)
minBtn.Position = UDim2.new(1, -70, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -16, 0, 22)
statusLabel.Position = UDim2.new(0, 8, 0, 38)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
statusLabel.Text = "Ready - Click any sound or enter ID"
statusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11

-- Custom Sound ID Box + Play Button
local customBox = Instance.new("TextBox", mainFrame)
customBox.Size = UDim2.new(1, -96, 0, 28)
customBox.Position = UDim2.new(0, 8, 0, 64)
customBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
customBox.PlaceholderText = "Enter Custom Sound ID..."
customBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 175)
customBox.Text = ""
customBox.TextColor3 = Color3.fromRGB(255, 255, 255)
customBox.Font = Enum.Font.Gotham
customBox.TextSize = 12
customBox.ClearTextOnFocus = false

local customPlayBtn = Instance.new("TextButton", mainFrame)
customPlayBtn.Size = UDim2.new(0, 74, 0, 28)
customPlayBtn.Position = UDim2.new(1, -82, 0, 64)
customPlayBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 90)
customPlayBtn.Text = "PLAY ID"
customPlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
customPlayBtn.Font = Enum.Font.GothamBold
customPlayBtn.TextSize = 12

local stopBtn = Instance.new("TextButton", mainFrame)
stopBtn.Size = UDim2.new(1, -16, 0, 28)
stopBtn.Position = UDim2.new(0, 8, 0, 96)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
stopBtn.Text = "STOP ALL SOUNDS"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12

local currentLocalSound = nil

local function stopAllSounds()
    if currentLocalSound then
        currentLocalSound:Stop()
        currentLocalSound:Destroy()
        currentLocalSound = nil
    end
    for _, v in ipairs(PlayerGui:GetChildren()) do
        if v:IsA("Sound") and v.Name == "BHSoundboardAudio" then
            v:Stop()
            v:Destroy()
        end
    end
    statusLabel.Text = "Stopped audio"
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
end

stopBtn.MouseButton1Click:Connect(stopAllSounds)
closeBtn.MouseButton1Click:Connect(function()
    stopAllSounds()
    screenGui:Destroy()
end)

local function playSound(soundName, soundId)
    local numericId = tonumber(tostring(soundId):match("%d+"))
    if not numericId then
        statusLabel.Text = "Error: Invalid Sound ID"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    stopAllSounds()

    -- 1. Local playback so YOU hear it
    local s = Instance.new("Sound")
    s.Name = "BHSoundboardAudio"
    s.SoundId = "rbxassetid://" .. tostring(numericId)
    s.Volume = 3
    s.Parent = PlayerGui
    s:Play()
    currentLocalSound = s
    s.Ended:Connect(function()
        if currentLocalSound == s then
            currentLocalSound = nil
        end
        s:Destroy()
    end)

    -- 2. FE remote broadcast so OTHERS hear it
    local ok = pcall(function()
        local reFolder = ReplicatedStorage:FindFirstChild("RE")
        local soundRemote = reFolder and reFolder:FindFirstChild("1Gu1nSound1s")
        if soundRemote and soundRemote:IsA("RemoteEvent") then
            soundRemote:FireServer(workspace, numericId, 1)
            statusLabel.Text = "Playing (FE + Local): " .. soundName
            statusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
        else
            statusLabel.Text = "Playing (Local Only): " .. soundName
            statusLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        end
    end)
    if not ok then
        statusLabel.Text = "Playing (Local Only): " .. soundName
        statusLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
    end
end

customPlayBtn.MouseButton1Click:Connect(function()
    if customBox.Text ~= "" then
        playSound("Custom ID (" .. customBox.Text .. ")", customBox.Text)
    end
end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -16, 1, -136)
scroll.Position = UDim2.new(0, 8, 0, 130)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #sounds * 38)
scroll.ScrollBarThickness = 6

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)

for _, item in ipairs(sounds) do
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = item.category == "Meme" and Color3.fromRGB(45, 110, 180) or Color3.fromRGB(140, 40, 50)
    btn.Text = "[" .. item.category .. "] " .. item.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13

    btn.MouseButton1Click:Connect(function()
        playSound(item.name, item.id)
    end)
end

-- Minimize / Expand Logic
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 320, 0, 35)
        statusLabel.Visible = false
        customBox.Visible = false
        customPlayBtn.Visible = false
        stopBtn.Visible = false
        scroll.Visible = false
        minBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 320, 0, 480)
        statusLabel.Visible = true
        customBox.Visible = true
        customPlayBtn.Visible = true
        stopBtn.Visible = true
        scroll.Visible = true
        minBtn.Text = "-"
    end
end)
