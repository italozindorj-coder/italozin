-- ACE SNIPER UI ONLY - visual shell prototype
-- No gameplay functions are connected yet. No blur, lighting effects, or screen dimming.
-- Run as a LocalScript / executor LocalScript in Roblox.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("AceSniperUIOnly")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "AceSniperUIOnly"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local C = {
 bg = Color3.fromRGB(10,10,14), panel = Color3.fromRGB(16,16,22), card = Color3.fromRGB(23,23,31),
 line = Color3.fromRGB(48,46,58), white = Color3.fromRGB(245,243,248), muted = Color3.fromRGB(151,146,163),
 purple = Color3.fromRGB(165,92,214), green = Color3.fromRGB(93,205,137)
}
local function corner(obj, radius)
 local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,radius or 8); x.Parent=obj; return x
end
local function stroke(obj, color, thickness, transparency)
 local x=Instance.new("UIStroke"); x.Color=color or C.line; x.Thickness=thickness or 1; x.Transparency=transparency or 0; x.Parent=obj; return x
end
local function label(parent, text, size, color, font)
 local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Text=text; x.TextColor3=color or C.white
 x.Font=font or Enum.Font.Gotham; x.TextSize=size or 12; x.TextXAlignment=Enum.TextXAlignment.Left
 x.Parent=parent; return x
end
local function button(parent, text, size, pos)
 local x=Instance.new("TextButton"); x.Size=size; x.Position=pos; x.BackgroundColor3=C.card; x.BorderSizePixel=0
 x.Text=text; x.TextColor3=C.white; x.Font=Enum.Font.GothamSemibold; x.TextSize=11; x.AutoButtonColor=true
 x.Parent=parent; corner(x,7); stroke(x,C.line,1); return x
end

local main=Instance.new("Frame")
main.Name="MainWindow"; main.Size=UDim2.fromOffset(510,390); main.Position=UDim2.new(.5,-255,.5,-195)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0; main.Parent=gui; corner(main,13); stroke(main,C.line,1)

-- Dragging is limited to the title bar; no overlay or blur is created.
local top=Instance.new("Frame"); top.Name="Header"; top.Size=UDim2.new(1,0,0,58); top.BackgroundColor3=C.panel; top.BorderSizePixel=0; top.Parent=main; corner(top,13)
local title=label(top,"ACE SNIPER",18,C.white,Enum.Font.GothamBlack); title.Position=UDim2.fromOffset(18,8); title.Size=UDim2.fromOffset(190,24)
local subtitle=label(top,"CODE SNIPER  •  UI PREVIEW",9,C.muted,Enum.Font.GothamBold); subtitle.Position=UDim2.fromOffset(19,32); subtitle.Size=UDim2.fromOffset(220,14)
local fpsLabel=label(top,"FPS: --",10,C.green,Enum.Font.GothamBold); fpsLabel.AnchorPoint=Vector2.new(1,0); fpsLabel.Position=UDim2.new(1,-88,0,12); fpsLabel.Size=UDim2.fromOffset(70,15); fpsLabel.TextXAlignment=Enum.TextXAlignment.Right
local pingLabel=label(top,"PING: -- ms",10,C.muted,Enum.Font.GothamBold); pingLabel.AnchorPoint=Vector2.new(1,0); pingLabel.Position=UDim2.new(1,-88,0,31); pingLabel.Size=UDim2.fromOffset(70,15); pingLabel.TextXAlignment=Enum.TextXAlignment.Right
local close=button(top,"×",UDim2.fromOffset(30,30),UDim2.new(1,-42,0,14)); close.TextSize=20

local tabBar=Instance.new("Frame"); tabBar.Name="Tabs"; tabBar.Size=UDim2.new(1,-24,0,38); tabBar.Position=UDim2.fromOffset(12,68); tabBar.BackgroundColor3=C.panel; tabBar.BorderSizePixel=0; tabBar.Parent=main; corner(tabBar,8)
local tabLayout=Instance.new("UIListLayout"); tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.Padding=UDim.new(0,3); tabLayout.SortOrder=Enum.SortOrder.LayoutOrder; tabLayout.Parent=tabBar
local tabPad=Instance.new("UIPadding"); tabPad.PaddingLeft=UDim.new(0,4); tabPad.PaddingTop=UDim.new(0,4); tabPad.PaddingBottom=UDim.new(0,4); tabPad.Parent=tabBar

