-- ACE SNIPER x AETHERION — ACE-style interface rebuild
-- Interface-only edition. Controls are visual/local preferences; no game remotes,
-- code submission, purchases, admin actions, exploit APIs, or webhook requests.
-- Built to follow the compact ACE layout: 310px window, 64px header,
-- 34px tab bar, dense 27px rows, Main/Farm/Settings pages.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AceAetherionUI")
if old then old:Destroy() end

local Theme = {
    Window = Color3.fromRGB(15, 15, 19),
    Panel = Color3.fromRGB(20, 20, 26),
    Control = Color3.fromRGB(36, 36, 45),
    Log = Color3.fromRGB(28, 28, 36),
    White = Color3.fromRGB(239, 238, 246),
    Muted = Color3.fromRGB(145, 143, 158),
    Accent = Color3.fromRGB(151, 112, 255),
    AccentDark = Color3.fromRGB(48, 37, 78),
    Green = Color3.fromRGB(92, 205, 145),
    Red = Color3.fromRGB(224, 92, 105),
    Stroke = Color3.fromRGB(72, 68, 86),
}

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function round(obj, px)
    make("UICorner", obj, {CornerRadius = UDim.new(0, px or 7)})
end
local function outline(obj, transparency)
    make("UIStroke", obj, {Color = Theme.Stroke, Transparency = transparency or 0.72, Thickness = 1})
end
local function text(parent, value, size, color, font)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1, Text = value, TextSize = size or 11,
        TextColor3 = color or Theme.White, Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    })
end
local function button(parent, value, size, pos)
    local b = make("TextButton", parent, {
        Size = size, Position = pos, BackgroundColor3 = Theme.Control,
        BorderSizePixel = 0, Text = value, TextColor3 = Theme.White,
        TextSize = 10, Font = Enum.Font.GothamSemibold, AutoButtonColor = false,
    })
    round(b, 6)
    return b
end

local gui = make("ScreenGui", playerGui, {
    Name = "AceAetherionUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local window = make("Frame", gui, {
    Name = "AceWindow", Size = UDim2.fromOffset(310, 446),
    Position = UDim2.new(0.5, -155, 0.5, -223),
    BackgroundColor3 = Theme.Window, BorderSizePixel = 0, ClipsDescendants = true,
})
round(window, 10); outline(window, 0.45)

local header = make("Frame", window, {
    Name = "Header", Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
})
local brand = text(header, "ACE SNIPER", 14, Theme.White, Enum.Font.GothamBold)
brand.Position = UDim2.fromOffset(15, 10); brand.Size = UDim2.fromOffset(170, 22)
local sub = text(header, "AETHERION CONFIG  •  UI EDITION", 8, Theme.Muted, Enum.Font.GothamMedium)
sub.Position = UDim2.fromOffset(16, 32); sub.Size = UDim2.fromOffset(210, 15)
local minimize = button(header, "—", UDim2.fromOffset(23, 23), UDim2.new(1, -61, 0, 17))
local close = button(header, "×", UDim2.fromOffset(23, 23), UDim2.new(1, -31, 0, 17))
minimize.TextSize = 14; close.TextSize = 15
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local tabBar = make("Frame", window, {
    Name = "TabBar", Position = UDim2.fromOffset(0, 60),
    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
})
local pages, tabs = {}, {}
local activeTab = "MAIN"
local content = make("Frame", window, {
    Name = "Content", Position = UDim2.fromOffset(0, 98),
    Size = UDim2.new(1, 0, 1, -116), BackgroundTransparency = 1,
})
local footer = text(window, "READY  •  LOCAL UI", 8, Theme.Muted, Enum.Font.GothamMedium)
footer.Position = UDim2.new(0, 13, 1, -16); footer.Size = UDim2.new(1, -26, 0, 12)

