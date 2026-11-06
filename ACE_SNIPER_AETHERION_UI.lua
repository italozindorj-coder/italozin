-- ACE SNIPER UI REMAKE — Aetherion options layout
-- UI-only build: controls update their visual state locally.
-- No game remotes, auto-redeem, exploit APIs, admin actions, or webhook requests are connected.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AceSniperRemake")
if old then old:Destroy() end

local C = {
    bg = Color3.fromRGB(10, 11, 15),
    panel = Color3.fromRGB(16, 18, 24),
    panel2 = Color3.fromRGB(22, 24, 32),
    line = Color3.fromRGB(43, 46, 58),
    white = Color3.fromRGB(240, 242, 248),
    muted = Color3.fromRGB(139, 145, 160),
    accent = Color3.fromRGB(111, 91, 255),
    accent2 = Color3.fromRGB(157, 126, 255),
    green = Color3.fromRGB(76, 205, 143),
    red = Color3.fromRGB(235, 92, 108),
}

local gui = Instance.new("ScreenGui")
gui.Name = "AceSniperRemake"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(obj, radius)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, radius or 10)
    u.Parent = obj
end

local function stroke(obj, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.line
    s.Transparency = transparency or 0
    s.Thickness = 1
    s.Parent = obj
end

local function label(parent, text, size, color, font)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = color or C.white
    t.TextSize = size or 13
    t.Font = font or Enum.Font.Gotham
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local window = Instance.new("Frame")
window.Name = "MainWindow"
window.Size = UDim2.fromOffset(720, 490)
window.Position = UDim2.new(0.5, -360, 0.5, -245)
window.BackgroundColor3 = C.bg
window.BorderSizePixel = 0
window.Parent = gui
corner(window, 14)
stroke(window, C.line)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(340, 420)
sizeLimit.MaxSize = Vector2.new(900, 650)
sizeLimit.Parent = window

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 62)
top.BackgroundColor3 = C.panel
top.BorderSizePixel = 0
top.Parent = window
corner(top, 14)

local topMask = Instance.new("Frame")
topMask.Position = UDim2.new(0, 0, 1, -14)
topMask.Size = UDim2.new(1, 0, 0, 14)
topMask.BackgroundColor3 = C.panel
topMask.BorderSizePixel = 0
topMask.Parent = top

local logo = Instance.new("Frame")
logo.Position = UDim2.fromOffset(18, 14)
logo.Size = UDim2.fromOffset(34, 34)
logo.BackgroundColor3 = C.accent
logo.BorderSizePixel = 0
logo.Parent = top
corner(logo, 10)
local logoText = label(logo, "A", 19, Color3.new(1,1,1), Enum.Font.GothamBlack)
logoText.Size = UDim2.fromScale(1,1)
logoText.TextXAlignment = Enum.TextXAlignment.Center

local title = label(top, "ACE SNIPER", 16, C.white, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(62, 10)
title.Size = UDim2.fromOffset(190, 22)
local subtitle = label(top, "CONTROL CENTER  /  UI EDITION", 9, C.muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(63, 33)
subtitle.Size = UDim2.fromOffset(250, 15)

local status = Instance.new("Frame")
status.AnchorPoint = Vector2.new(1, 0.5)
status.Position = UDim2.new(1, -56, 0.5, 0)
status.Size = UDim2.fromOffset(112, 27)
status.BackgroundColor3 = Color3.fromRGB(24, 39, 35)
status.BorderSizePixel = 0
status.Parent = top
corner(status, 20)
local statusDot = Instance.new("Frame")
statusDot.Position = UDim2.fromOffset(10, 10)
statusDot.Size = UDim2.fromOffset(7, 7)
statusDot.BackgroundColor3 = C.green
statusDot.BorderSizePixel = 0
statusDot.Parent = status
corner(statusDot, 9)
local statusText = label(status, "UI READY", 9, C.green, Enum.Font.GothamBold)
statusText.Position = UDim2.fromOffset(24, 0)
statusText.Size = UDim2.new(1, -28, 1, 0)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -38, 0, 17)
close.BackgroundColor3 = C.panel2
close.Text = "×"
close.TextColor3 = C.muted
close.TextSize = 20
close.Font = Enum.Font.Gotham
close.BorderSizePixel = 0
close.Parent = top
corner(close, 8)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local nav = Instance.new("Frame")
nav.Position = UDim2.fromOffset(14, 76)
nav.Size = UDim2.new(0, 150, 1, -90)
nav.BackgroundColor3 = C.panel
nav.BorderSizePixel = 0
nav.Parent = window
corner(nav, 11)
local navPad = Instance.new("UIPadding")
navPad.PaddingTop = UDim.new(0, 12)
navPad.PaddingLeft = UDim.new(0, 9)
navPad.PaddingRight = UDim.new(0, 9)
navPad.Parent = nav
local navList = Instance.new("UIListLayout")
navList.Padding = UDim.new(0, 7)
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Parent = nav

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(178, 76)
content.Size = UDim2.new(1, -192, 1, -90)
content.BackgroundColor3 = C.panel
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.accent
content.CanvasSize = UDim2.new()
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = window
corner(content, 11)
local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 16)
contentPad.PaddingBottom = UDim.new(0, 18)
contentPad.PaddingLeft = UDim.new(0, 16)
contentPad.PaddingRight = UDim.new(0, 16)
contentPad.Parent = content
local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 10)
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Parent = content

