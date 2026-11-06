-- ACE SNIPER UI | AETHERION OPTIONS (UI ONLY)
-- Esta versao altera somente a interface. Os toggles sao visuais e ainda nao executam funcoes do Aetherion.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PG = Player:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("AceCodeSniper")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "AceCodeSniper"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PG

local BLACK = Color3.fromRGB(5,5,6)
local PANEL = Color3.fromRGB(9,9,11)
local ROW = Color3.fromRGB(12,12,15)
local BORDER = Color3.fromRGB(45,45,50)
local TEXT = Color3.fromRGB(235,235,238)
local MUTED = Color3.fromRGB(160,160,165)
local RED = Color3.fromRGB(255,55,55)
local GREEN = Color3.fromRGB(105,220,135)

local function Corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
    return c
end

local function Stroke(object)
    local s = Instance.new("UIStroke")
    s.Color = BORDER
    s.Thickness = 1
    s.Transparency = 0.15
    s.Parent = object
    return s
end

local function Label(parent, value, size, bold)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextColor3 = TEXT
    t.TextSize = size
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local function MakeButton(parent, value, size, position)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = ROW
    b.BorderSizePixel = 0
    b.Text = value
    b.TextColor3 = TEXT
    b.TextSize = 8
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = parent
    Corner(b, 6)
    Stroke(b)
    return b
end

-- Main window (single ACE-style window; no blur or dark overlay)
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.fromOffset(275, 430)
Window.Position = UDim2.new(0.5, -137, 0.5, -215)
Window.BackgroundColor3 = BLACK
Window.BorderSizePixel = 0
Window.Parent = Gui
Corner(Window, 14)
Stroke(Window)

-- Dragging
local dragging, dragStart, startPos = false, nil, nil
local DragBar = Instance.new("Frame")
DragBar.BackgroundTransparency = 1
DragBar.Size = UDim2.new(1, -90, 0, 38)
DragBar.Position = UDim2.fromOffset(5, 2)
DragBar.Parent = Window
DragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Window.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, -18, 0, 31)
Header.Position = UDim2.fromOffset(9, 5)
Header.BackgroundTransparency = 1
Header.Parent = Window
local Logo = Label(Header, "♤", 17, true)
Logo.Size = UDim2.fromOffset(23, 31)
local Title = Label(Header, "ACE CODE SNIPER", 10, true)
Title.Position = UDim2.fromOffset(25, 0)
Title.Size = UDim2.fromOffset(105, 31)
local Telemetry = Label(Header, "FPS --  |  PING --ms", 7, true)
Telemetry.Position = UDim2.fromOffset(127, 0)
Telemetry.Size = UDim2.fromOffset(82, 31)
Telemetry.TextColor3 = MUTED

local Min = MakeButton(Header, "−", UDim2.fromOffset(23, 22), UDim2.new(1, -53, 0, 4))
Min.TextSize = 14
local Close = MakeButton(Header, "×", UDim2.fromOffset(23, 22), UDim2.new(1, -26, 0, 4))
Close.TextSize = 14

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, -18, 0, 1)
HeaderLine.Position = UDim2.fromOffset(9, 41)
HeaderLine.BackgroundColor3 = BORDER
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Window

-- Tab strip
local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, -18, 0, 48)
Tabs.Position = UDim2.fromOffset(9, 48)
Tabs.BackgroundColor3 = PANEL
Tabs.BorderSizePixel = 0
Tabs.Parent = Window
Corner(Tabs, 8)
Stroke(Tabs)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -18, 1, -112)
Content.Position = UDim2.fromOffset(9, 102)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = MUTED
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Window
local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 5)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local function ClearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child ~= ContentLayout then child:Destroy() end
    end
end

local function Section(title)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, -2, 0, 19)
    wrap.BackgroundTransparency = 1
    wrap.Parent = Content
    local t = Label(wrap, "—  " .. title, 8, true)
    t.Size = UDim2.new(0, 90, 1, 0)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -98, 0, 1)
    line.Position = UDim2.new(0, 98, 0.5, 0)
    line.BackgroundColor3 = BORDER
    line.BorderSizePixel = 0
    line.Parent = wrap
end

local function Info(value, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, 27)
    row.BackgroundColor3 = PANEL
    row.BorderSizePixel = 0
    row.Parent = Content
    Corner(row, 7)
    Stroke(row)
    local t = Label(row, value, 8, false)
    t.Position = UDim2.fromOffset(9, 0)
    t.Size = UDim2.new(1, -18, 1, 0)
    t.TextColor3 = color or MUTED
end