local function page(name)
    local p = make("ScrollingFrame", content, {
        Name = name .. "Page", Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    make("UIPadding", p, {
        PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13),
        PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 12),
    })
    make("UIListLayout", p, {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
    pages[name] = p
    return p
end
local function show(name)
    activeTab = name
    for n, p in pairs(pages) do p.Visible = n == name end
    for n, b in pairs(tabs) do
        local on = n == name
        b.TextColor3 = on and Theme.Accent or Theme.Muted
        b.BackgroundColor3 = on and Theme.AccentDark or Theme.Panel
    end
end
for i, name in ipairs({"MAIN", "FARM", "SETTINGS"}) do
    local b = button(tabBar, name, UDim2.fromOffset(91, 26), UDim2.fromOffset(10 + (i-1)*97, 4))
    b.Name = name .. "Tab"; b.TextSize = 9
    tabs[name] = b
    b.MouseButton1Click:Connect(function() show(name) end)
end

local function section(parent, name, hint)
    local h = make("Frame", parent, {Size = UDim2.new(1, 0, 0, hint and 30 or 22), BackgroundTransparency = 1})
    local t = text(h, name:upper(), 9, Theme.Accent, Enum.Font.GothamBold)
    t.Size = UDim2.new(1, 0, 0, 16)
    if hint then
        local d = text(h, hint, 8, Theme.Muted)
        d.Position = UDim2.fromOffset(0, 14); d.Size = UDim2.new(1, 0, 0, 13)
    end
    return h
end
local function row(parent, height)
    local r = make("Frame", parent, {
        Size = UDim2.new(1, 0, 0, height or 27),
        BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
    })
    round(r, 5)
    return r
end
local function toggle(parent, name, default)
    local r = row(parent, 27)
    local t = text(r, name, 9, Theme.White, Enum.Font.GothamMedium)
    t.Position = UDim2.fromOffset(9, 0); t.Size = UDim2.new(1, -58, 1, 0)
    local sw = make("TextButton", r, {
        Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -38, 0.5, -8),
        BackgroundColor3 = default and Theme.Accent or Theme.Control,
        Text = "", BorderSizePixel = 0, AutoButtonColor = false,
    })
    round(sw, 9)
    local knob = make("Frame", sw, {
        Size = UDim2.fromOffset(12, 12),
        Position = default and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.White, BorderSizePixel = 0,
    })
    round(knob, 8)
    local state = default == true
    local function render()
        TweenService:Create(sw, TweenInfo.new(.15), {
            BackgroundColor3 = state and Theme.Accent or Theme.Control
        }):Play()
        TweenService:Create(knob, TweenInfo.new(.15), {
            Position = state and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2)
        }):Play()
    end
    sw.MouseButton1Click:Connect(function() state = not state; render() end)
    return function() return state end