local pages, navButtons = {}, {}
local currentPage = nil

local function makePage(name)
    local page = Instance.new("Frame")
    page.Name = name
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, -2, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = content
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page
    pages[name] = page
    return page
end

local function showPage(name)
    currentPage = name
    for pageName, page in pairs(pages) do page.Visible = pageName == name end
    for pageName, button in pairs(navButtons) do
        local active = pageName == name
        button.BackgroundColor3 = active and Color3.fromRGB(42, 36, 77) or C.panel
        button.TextColor3 = active and C.accent2 or C.muted
    end
    content.CanvasPosition = Vector2.new(0, 0)
end

local function addNav(name, order)
    local b = Instance.new("TextButton")
    b.Name = name .. "Tab"
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = C.panel
    b.Text = "   " .. name
    b.TextColor3 = C.muted
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.BorderSizePixel = 0
    b.Parent = nav
    corner(b, 8)
    b.MouseButton1Click:Connect(function() showPage(name) end)
    navButtons[name] = b
end

local function section(parent, name, description)
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.Size = UDim2.new(1, 0, 0, description and 43 or 25)
    wrap.Parent = parent
    local h = label(wrap, name:upper(), 11, C.accent2, Enum.Font.GothamBold)
    h.Size = UDim2.new(1, 0, 0, 18)
    if description then
        local d = label(wrap, description, 10, C.muted)
        d.Position = UDim2.fromOffset(0, 19)
        d.Size = UDim2.new(1, 0, 0, 17)
    end
    return wrap
end

local function rowBase(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 52)
    row.BackgroundColor3 = C.panel2
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 9)
    return row
end

local function toggle(parent, name, description, default)
    local row = rowBase(parent, description and 58 or 48)
    local titleLabel = label(row, name, 12, C.white, Enum.Font.GothamSemibold)
    titleLabel.Position = UDim2.fromOffset(13, description and 8 or 0)
    titleLabel.Size = UDim2.new(1, -78, 0, 20)
    if description then
        local desc = label(row, description, 9, C.muted)
        desc.Position = UDim2.fromOffset(13, 29)
        desc.Size = UDim2.new(1, -80, 0, 15)
    end
    local track = Instance.new("TextButton")
    track.Size = UDim2.fromOffset(38, 21)
    track.Position = UDim2.new(1, -51, 0.5, -10)
    track.BackgroundColor3 = default and C.accent or Color3.fromRGB(54, 57, 68)
    track.Text = ""
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 20)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(15, 15)
    knob.Position = default and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 20)
    local state = default == true
    local function render()
        TweenService:Create(track, TweenInfo.new(0.14), {
            BackgroundColor3 = state and C.accent or Color3.fromRGB(54,57,68)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.14), {
            Position = state and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)
        }):Play()
    end
    track.MouseButton1Click:Connect(function()
        state = not state
        render()
    end)
    return function() return state end
end

local function action(parent, name, caption)
    local row = rowBase(parent, 48)
    local t = label(row, name, 12, C.white, Enum.Font.GothamSemibold)
    t.Position = UDim2.fromOffset(13, 0)
    t.Size = UDim2.new(1, -120, 1, 0)
    local b = Instance.new("TextButton")
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -10, 0.5, 0)
    b.Size = UDim2.fromOffset(94, 29)
    b.BackgroundColor3 = Color3.fromRGB(42, 36, 77)
    b.Text = caption or "OPEN"
    b.TextColor3 = C.accent2
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = row
    corner(b, 7)
    b.MouseButton1Click:Connect(function()
        b.Text = "UI ONLY"
        task.delay(1.1, function() if b.Parent then b.Text = caption or "OPEN" end end)
    end)
end

