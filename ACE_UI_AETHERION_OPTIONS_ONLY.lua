-- ACE SNIPER UI SHELL + AETHERION CONTROLS
-- Rebuilt from the supplied ACE visual reference and Aetherion option names.
-- ACE gameplay actions/buttons are removed. This is a UI-only shell:
-- controls change their local visual state and do not run game automation.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("AceAetherionShell")
if old then old:Destroy() end

local T = {
    black = Color3.fromRGB(7,7,10), panel = Color3.fromRGB(13,13,18),
    row = Color3.fromRGB(20,20,27), row2 = Color3.fromRGB(27,27,36),
    white = Color3.fromRGB(242,241,247), muted = Color3.fromRGB(151,149,163),
    dim = Color3.fromRGB(91,89,103), purple = Color3.fromRGB(157,117,255),
    purpleDark = Color3.fromRGB(47,35,77), border = Color3.fromRGB(74,68,91),
    green = Color3.fromRGB(100,215,153)
}
local function make(class,parent,props)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function round(o,r) make("UICorner",o,{CornerRadius=UDim.new(0,r or 8)}) end
local function outline(o,a)
    make("UIStroke",o,{Color=T.border,Transparency=a or .68,Thickness=1})
end
local function label(parent,value,size,color,font)
    return make("TextLabel",parent,{
        BackgroundTransparency=1,Text=value,TextSize=size or 10,
        TextColor3=color or T.white,Font=font or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center
    })
end
local function btn(parent,value,size,pos)
    local b=make("TextButton",parent,{
        Text=value,Size=size,Position=pos,BackgroundColor3=T.row2,
        TextColor3=T.white,TextSize=9,Font=Enum.Font.GothamMedium,
        BorderSizePixel=0,AutoButtonColor=false
    })
    round(b,7)
    return b
end

local gui=make("ScreenGui",guiParent,{
    Name="AceAetherionShell",ResetOnSpawn=false,IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling
})
local WIDTH, HEIGHT = 354, 500
local shell=make("Frame",gui,{
    Name="ACEWindow",Size=UDim2.fromOffset(WIDTH,HEIGHT),
    Position=UDim2.new(1,-WIDTH-18,0,18),BackgroundColor3=T.black,
    BackgroundTransparency=.035,BorderSizePixel=0,ClipsDescendants=true
})
round(shell,17); outline(shell,.35)

-- ACE-like compact header with the original collapse/close behavior.
local header=make("Frame",shell,{
    Name="Header",Size=UDim2.new(1,0,0,54),
    BackgroundColor3=T.panel,BorderSizePixel=0,Active=true
})
local logo=make("Frame",header,{
    Position=UDim2.fromOffset(12,11),Size=UDim2.fromOffset(31,31),
    BackgroundColor3=T.row2,BorderSizePixel=0
})
round(logo,16)
label(logo,"A",16,T.purple,Enum.Font.GothamBold).Size=UDim2.fromScale(1,1)
local heading=label(header,"ACE CODE SNIPER",12,T.white,Enum.Font.GothamBold)
heading.Position=UDim2.fromOffset(52,7); heading.Size=UDim2.new(1,-135,0,21)
local sub=label(header,"AETHERION  •  CONTROL PANEL",7,T.dim,Enum.Font.GothamMedium)
sub.Position=UDim2.fromOffset(53,28); sub.Size=UDim2.new(1,-135,0,14)
local menu=btn(header,"☰",UDim2.fromOffset(28,27),UDim2.new(1,-94,.5,-13.5))
local collapse=btn(header,"−",UDim2.fromOffset(26,27),UDim2.new(1,-62,.5,-13.5))
local close=btn(header,"×",UDim2.fromOffset(26,27),UDim2.new(1,-31,.5,-13.5))
menu.TextSize=14; collapse.TextSize=15; close.TextSize=15
close.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Expandable ACE-style side navigation.
local sidebar=make("Frame",shell,{
    Name="SideBar",Position=UDim2.fromOffset(10,62),
    Size=UDim2.fromOffset(104,HEIGHT-91),BackgroundColor3=T.panel,
    BorderSizePixel=0,ClipsDescendants=true
})
round(sidebar,11); outline(sidebar,.82)
local sideTitle=label(sidebar,"AETHERION",8,T.purple,Enum.Font.GothamBold)
sideTitle.Position=UDim2.fromOffset(12,12); sideTitle.Size=UDim2.new(1,-20,0,18)
local sideHint=label(sidebar,"PAGES",7,T.dim,Enum.Font.GothamBold)
sideHint.Position=UDim2.fromOffset(12,31); sideHint.Size=UDim2.new(1,-20,0,14)