local function Toggle(value, default)
    local enabled = default or false
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, 29)
    row.BackgroundColor3 = ROW
    row.BorderSizePixel = 0
    row.Parent = Content
    Corner(row, 7)
    Stroke(row)
    local txt = Label(row, value, 7.5, false)
    txt.Position = UDim2.fromOffset(9, 0)
    txt.Size = UDim2.new(1, -58, 1, 0)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(32, 18)
    button.Position = UDim2.new(1, -40, 0.5, -9)
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = row
    Corner(button, 20)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Parent = button
    Corner(knob, 20)
    local function update()
        button.BackgroundColor3 = enabled and Color3.fromRGB(245,245,245) or Color3.fromRGB(38,38,43)
        knob.BackgroundColor3 = enabled and Color3.fromRGB(5,5,5) or Color3.fromRGB(235,235,235)
        knob.Position = enabled and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2)
    end
    update()
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        update()
    end)
end

local function PageClear()
    ClearContent()
    Section("CLEAR")
    Toggle("Clear current feed", false)
    Toggle("Clear captured codes", false)
    Info("UI preview only — no game action connected")
end

local function PageSender()
    ClearContent()
    Section("SENDER")
    Toggle("Require Sammy as sender", true)
    Toggle("Listen for Sammy's code", false)
    Info("WAITING FOR SAMMY", RED)
    Info("Status display only")
end

local function PageFPS()
    ClearContent()
    Section("FPS BOOST")
    Toggle("Enable FPS boost", false)
    Toggle("Reduce visual effects", false)
    Toggle("Low graphics mode", false)
    Info("These controls are visual placeholders")
end

local function PageRiddle()
    ClearContent()
    Section("CODES")
    Toggle("Auto Redeem", false)
    Toggle("Auto Part Guesser", false)
    Toggle("Auto Mode", false)
    Toggle("Parts Mode", false)
    Section("RIDDLES")
    Toggle("AI Riddle Solver", false)
    Toggle("Riddle Database", true)
    Toggle("Auto Submit", false)
end

local function PageRetype()
    ClearContent()
    Section("RETYPE")
    Toggle("Retype invalid codes", false)
    Toggle("Retype announcements", false)
    Toggle("Replay last announcement", false)
    Info("Retype controls — UI preview only")
end

local function PageAdmin()
    ClearContent()
    Section("ADMIN")
    Toggle("Auto Buy", false)
    Toggle("Anti Ragdoll", false)
    Toggle("Lock Position", false)
    Info("Admin options — UI preview only")
end

local pages = {
    {name="CLEAR", fn=PageClear},
    {name="SENDER", fn=PageSender},
    {name="FPS BOOST", fn=PageFPS},
    {name="RIDDLE", fn=PageRiddle},
    {name="RETYPE", fn=PageRetype},
    {name="ADMIN", fn=PageAdmin},
}
local tabButtons = {}
for i, page in ipairs(pages) do
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    local b = MakeButton(Tabs, page.name, UDim2.fromOffset(80, 19), UDim2.fromOffset(3 + col * 84, 4 + row * 22))
    b.TextSize = 7
    tabButtons[i] = b
    b.MouseButton1Click:Connect(function()
        for j, other in ipairs(tabButtons) do
            other.BackgroundColor3 = (i == j) and Color3.fromRGB(27,27,31) or ROW
        end
        page.fn()
    end)
end

-- Minimize and floating OPEN control
local minimized = false
local function setMinimized(state)
    minimized = state
    Tabs.Visible = not state
    Content.Visible = not state
    Window.Size = state and UDim2.fromOffset(275, 52) or UDim2.fromOffset(275, 430)
end
Min.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

local Open = MakeButton(Gui, "OPEN", UDim2.fromOffset(64, 27), UDim2.new(0, 14, 0.5, -13))
Open.Visible = false
Open.BackgroundColor3 = BLACK
Open.MouseButton1Click:Connect(function()
    Window.Visible = true
    Open.Visible = false
    setMinimized(false)
end)
Close.MouseButton1Click:Connect(function()
    Window.Visible = false
    Open.Visible = true
end)

-- Live FPS / ping display
local frames, elapsed, fps = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt
    if elapsed >= 0.5 then
        fps = math.floor(frames / elapsed + 0.5)
        frames, elapsed = 0, 0
        local ping = "--"
        pcall(function()
            ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5))
        end)
        Telemetry.Text = string.format("FPS %d | PING %sms", fps, ping)
    end
end)

-- Initial page
for i, b in ipairs(tabButtons) do
    b.BackgroundColor3 = (i == 1) and Color3.fromRGB(27,27,31) or ROW
end
PageClear()