local content=Instance.new("Frame"); content.Name="Content"; content.Size=UDim2.new(1,-24,1,-120); content.Position=UDim2.fromOffset(12,114); content.BackgroundTransparency=1; content.Parent=main
local pages={}; local tabButtons={}; local current
local tabs={"CLEAR","SENDER","FPS BOOST","RIDDLE","RETYPE","ADMIN"}
local function section(parent, text, y)
 local holder=Instance.new("Frame"); holder.Size=UDim2.new(1,-8,0,25); holder.Position=UDim2.fromOffset(4,y); holder.BackgroundTransparency=1; holder.Parent=parent
 local line=Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,.5,0); line.BackgroundColor3=C.line; line.BorderSizePixel=0; line.Parent=holder
 local cap=Instance.new("Frame"); cap.Size=UDim2.fromOffset(math.max(58,#text*7+18),20); cap.Position=UDim2.fromOffset(9,2); cap.BackgroundColor3=C.bg; cap.BorderSizePixel=0; cap.Parent=holder
 local t=label(cap,text,10,C.muted,Enum.Font.GothamBold); t.Size=UDim2.fromScale(1,1); t.TextXAlignment=Enum.TextXAlignment.Center
end
local function visualToggle(parent, text, y, initial)
 local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,37); row.Position=UDim2.fromOffset(4,y); row.BackgroundColor3=C.card; row.BorderSizePixel=0; row.Parent=parent; corner(row,7); stroke(row,C.line,1)
 local t=label(row,text,11,C.white,Enum.Font.GothamSemibold); t.Position=UDim2.fromOffset(12,0); t.Size=UDim2.new(1,-70,1,0)
 local state=initial or false; local b=button(row,state and "ON" or "OFF",UDim2.fromOffset(44,23),UDim2.new(1,-54,.5,-11.5)); b.TextColor3=state and C.green or C.muted
 b.MouseButton1Click:Connect(function() state=not state; b.Text=state and "ON" or "OFF"; b.TextColor3=state and C.green or C.muted end)
end
local function placeholder(parent,text,y)
 local b=button(parent,text,UDim2.new(1,-8,0,34),UDim2.fromOffset(4,y)); b.TextXAlignment=Enum.TextXAlignment.Left
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,12); pad.Parent=b
end
for i,name in ipairs(tabs) do
 local tb=button(tabBar,name,UDim2.new(1/6,-3,1,0),UDim2.new()); tb.LayoutOrder=i; tb.TextSize=9; tabButtons[name]=tb
 local page=Instance.new("ScrollingFrame"); page.Name=name.."Page"; page.Size=UDim2.fromScale(1,1); page.BackgroundTransparency=1; page.BorderSizePixel=0; page.ScrollBarThickness=3; page.ScrollBarImageColor3=C.purple; page.CanvasSize=UDim2.new(0,0,0,460); page.Visible=false; page.Parent=content; pages[name]=page
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,6); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=page
 local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,4); pad.PaddingLeft=UDim.new(0,4); pad.PaddingRight=UDim.new(0,4); pad.Parent=page
end

-- UI-only preview controls. These switches/buttons are visual placeholders and do not execute game actions.
section(pages.CLEAR,"CODES",0); visualToggle(pages.CLEAR,"Auto Redeem",30,false); visualToggle(pages.CLEAR,"Auto Part Guesser",73,false); visualToggle(pages.CLEAR,"Auto Mode",116,false); visualToggle(pages.CLEAR,"Parts Mode",159,false)
section(pages.CLEAR,"RIDDLES",207); visualToggle(pages.CLEAR,"AI Riddle Solver",237,false); visualToggle(pages.CLEAR,"Riddle Database",280,true); visualToggle(pages.CLEAR,"Auto Submit",323,false)
section(pages.SENDER,"SENDER",0); visualToggle(pages.SENDER,"Sender Detection",30,false); placeholder(pages.SENDER,"Waiting for Sammy...",73)
section(pages["FPS BOOST"],"PERFORMANCE",0); visualToggle(pages["FPS BOOST"],"FPS Boost",30,false); visualToggle(pages["FPS BOOST"],"Reduce Visual Effects",73,false)
section(pages.RIDDLE,"RIDDLE",0); visualToggle(pages.RIDDLE,"AI Riddle Solver",30,false); visualToggle(pages.RIDDLE,"Use Riddle Database",73,true); visualToggle(pages.RIDDLE,"Auto Submit",116,false)
section(pages.RETYPE,"RETYPE",0); visualToggle(pages.RETYPE,"Retype Replay",30,false); placeholder(pages.RETYPE,"Waiting for announcement...",73)
section(pages.ADMIN,"ADMIN",0); visualToggle(pages.ADMIN,"Admin Abuse (visual only)",30,false); visualToggle(pages.ADMIN,"Anti Ragdoll (visual only)",73,false)

local function selectTab(name)
 if current and pages[current] then pages[current].Visible=false end
 current=name; pages[name].Visible=true
 for n,b in pairs(tabButtons) do b.BackgroundColor3=(n==name) and Color3.fromRGB(48,29,61) or C.card; b.TextColor3=(n==name) and C.white or C.muted end
end
for name,b in pairs(tabButtons) do b.MouseButton1Click:Connect(function() selectTab(name) end) end
selectTab("CLEAR")

local open=button(gui,"OPEN  •  ACE SNIPER",UDim2.fromOffset(150,36),UDim2.new(0,18,0.5,-18)); open.Name="OpenButton"; open.Visible=false; open.BackgroundColor3=C.panel; open.TextColor3=C.white; stroke(open,C.purple,1)
close.MouseButton1Click:Connect(function() main.Visible=false; open.Visible=true end)
open.MouseButton1Click:Connect(function() main.Visible=true; open.Visible=false end)

local dragging=false; local dragStart; local startPos
 top.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; startPos=main.Position end
 end)
 UserInputService.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local d=input.Position-dragStart; main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
  end
 end)
 UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

local frames=0; local last=os.clock()
RunService.RenderStepped:Connect(function()
 frames+=1; local now=os.clock()
 if now-last>=1 then
  fpsLabel.Text="FPS: "..tostring(math.floor(frames/(now-last)+0.5)); frames=0; last=now
  local ok,ping=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
  if ok and type(ping)=="number" then pingLabel.Text="PING: "..tostring(math.floor(ping+0.5)).." ms" end
 end
end)