local content=make("Frame",shell,{
    Name="PageContent",Position=UDim2.fromOffset(124,62),
    Size=UDim2.new(1,-134,1,-91),BackgroundTransparency=1
})
local status=label(shell,"●  READY  •  UI MODE",7,T.green,Enum.Font.GothamBold)
status.Position=UDim2.new(0,13,1,-19); status.Size=UDim2.new(1,-26,0,12)

local pages,navButtons={},{}
local activePage="CODES"
local function makePage(name)
    local p=make("ScrollingFrame",content,{
        Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=T.purple,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false
    })
    make("UIPadding",p,{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,8),PaddingRight=UDim.new(0,4)})
    make("UIListLayout",p,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
    pages[name]=p
    return p
end
local function show(name)
    activePage=name
    for n,p in pairs(pages) do p.Visible=(n==name) end
    for n,b in pairs(navButtons) do
        local on=n==name
        b.BackgroundColor3=on and T.purpleDark or T.panel
        b.TextColor3=on and T.purple or T.muted
    end
end
local function section(parent,name)
    local f=make("Frame",parent,{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1})
    label(f,name:upper(),8,T.purple,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)
end
local function toggle(parent,name,default)
    local r=make("Frame",parent,{Size=UDim2.new(1,0,0,29),BackgroundColor3=T.row,BorderSizePixel=0})
    round(r,6)
    local l=label(r,name,8,T.white,Enum.Font.GothamMedium)
    l.Position=UDim2.fromOffset(9,0); l.Size=UDim2.new(1,-55,1,0)
    local sw=make("TextButton",r,{
        Size=UDim2.fromOffset(32,18),Position=UDim2.new(1,-39,.5,-9),
        BackgroundColor3=default and T.purple or T.row2,Text="",BorderSizePixel=0,AutoButtonColor=false
    })
    round(sw,10)
    local knob=make("Frame",sw,{
        Size=UDim2.fromOffset(12,12),
        Position=default and UDim2.fromOffset(17,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=T.white,BorderSizePixel=0
    })
    round(knob,8)
    local on=default==true
    sw.Activated:Connect(function()
        on=not on
        TweenService:Create(sw,TweenInfo.new(.14),{BackgroundColor3=on and T.purple or T.row2}):Play()
        TweenService:Create(knob,TweenInfo.new(.14),{Position=on and UDim2.fromOffset(17,3) or UDim2.fromOffset(3,3)}):Play()
    end)
    return function() return on end
end
local function selector(parent,name,values,default)
    local r=make("Frame",parent,{Size=UDim2.new(1,0,0,42),BackgroundColor3=T.row,BorderSizePixel=0})
    round(r,6)
    local l=label(r,name,8,T.white,Enum.Font.GothamMedium)
    l.Position=UDim2.fromOffset(9,1); l.Size=UDim2.new(1,-16,0,16)
    local holder=make("Frame",r,{Position=UDim2.fromOffset(7,19),Size=UDim2.new(1,-14,0,18),BackgroundTransparency=1})
    make("UIListLayout",holder,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,3),HorizontalAlignment=Enum.HorizontalAlignment.Left})
    local selected=default or values[1]
    for _,v in ipairs(values) do
        local b=btn(holder,tostring(v),UDim2.new(1/#values,-3,1,0),UDim2.new())
        b.TextSize=7
        local function paint()
            b.BackgroundColor3=(selected==v) and T.purpleDark or T.row2
            b.TextColor3=(selected==v) and T.purple or T.muted
        end
        paint()
        b.Activated:Connect(function()
            selected=v
            for _,child in ipairs(holder:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3=(child==b) and T.purpleDark or T.row2
                    child.TextColor3=(child==b) and T.purple or T.muted
                end
            end
        end)
    end
    return function() return selected end
end
local function field(parent,name,placeholder)
    local r=make("Frame",parent,{Size=UDim2.new(1,0,0,48),BackgroundColor3=T.row,BorderSizePixel=0})
    round(r,6)
    label(r,name,7,T.muted,Enum.Font.GothamBold).Position=UDim2.fromOffset(9,3)
    local box=make("TextBox",r,{
        Position=UDim2.fromOffset(8,19),Size=UDim2.new(1,-16,0,23),
        BackgroundColor3=T.black,Text="",PlaceholderText=placeholder or "Value",
        PlaceholderColor3=T.dim,TextColor3=T.white,TextSize=8,
        Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0
    })
    round(box,4)
    return box
end
local function info(parent,name,value)
    local r=make("Frame",parent,{Size=UDim2.new(1,0,0,27),BackgroundColor3=T.row,BorderSizePixel=0})
    round(r,6)
    label(r,name,8,T.muted).Position=UDim2.fromOffset(9,0)
    local v=label(r,value,8,T.purple,Enum.Font.GothamBold)
    v.Position=UDim2.new(1,-65,0,0); v.Size=UDim2.fromOffset(56,27); v.TextXAlignment=Enum.TextXAlignment.Right
end

for i,name in ipairs({"CODES","RIDDLES","FARM","SETTINGS"}) do
    local b=btn(sidebar,name,UDim2.new(1,-12,0,31),UDim2.fromOffset(6,55+(i-1)*37))
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextSize=8
    b.TextColor3=T.muted
    local pad=make("UIPadding",b,{PaddingLeft=UDim.new(0,8)})
    navButtons[name]=b
    b.Activated:Connect(function() show(name) end)
end

-- Aetherion CODES options (ACE's old buttons/actions are not included).
local codes=makePage("CODES")
section(codes,"Code automation")
toggle(codes,"Auto Redeem",false)
toggle(codes,"Auto Part Guesser",false)
toggle(codes,"Auto Mode",false)
toggle(codes,"Parts Mode",false)
selector(codes,"Parts Amount",{1,2,3,4,5,6,8,10,12},3)
section(codes,"Announcement handling")
toggle(codes,"Accept Bare Parts",true)
toggle(codes,"Accept Sentence Parts",true)
toggle(codes,"Retype Invalid",false)
selector(codes,"Submit After",{1,2,3,6},3)
selector(codes,"Max Code Length",{20,30,40,50},50)
info(codes,"Collected Parts","0 / 3")
info(codes,"Code Status","IDLE")

-- Aetherion RIDDLES options.
local riddles=makePage("RIDDLES")
section(riddles,"Riddle solver")
toggle(riddles,"AI Riddle Solver",false)
toggle(riddles,"AI Riddles Auto Submit",false)
toggle(riddles,"Riddle Before Auto",false)
toggle(riddles,"Backup Riddle Answer",false)
toggle(riddles,"Learn Facts",false)
selector(riddles,"Fallback Delay",{"0.25s","0.55s","0.75s","1s"},"0.55s")
selector(riddles,"Retry Mode",{"Off","1x","2x"},"1x")
info(riddles,"Solver Status","IDLE")

-- Aetherion FARM options.
local farm=makePage("FARM")
section(farm,"Farm preferences")
toggle(farm,"Auto Buy",false)
toggle(farm,"Anti Ragdoll",false)
toggle(farm,"Lock Position",false)
toggle(farm,"FPS Boost",false)
toggle(farm,"Admin Abuse Alerts",false)
section(farm,"Retype buffer")
selector(farm,"Buffer Limit",{16,32,64,128},32)
selector(farm,"Buffer TTL",{30,60,180,300,600},180)
selector(farm,"Webhook Detail",{"Code","Reward","Both"},"Both")
field(farm,"Webhook URL","Paste URL (not sent by this UI)")

-- Aetherion SETTINGS options.
local settings=makePage("SETTINGS")
section(settings,"General")
toggle(settings,"Remember UI State",true)
toggle(settings,"Notifications",true)
toggle(settings,"Notification Sounds",true)
toggle(settings,"Falling Particles",false)
selector(settings,"Notification Volume",{0,25,50,75,100},75)
selector(settings,"UI Scale",{"80%","90%","100%","110%"}, "100%")
selector(settings,"Theme",{"Dark","Purple","Midnight"},"Dark")
info(settings,"Interface","ACE SHELL")
info(settings,"Mode","UI ONLY")

show("CODES")

-- Hamburger opens/closes the side navigation; content expands to use the freed width.
local sideOpen=true
local function setSidebar(open)
    sideOpen=open
    local targetX=open and 124 or 14
    local targetW=open and (WIDTH-134) or (WIDTH-24)
    TweenService:Create(sidebar,TweenInfo.new(.18,Enum.EasingStyle.Quad),{
        Size=UDim2.new(0,open and 104 or 0,1,-91)
    }):Play()
    TweenService:Create(content,TweenInfo.new(.18,Enum.EasingStyle.Quad),{
        Position=UDim2.fromOffset(targetX,62),
        Size=UDim2.new(1,-(open and 134 or 24),1,-91)
    }):Play()
end
menu.Activated:Connect(function() setSidebar(not sideOpen) end)

-- Collapse to the ACE title strip and restore on next click.
local collapsed=false
collapse.Activated:Connect(function()
    collapsed=not collapsed
    sidebar.Visible=not collapsed
    content.Visible=not collapsed
    status.Visible=not collapsed
    TweenService:Create(shell,TweenInfo.new(.18),{
        Size=UDim2.fromOffset(WIDTH,collapsed and 54 or HEIGHT)
    }):Play()
    collapse.Text=collapsed and "+" or "−"
end)

-- Drag window with mouse or touch.
local dragging,dragStart,startPosition=false,nil,nil
header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPosition=shell.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        shell.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,
            startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
    end
end)