local function slider(parent, name, min, max, initial)
    local row = rowBase(parent, 65)
    local t = label(row, name, 12, C.white, Enum.Font.GothamSemibold)
    t.Position = UDim2.fromOffset(13, 6)
    t.Size = UDim2.new(1, -80, 0, 20)
    local value = label(row, tostring(initial), 11, C.accent2, Enum.Font.GothamBold)
    value.Position = UDim2.new(1, -48, 0, 6)
    value.Size = UDim2.fromOffset(35, 20)
    value.TextXAlignment = Enum.TextXAlignment.Right
    local bar = Instance.new("TextButton")
    bar.Position = UDim2.fromOffset(13, 39)
    bar.Size = UDim2.new(1, -26, 0, 5)
    bar.BackgroundColor3 = Color3.fromRGB(55, 57, 70)
    bar.Text = ""
    bar.BorderSizePixel = 0
    bar.Parent = row
    corner(bar, 5)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    corner(fill, 5)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((initial-min)/(max-min), 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(12, 12)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    corner(knob, 8)
    local function setFromX(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local n = math.floor(min + (max-min)*pct + 0.5)
        local p = (n-min)/(max-min)
        fill.Size = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,0,0.5,0)
        value.Text = tostring(n)
    end
    bar.MouseButton1Down:Connect(function(x) setFromX(x) end)
    return function() return tonumber(value.Text) end
end

local function textbox(parent, name, placeholder)
    local row = rowBase(parent, 58)
    local t = label(row, name, 11, C.white, Enum.Font.GothamSemibold)
    t.Position = UDim2.fromOffset(12, 5)
    t.Size = UDim2.new(1, -24, 0, 17)
    local box = Instance.new("TextBox")
    box.Position = UDim2.fromOffset(12, 27)
    box.Size = UDim2.new(1, -24, 0, 23)
    box.BackgroundColor3 = C.bg
    box.TextColor3 = C.white
    box.PlaceholderColor3 = C.muted
    box.PlaceholderText = placeholder or "Enter value..."
    box.Text = ""
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = row
    corner(box, 6)
    return box
end

local main = makePage("MAIN")
section(main, "Code controls", "Aetherion control layout · visual preview")
toggle(main, "Auto Redeem", "Enable the code-redeem mode (visual toggle)", false)
toggle(main, "Guess Mode", "Display the guess-mode setting", false)
toggle(main, "Parts Mode", "Collect code parts in sequence", false)
slider(main, "Parts Amount", 1, 12, 3)
toggle(main, "Auto Mode", "Switch between code and riddle modes", false)
section(main, "Announcement tools", "Local interface controls")
action(main, "Retype Announcements", "RETYPE")
action(main, "Clear Collected Parts", "CLEAR")
action(main, "Manual Code Entry", "OPEN")

local riddles = makePage("RIDDLES")
section(riddles, "Riddle solver", "Aetherion riddle preferences · UI only")
toggle(riddles, "Riddle Enabled", "Show the riddle feature setting", false)
toggle(riddles, "Riddle Before Auto", "Prioritize riddles in Auto Mode", false)
toggle(riddles, "Learn Facts", "Remember learned clue information", false)
toggle(riddles, "Backup Answer / Fallback", "Show fallback answer preference", false)
slider(riddles, "Fallback Delay", 0, 100, 55)
action(riddles, "Riddle Answer", "VIEW")
action(riddles, "Riddle History", "OPEN")

local performance = makePage("PERFORMANCE")
section(performance, "Performance", "Client-side preference controls")
toggle(performance, "FPS Boost", "Display the FPS boost preference", false)
action(performance, "Performance Status", "CHECK")

local extra = makePage("EXTRA")
section(extra, "Admin Abuse options", "Imported as visual settings only — no game actions")
toggle(extra, "Auto Buy", "UI preference only; not connected to purchases", false)
toggle(extra, "Anti Ragdoll", "UI preference only; no character manipulation", false)
toggle(extra, "Lock Position", "UI preference only; no movement control", false)
section(extra, "Webhook & history", "Sensitive values are not prefilled or transmitted")
toggle(extra, "Webhook Enabled", "Visual preference only; no network requests", false)
textbox(extra, "Webhook URL", "Paste URL locally (not sent anywhere)")
action(extra, "Webhook Detail", "SELECT")
slider(extra, "Retype Buffer Limit", 1, 128, 32)
slider(extra, "Retype Buffer TTL", 1, 600, 180)

local settings = makePage("SETTINGS")
section(settings, "General settings", "Local interface preferences")
toggle(settings, "Remember UI State", "Keep the current visual settings while this UI is open", true)
toggle(settings, "Compact Mode", "Visual preference placeholder", false)
toggle(settings, "Show Status Indicator", "Display the UI READY indicator", true)
action(settings, "Reset UI Preferences", "RESET")
action(settings, "Unload Interface", "UNLOAD")

for i, name in ipairs({"MAIN", "RIDDLES", "PERFORMANCE", "EXTRA", "SETTINGS"}) do
    addNav(name, i)
end
showPage("MAIN")

-- Dragging support
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Keep unload/reset actions safe and local.
for _, obj in ipairs(content:GetDescendants()) do
    if obj:IsA("TextButton") and (obj.Text == "RESET" or obj.Text == "UNLOAD") then
        obj.MouseButton1Click:Connect(function()
            if obj.Text == "UNLOAD" then gui:Destroy() end
        end)
    end
end