end
local function choice(parent, name, options, selected)
    local r = row(parent, 34)
    local t = text(r, name, 9, Theme.White, Enum.Font.GothamMedium)
    t.Position = UDim2.fromOffset(9, 0); t.Size = UDim2.new(.43, 0, 1, 0)
    local holder = make("Frame", r, {
        Position = UDim2.new(.43, 0, 0, 4), Size = UDim2.new(.55, 0, 1, -8),
        BackgroundTransparency = 1,
    })
    make("UIListLayout", holder, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Right})
    local selectedValue = selected or options[1]
    for _, opt in ipairs(options) do
        local b = button(holder, tostring(opt), UDim2.new(1/#options, -3, 1, 0), UDim2.new())
        b.TextSize = 8
        local function paint()
            b.BackgroundColor3 = selectedValue == opt and Theme.AccentDark or Theme.Control
            b.TextColor3 = selectedValue == opt and Theme.Accent or Theme.Muted
        end
        paint()
        b.MouseButton1Click:Connect(function()
            selectedValue = opt
            for _, child in ipairs(holder:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = child == b and Theme.AccentDark or Theme.Control
                    child.TextColor3 = child == b and Theme.Accent or Theme.Muted
                end
            end
        end)
    end
    return function() return selectedValue end
end
local function input(parent, name, placeholder)
    local r = row(parent, 43)
    local t = text(r, name, 8, Theme.Muted, Enum.Font.GothamMedium)
    t.Position = UDim2.fromOffset(9, 2); t.Size = UDim2.new(1, -18, 0, 13)
    local box = make("TextBox", r, {
        Position = UDim2.fromOffset(8, 17), Size = UDim2.new(1, -16, 0, 21),
        BackgroundColor3 = Theme.Window, BorderSizePixel = 0,
        Text = "", PlaceholderText = placeholder or "Enter value",
        PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.White,
        TextSize = 9, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
    })
    round(box, 4)
    return box
end
local function info(parent, name, value)
    local r = row(parent, 27)
    local t = text(r, name, 9, Theme.Muted)
    t.Position = UDim2.fromOffset(9, 0); t.Size = UDim2.new(1, -70, 1, 0)
    local v = text(r, value, 9, Theme.Accent, Enum.Font.GothamBold)
    v.Position = UDim2.new(1, -65, 0, 0); v.Size = UDim2.fromOffset(56, 27)
    v.TextXAlignment = Enum.TextXAlignment.Right
end

local main = page("MAIN")
section(main, "Code automation", "Aetherion options · interface preview")
toggle(main, "Auto Redeem", false)
toggle(main, "Auto Part Guesser", false)
toggle(main, "AI Riddle Solver", false)
toggle(main, "Auto Mode", false)
toggle(main, "Parts Mode", false)
choice(main, "Parts Amount", {1,2,3,4,5,6,8,10,12}, 3)
section(main, "Riddle preferences")
toggle(main, "Riddle Before Auto", false)
toggle(main, "AI Riddles Auto Submit", false)
toggle(main, "Backup Riddle Answer", false)
toggle(main, "Learn Facts", false)
choice(main, "Riddle Retry", {"Off","1x","2x"}, "1x")
section(main, "Announcement options")
toggle(main, "Retype Invalid", false)
toggle(main, "Accept Bare Parts", true)
toggle(main, "Accept Sentence Parts", true)
choice(main, "Submit After", {1,2,3,6}, 3)
info(main, "Collected Parts", "0 / 3")
info(main, "Current Status", "IDLE")

local farm = page("FARM")
section(farm, "Farm preferences", "Imported Aetherion settings · visual only")
toggle(farm, "Auto Buy", false)
toggle(farm, "Anti Ragdoll", false)
toggle(farm, "Lock Position", false)
toggle(farm, "FPS Boost", false)
toggle(farm, "Admin Abuse Alerts", false)
choice(farm, "Webhook Detail", {"Code","Reward","Both"}, "Both")
input(farm, "Webhook URL", "Paste webhook URL (not transmitted)")
section(farm, "Retype settings")
choice(farm, "Buffer Limit", {16,32,64,128}, 32)
choice(farm, "Buffer TTL", {30,60,180,300,600}, 180)
info(farm, "Mode", "PREVIEW")

local settings = page("SETTINGS")
section(settings, "General", "ACE-style compact control panel")
toggle(settings, "Remember UI State", true)
toggle(settings, "Compact Layout", true)
toggle(settings, "Show Status Footer", true)
choice(settings, "Accent Color", {"Violet","Blue","Red","Green"}, "Violet")
choice(settings, "UI Scale", {"80%","90%","100%","110%"}, "100%")
info(settings, "Build", "ACE × AETHERION")
info(settings, "Version", "UI 1.0")
local reset = button(settings, "RESET VISUAL SETTINGS", UDim2.new(1, 0, 0, 28), UDim2.new())
reset.BackgroundColor3 = Theme.AccentDark; reset.TextColor3 = Theme.Accent
reset.MouseButton1Click:Connect(function()
    footer.Text = "SETTINGS RESET  •  RELOAD TO RESTORE"
end)

show("MAIN")

-- Minimize to a compact ACE-like title strip.
local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    tabBar.Visible = not minimized
    content.Visible = not minimized
    footer.Visible = not minimized
    TweenService:Create(window, TweenInfo.new(.2, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.fromOffset(310, 60) or UDim2.fromOffset(310, 446)
    }):Play()
    minimize.Text = minimized and "+" or "—"
end)

-- Drag from header; works with mouse and touch.
local dragging, dragStart, startPosition
header.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inputObject.Position
        startPosition = window.Position
        inputObject.Changed:Connect(function()
            if inputObject.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inputObject)
    if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
        local delta = inputObject.Position - dragStart
        window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
